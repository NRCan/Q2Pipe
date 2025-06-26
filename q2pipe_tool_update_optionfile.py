#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys,os
import argparse


#print("Q2Pipe Option file updater V1.0")
#print("By: Patrick Gagne\n")



parser=argparse.ArgumentParser(description='Update Q2Pipe optionfile to latest version')

parser.add_argument("-u","--user_optionfile", dest="user_optionfile",required=True, help=("User's optionfile to update [REQUIRED]"))
parser.add_argument("-d","--default_optionfile", dest="default_optionfile",required=True, help=("Default optionfile for the current Q2Pipe version [REQUIRED]"))
parser.add_argument("-o","--output", dest="optionfile_output",required=True, help=("Output filename [REQUIRED]"))

args=parser.parse_args()


user_option_dict={}

with open(args.user_optionfile, 'r') as user_file:
    for line in user_file:
        if line.startswith("#") or not line.strip():
            continue  # Skip comments and empty lines
        key, value = line.strip().split("=", 1)
        user_option_dict[key.strip()] = value.strip()

savefile=open(args.optionfile_output,'w')

with open(args.default_optionfile, 'r') as default_file:
    for line in default_file:
        if line.startswith("#") or not line.strip():
            savefile.write(line)  # Write comments and empty lines as is
            continue  # Skip comments and empty lines
        key, value = line.strip().split("=", 1)
        key = key.strip()
        value = value.strip()
        
        if key in user_option_dict:
            # If the user has provided a value, use it
            savefile.write(f"{key}={user_option_dict[key]}\n")
            user_option_dict.pop(key)  # Remove the key so the dict can be checked for remaining keys
        else:
            # Otherwise, use the default value
            savefile.write(f"{key}={value}\n")

savefile.close()

if len(user_option_dict.keys()) != 0:
    print("WARNING: The following keys were not found in the default option file (probably deprecated options) and will not be included in the output:")
    for remaining_key in user_option_dict.keys():
        print(f" - {remaining_key} = {user_option_dict[remaining_key]}")


print(f"\nUpdated option file saved to {args.optionfile_output}")
