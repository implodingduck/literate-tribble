terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.1.0"
    }
  }
  backend "azurerm" {

  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

locals {
  loc_for_naming = lower(replace(var.location, " ", ""))
}

resource "azurerm_resource_group" "literatetribble" {
  name     = "rg-functions-literatetribble-${local.loc_for_naming}"
  location = var.location
}

resource "random_string" "literatetribble_unique" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_storage_account" "literatetribble" {
  name                     = "literatetribble${random_string.literatetribble_unique.result}"
  resource_group_name      = azurerm_resource_group.literatetribble.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "literatetribble" {
  name                = "azure-functions-literatetribble-service-plan"
  location            = azurerm_resource_group.literatetribble.location
  resource_group_name = azurerm_resource_group.literatetribble.name
  kind                = "functionapp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "literatetribble" {
  name                       = "literatetribble${random_string.literatetribble_unique.result}"
  location                   = azurerm_resource_group.literatetribble.location
  resource_group_name        = azurerm_resource_group.literatetribble.name
  app_service_plan_id        = azurerm_app_service_plan.literatetribble.id
  storage_account_name       = azurerm_storage_account.literatetribble.name
  storage_account_access_key = azurerm_storage_account.literatetribble.primary_access_key
  version = "~3"
  os_type = "linux"

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"   = "python"
  }

  site_config {
    linux_fx_version= "Python|3.8"        
    ftps_state = "Disabled"
  }

  
}

resource "null_resource" "publish_literatetribble"{
  depends_on = [
    azurerm_function_app.literatetribble
  ]
  triggers = {
    index = "${base64sha256(file("${path.module}/ParseIt/ParseItHttpTrigger/__init__.py"))}"
  }
  provisioner "local-exec" {
    working_dir = "ParseIt"
    command     = "func azure functionapp publish ${azurerm_function_app.literatetribble.name}"
  }
}

resource "azurerm_template_deployment" "api_connection" {
  name = "literatetribbleofice365"
  resource_group_name = azurerm_resource_group.literatetribble.name 

  template_body = <<DEPLOY
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "connections_office365_name": {
            "defaultValue": "office365",
            "type": "String"
        }
    },
    "variables": {},
    "resources": [
        {
            "type": "Microsoft.Web/connections",
            "apiVersion": "2016-06-01",
            "name": "[parameters('connections_office365_name')]",
            "location": "eastus",
            "kind": "V1",
            "properties": {
                "displayName": "${var.api_connection_display_name}",
                "customParameterValues": {},
                "api": {
                    "id": "[concat('/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/eastus/managedApis/', parameters('connections_office365_name'))]"
                }
            }
        }
    ]
}
  DEPLOY

  deployment_mode = "Incremental"
}

resource "azurerm_template_deployment" "logicapp" {
  depends_on = [
    azurerm_template_deployment.api_connection
  ]
  name                = "literatetribblelogicapp"
  resource_group_name = azurerm_resource_group.literatetribble.name

  template_body = <<DEPLOY
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "workflows_name_param": {
            "defaultValue": "",
            "type": "String"
        },
        "sites_functionapp_externalid": {
            "defaultValue": "",
            "type": "String"
        },
        "connections_office365_externalid": {
            "defaultValue": "",
            "type": "String"
        },
        "emails_param": {
            "defaultValue": "",
            "type": "String"
        }
    },
    "variables": {},
    "resources": [
        {
            "type": "Microsoft.Logic/workflows",
            "apiVersion": "2017-07-01",
            "name": "[parameters('workflows_name_param')]",
            "location": "eastus",
            "properties": {
                "state": "Enabled",
                "definition": {
                    "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
                    "contentVersion": "1.0.0.0",
                    "parameters": {
                        "$connections": {
                            "defaultValue": {},
                            "type": "Object"
                        }
                    },
                    "triggers": {
                        "Recurrence": {
                            "recurrence": {
                                "frequency": "Day",
                                "interval": 1,
                                "schedule": {
                                    "hours": [
                                        "6"
                                    ],
                                    "minutes": [
                                        30
                                    ]
                                },
                                "timeZone": "Central Standard Time"
                            },
                            "type": "Recurrence"
                        }
                    },
                    "actions": {
                        "ParseItHttpTrigger": {
                            "runAfter": {},
                            "type": "Function",
                            "inputs": {
                                "function": {
                                    "id": "[concat(parameters('sites_functionapp_externalid'), '/functions/ParseItHttpTrigger')]"
                                }
                            }
                        },
                        "Send_an_email_(V2)": {
                            "runAfter": {
                                "ParseItHttpTrigger": [
                                    "Succeeded"
                                ]
                            },
                            "type": "ApiConnection",
                            "inputs": {
                                "body": {
                                    "Body": "<p>@{body('ParseItHttpTrigger')}</p>",
                                    "Subject": "Library Jobs",
                                    "To": "[parameters('emails_param')]"
                                },
                                "host": {
                                    "connection": {
                                        "name": "@parameters('$connections')['office365']['connectionId']"
                                    }
                                },
                                "method": "post",
                                "path": "/v2/Mail"
                            }
                        }
                    },
                    "outputs": {}
                },
                "parameters": {
                    "$connections": {
                        "value": {
                            "office365": {
                                "connectionId": "[parameters('connections_office365_externalid')]",
                                "connectionName": "office365",
                                "id": "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/eastus/managedApis/office365"
                            }
                        }
                    }
                }
            }
        }
    ]
}
DEPLOY
 
  parameters = {
    "workflows_name_param" = "literatetribblelogicapp"
    "sites_functionapp_externalid" = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.literatetribble.name}/providers/Microsoft.Web/sites/${azurerm_function_app.literatetribble.name}"
    "connections_office365_externalid" = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.literatetribble.name}/providers/Microsoft.Web/connections/office365"
    "emails_param" = var.emails_param
  }

  deployment_mode = "Incremental"
}