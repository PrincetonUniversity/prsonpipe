#!/bin/env python2.7
#
# Author: Judith Mildner 10/19/2016
# Grab SFNR values from all bxh qa index.html files for a certain task and put them in a .csv file
# NOTE: functionality depends on order of items, so might only work when QA has meanstdevsfnr option on
#########################################
# Required packages:
#    bs4 (BeautifulSoup)

## Parse the input arguments
import argparse

parser = argparse.ArgumentParser(description='This script pulls the SFNR values from each bxh qa index.html file. -JM')
parser.add_argument('-i','--input', help='Path to index.html file to parse',required=True)
parser.add_argument('-p','--pkgdir',help='Directory with packages, /jukebox/tamir/pkg/ by default', required=False)

args = parser.parse_args()

bxh_file = args.input
pkg_dir = args.pkgdir if args.pkgdir != None else '/jukebox/tamir/pkg/'


## import modules/tools
import sys
sys.path.append(pkg_dir)
from bs4 import BeautifulSoup
import re
from itertools import chain



#open index.html file using bs4
bxh_html=open(bxh_file)
bxh_soup=BeautifulSoup(bxh_html,"lxml")

#get every third "imgmax" tag content (this should be the max SFNR value),
#extract digits only, and flatten the list
sfnr_max=[(re.findall('[0-9]+\.[0-9]+',x.text.encode("utf-8"))) for x in bxh_soup.findAll("span",{"class":"imgmax"})[2::3]]
sfnr_max=list(chain.from_iterable(sfnr_max))

print(','.join(sfnr_max))


