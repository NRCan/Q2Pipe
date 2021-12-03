#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#Simple Dada2 Table QZV HTML parser for Q2Pipe
# By Patrick Gagne

import sys

#Print to stderr function
def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def extract_between_html(string):
    start=string.find(">")+len(">")
    end=string.find("</")
    return string[start:end]


try:
    table_html=open(sys.argv[1],'r')
except IndexError:
    eprint("ERROR: you must specify a dada2 table html file")
    eprint("USAGE: %s /path/to/index.html"%(sys.argv[0]))
    sys.exit(1)
except IOError:
    eprint("ERROR: %s not found or not accessible"%(sys.argv[1]))
    sys.exit(2)
table_htmlL=table_html.readlines()
table_html.close()

info_samp=[]
info_freq=[]
check_list={"Number of samples":1,"Number of features":1,"Total frequency":1,"Minimum frequency":2,"1st quartile":2,"Median frequency":2,"3rd quartile":2,"Maximum frequency":2,"Mean frequency":2}
for i in table_htmlL:
    if "Frequency per feature" in i:
        break
    try:
        val=0
        key=extract_between_html(i)
        val=check_list[key]
    except KeyError:
        continue
    else:
        if val == 1:
            info_samp.append([key,extract_between_html(table_htmlL[table_htmlL.index(i)+1])])
        if val == 2:
            info_freq.append([key,extract_between_html(table_htmlL[table_htmlL.index(i)+1])])


length_list = [len(element) for row in info_samp for element in row]
column_width = max(length_list)
print("Table summary")
print("-"*((column_width*2)+2))
for row in info_samp:
    row = "".join(element.ljust(column_width + 2) for element in row)
    print(row)
print("-"*((column_width*2)+2))
print("")
length_list = [len(element) for row in info_freq for element in row]
column_width = max(length_list)
print("Frequency per sample")
print("-"*((column_width*2)+2))
for row in info_freq:
    row = "".join(element.ljust(column_width + 2) for element in row)
    print(row)
print("-"*((column_width*2)+2))

