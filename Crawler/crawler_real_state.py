
# This file produces a csv file with information on real estate
# properties in Mexico City coming from the website http://www.inmuebles24.com/

import bs4
import urllib3
import re
import numpy as np
import csv
import requests
import urllib.request

# Number of websites per type we want to scrap
RANGE = 2

def url_ok(url):
     '''
     Checks if a URL is valid to follow
     Input: url
     Returns: Boolean
     '''
     r = requests.head(url)
     return r.status_code == 200

def get_valid_links(prefix_url):
     '''
     Gets a list of valid links to follow from the website
     http://www.inmuebles24.com/
     Input: absolute url (string)
     Returns: List of urls for each property
     '''
     # List of numbers to form website scrap across all pages of properties
     numbers = []
     for i in range(1,RANGE):
          numbers.append(i)
     links_to_follow_raw = []

     for number in numbers:
          if number == 1:
               links_to_follow_raw.append(prefix_url + '.html' + '')
          else:
               links_to_follow_raw.append(prefix_url + '-pagina-' + str(number) + '.html')

     links_to_follow = []
     for link in links_to_follow_raw:
        if url_ok(link) == True:
               links_to_follow.append(link)

     list_of_soups = []      # This chunk of code comes from PA2
     for link in links_to_follow:
          soup = create_soup(link)
          list_of_soups.append(soup)

     links_per_page = [] # Gets all the links per website
     for soup in list_of_soups:
          for tag in soup.find_all('a'):
               links_per_page.append( (tag.get('href')))

     clean_links = []  # Delete the repeated and non-valid links
     for link in links_per_page:
          valid_link = re.findall('^/propiedades.*\.html$', link)
          clean_links.extend(valid_link)
          unique_set = set(clean_links)
          unique_list = list(unique_set)

     final_list = []        # Final valid list of links
     for link in unique_list:
          complete_link = (prefix_url[:26] + link)
          final_list.append(complete_link)

     return final_list

def create_soup (link):
     '''
     It creates a BeautifulSoup object with a website info
     Input: String
     Returns: BeautifulSoup object
     '''
     pm = urllib3.PoolManager()
     html = pm.urlopen(url = link, method = "GET", timeout = 5).data
     soup = bs4.BeautifulSoup(html, 'html5lib')
     return soup

