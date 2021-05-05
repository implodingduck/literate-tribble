import logging

import azure.functions as func

import requests
from bs4 import BeautifulSoup
import time

def match_class(target):                                                        
    def do_match(tag):                                                          
        classes = tag.get('class', [])                                          
        return all(c in classes for c in target)                                
    return do_match  

def handle_rails_library():
    resp = requests.get('https://www.railslibraries.info/jobs')
    soup = BeautifulSoup(resp.content, 'html.parser')
    new_soup = BeautifulSoup('<div></div>', 'html.parser')
    soup_ele = soup.find("div", {"id": "content"})
    for a in soup_ele.find_all('a'):
        if a.get('href') != None:
            a['href'] = 'https://www.railslibraries.info' + a.get('href')
    jobs_ele = soup_ele.find_all(match_class(['views-row']))
    new_tag = soup.new_tag("a", href='https://www.railslibraries.info/jobs')
    new_tag.string = "!!! Rails Libraries Jobs !!!"
    new_soup.div.append(new_tag)
    for je in jobs_ele:
        new_soup.div.append(je)
    return new_soup

def handle_moline_library():
    # https://www.governmentjobs.com/careers/molineil?keywords=library
    # Doesnt work because of javascript...
    s = requests.Session()
    resp = s.get('https://www.governmentjobs.com/careers/molineil?keywords=library')
    #logging.info(resp.content.decode('utf-8'))
    soup = BeautifulSoup(resp.content, 'html.parser')
    new_soup = BeautifulSoup('<div></div>', 'html.parser')
    soup_ele = soup.find("div", { "id": "job-list-container" })
    for a in soup_ele.find_all('a'):
        if a.get('href') != None:
            a['href'] = 'https://www.governmentjobs.com' + a.get('href')

    #jobs_ele = soup_ele.find_all(match_class(['list-item']))
    new_tag = soup.new_tag("a", href='https://www.governmentjobs.com/careers/molineil?keywords=library')
    new_tag.string = "!!! Moline Library Jobs !!!"
    new_soup.div.append(new_tag)
    # for je in jobs_ele:
    #     new_soup.div.append(je)
    new_soup.append(soup_ele)
    return new_soup

def handle_augustana():
    resp = requests.get('https://augustana.interviewexchange.com/static/clients/555ACM1/index.jsp')
    soup = BeautifulSoup(resp.content, 'html.parser')
    new_soup = BeautifulSoup('<div></div>', 'html.parser')
    soup_ele = soup.find("main")
    for a in soup_ele.find_all('a'):
        if a.get('href') != None:
            a['href'] = 'https://augustana.interviewexchange.com' + a.get('href')
    new_tag = soup.new_tag("a", href='https://augustana.interviewexchange.com/static/clients/555ACM1/index.jsp')
    new_tag.string = "!!! Augustana Jobs !!!"
    new_soup.div.append(new_tag)
    new_soup.div.append(soup_ele)
    return new_soup

def handle_rivershare():
    # http://www.rivershare.org/index.php/39-news-room/57-job-postings
    resp = requests.get('http://www.rivershare.org/index.php/39-news-room/57-job-postings')
    soup = BeautifulSoup(resp.content, 'html.parser')
    new_soup = BeautifulSoup('<div></div>', 'html.parser')
    soup_ele = soup.find("div", class_='item-page')
    # for a in soup_ele.find_all('a'):
    #     if a.get('href') != None:
    #         a['href'] = 'http://www.rivershare.org' + a.get('href')

    new_tag = soup.new_tag("a", href='http://www.rivershare.org/index.php/39-news-room/57-job-postings')
    new_tag.string = "!!! RiverShare Jobs !!!"
    new_soup.div.append(new_tag)
    new_soup.div.append(soup_ele)
    return new_soup


def handle_stambrose():
    # https://stambroseuniv.applicantlist.com/jobs/
    resp = requests.get('https://stambroseuniv.applicantlist.com/jobs/')
    soup = BeautifulSoup(resp.content, 'html.parser')
    soup_ele = soup.find('div', { 'id': 'job_listings' })
    jobs_ele = soup_ele.find_all(match_class(['list-group-item']))
    new_soup = BeautifulSoup('<div></div>', 'html.parser')
    new_tag = soup.new_tag("a", href='https://stambroseuniv.applicantlist.com/jobs/')
    new_tag.string = "!!! St. Ambrose Jobs !!!"
    new_soup.div.append(new_tag)
    for je in jobs_ele:
        new_soup.div.append(je)
    return new_soup

def handle_blackhawk():
    # Boo doesnt work either
    # https://www.schooljobs.com/careers/bhcedu
    resp = requests.get('https://www.schooljobs.com/careers/bhcedu')
    soup = BeautifulSoup(resp.content, 'html.parser')
    soup_ele = soup.find('div', { 'id': 'job-list-container' })
    for a in soup_ele.find_all('a'):
        if a.get('href') != None:
            a['href'] = 'https://www.schooljobs.com' + a.get('href')
    jobs_ele = soup_ele.find_all('li', class_='list-item')
    new_soup = BeautifulSoup('<div></div>', 'html.parser')
    new_tag = soup.new_tag("a", href='https://www.schooljobs.com/careers/bhcedu')
    new_tag.string = "!!! Black Hawk College Jobs !!!"
    new_soup.div.append(new_tag)
    for je in jobs_ele:
        new_soup.div.append(je)
    return new_soup

def handle_eicc():
    # https://www.eicc.edu/about-eicc/careers/
    resp = requests.get('https://www.eicc.edu/about-eicc/careers/')
    soup = BeautifulSoup(resp.content, 'html.parser')
    soup_ele = soup.find('section', class_='content-block')
    for a in soup_ele.find_all('a'):
        if a.get('href') != None:
            a['href'] = 'https://www.eicc.edu' + a.get('href')
    jobs_ele = soup_ele.find('ul').find_all('li')
    new_soup = BeautifulSoup('<div></div>', 'html.parser')
    new_tag = soup.new_tag("a", href='https://www.eicc.edu/about-eicc/careers/')
    new_tag.string = "!!! East Iowa CC Jobs !!!"
    new_soup.div.append(new_tag)
    for je in jobs_ele:
        new_soup.div.append(je)
    return new_soup

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')


    # name = req.params.get('name')
    # if not name:
    #     try:
    #         req_body = req.get_json()
    #     except ValueError:
    #         pass
    #     else:
    #         name = req_body.get('name')

    # if name:
    #     return func.HttpResponse(f"Hello, {name}. This HTTP triggered function executed successfully.")
    # else:
    #     return func.HttpResponse(
    #          "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response.",
    #          status_code=200
    #     )
    new_soup = BeautifulSoup('<b>Library Job Search</b>', 'html.parser')
    
    new_soup.append(handle_rails_library())
    new_soup.append(handle_augustana())
    new_soup.append(handle_rivershare())
    new_soup.append(handle_stambrose())
    new_soup.append(handle_eicc())
    return func.HttpResponse(
             new_soup.prettify(),
             status_code=200
    )