def get_info(link):
     '''
     Extracts relevant information from each link, corresponding
     to one property
     Input: Url (String)
     Returns: Dictionary
     '''
     soup = create_soup (link)
     tags_with_info = soup('script', type = "text/javascript")
     for tag in tags_with_info:
          if 'dataLayer.push({"' in tag.text:
               tag_with_info1 = tag

     # General information contained that is contained in a dictionary in the
     # html file. This tag has the property address...
     list_with_info1 = tag_with_info1.string.rstrip().rstrip('});').lstrip\
     ('\n\t\tdataLayer.push({').split('","')
     dictionary_with_info = {}
     for pair in list_with_info1:
          key_val = pair.split(':')
          dictionary_with_info[key_val[0].strip('\"')] = key_val[1].strip('\"')

     # Now we will scrap the This is the tag with the relevant information (not the address)
     final_dict = {}

     if '"tipoDeOperacion":"Alquiler' in list_with_info1:
          final_dict['Transaction Type'] = 'Rent'
     elif '"tipoDeOperacion":"Venta' in list_with_info1:
          final_dict['Transaction Type'] = 'Sale'
     for element in list_with_info1:
          if 'precioVenta":"MN' in element:
               words_numbers = element.split()
               price = int(words_numbers[1].replace(',', ''))
               final_dict['Sale price pesos'] = price
          elif 'precioVenta":"U$D' in element:
               words_numbers = element.split()
               price = int(words_numbers[1].replace(',', ''))
               final_dict['Sale price dollars'] = price
          elif 'precioAlquiler":"U$D' in element:
               words_numbers = element.split()
               price = int(words_numbers[1].replace(',', ''))
               final_dict['Rent price dollars'] = price
          elif 'precioAlquiler":"MN' in element:
               words_numbers = element.split()
               price = int(words_numbers[1].replace(',', ''))
               final_dict['Rent price pesos'] = price

     tag_with_info2 = soup.find_all("div" , {"class" : "card aviso-datos"})
     list_with_info2 = []
     if len(tag_with_info2) > 0:
          for piece_of_info in tag_with_info2[0].find_all('li'):
               a = piece_of_info.text.replace('\t','').replace('\n','').strip()
               list_with_info2.append(a)

     # Description of property
     description = soup.find_all("div" , {"class" : "span8"})
     description_string = description[1].text.replace('\t','').replace\
     ('\n','').strip()
     # Location of property
     tag_with_address = soup.find_all("div" , {"class" : "card location"})
     if  len(tag_with_address) != 0:
          address = tag_with_address[0].text.replace('\t','').replace\
          ('\n','').strip()[9:]
     else:
          address = 'NA'

     for element in list_with_info2:
          if len(element) > 0:
               if 'Superficie' and 'total' in element:
                    final_dict['Surface (total)'] = int(re.findall(r'\b\d+', \
                         element)[0])
               elif 'Superficie' and 'construída' in element:
                    final_dict['Surface (built)'] = int(re.findall(r'\b\d+', \
                         element)[0])
               elif 'Recámaras' in element:
                    final_dict ['Rooms'] = int(re.findall(r'\b\d+', element)[0])
               elif 'Baños' in element:
                    final_dict ['Bathrooms'] = int(re.findall(r'\b\d+', \
                         element)[0])
               elif 'baño' and 'Medio' in element:
                    final_dict ['Half bathrooms'] = int(re.findall(r'\b\d+', \
                         element)[0])
               elif 'Estacionamientos' in element:
                    final_dict['Parking lots'] = int(re.findall(r'\b\d+', \
                         element)[0])
               elif 'Antigüedad' in element:
                    if len(element[0]) > 1:
                         final_dict['Building Age'] = int(re.findall(r'\b\d+', \
                              element)[0])
                    elif "A estrenar" in element:
                         final_dict['Building Age'] = 0
                    else:
                         final_dict['Building Age'] = 'NA'
               elif 'MantenimientoMN' in element:
                    words_numbers = element.split()
                    final_dict['Maintenance Cost'] = words_numbers[1]

     if 'barrio' in dictionary_with_info.keys():
          final_dict['Neighborhood'] = dictionary_with_info ['barrio']
     else:
          final_dict['Neighborhood'] = 'NA'
     if 'ciudad' in dictionary_with_info.keys():
          final_dict['Delegacion'] = dictionary_with_info ['ciudad']
     else:
          final_dict['Delegacion'] = 'NA'
     if 'tipoDePropiedad' in dictionary_with_info.keys():
          final_dict['Type'] = dictionary_with_info ['tipoDePropiedad']
     else:
          final_dict['Type'] = 'NA'
     final_dict['Location (Address)'] = address
     final_dict['Description'] = description_string[11:]

     return  final_dict

def construct_link(building_type, transaction_type):
     '''
     Constructs an absolute string to build the data
     Inputs:
      - building_type (string): It can take two values: 'house', or 'appartment'
      - transaction_type (string): It can take two values: 'rent', or 'sale'
     Returns: String
     '''
     if building_type == 'house':
          string_1 = 'casas'
     elif building_type == 'appartment':
          string_2 = 'departamentos'
     if transaction_type == 'rent':
          string_2 = 'renta'
     elif transaction_type == 'sale':
          string_2 = 'venta'

     return 'http://www.inmuebles24.com/' + string_1 + \
     '-en-' + string_2 + '-en-distrito-federal'

def build_data(building_type, transaction_type, outputfile):
     '''
     Constructs a csv file. Each row of the CSV corresponds to
     a dictionary with information from one property.

     Inputs:
      - building_type (string): It can take two values: 'house', or 'appartment'
      - transaction_type (string): It can take two values: 'rent', or 'sale'
     '''
     link = construct_link(building_type,transaction_type)
     list_of_links = get_valid_links (link)
     list_of_dictionaries = []
     for link in list_of_links:
          dictionary_one_property = get_info(link)
          print (link, dictionary_one_property)
          list_of_dictionaries.append(dictionary_one_property)
     fieldnames = ['Type', 'Delegacion','Neighborhood','Rent price pesos',\
          'Rent price dollars', 'Maintenance Cost', 'Rooms','Surface (total)', \
          'Surface (built)','Sale price pesos','Sale price dollars','Bathrooms',\
          'Transaction Type', 'Location (Address)',  'Half bathrooms', \
          'Parking lots', 'Building Age', 'Description']

     with open(outputfile +'.csv', 'w') as output_file:
          dict_writer = csv.DictWriter(output_file, fieldnames)
          dict_writer.writeheader()
          dict_writer.writerows(list_of_dictionaries)

     print('')
     print(outputfile + 'complete')


files = ['appartmentsale', 'appartmentrent', 'houserent', 'housesale']

#or name in files:
     #build_data(name[:-4], name[-4:], name)
