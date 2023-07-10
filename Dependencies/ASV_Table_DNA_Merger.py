#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys,os
import argparse


#print("ASV Table - Sequences Merger")
#print("By: Patrick Gagne\n")



parser=argparse.ArgumentParser(description='Merge Qiime2 ASV Table with Fasta sequences V1.0')

parser.add_argument("-f","--fasta", dest="fasta_file",required=True, help=("Fasta file containing ASV representative sequences [REQUIRED]"))
parser.add_argument("-t","--asv-table", dest="asv_table",required=True, help=("Sequence Name [REQUIRED]"))
parser.add_argument("-o","--out", dest="asv_outfile",required=True, help=("Output filename [REQUIRED]"))

args=parser.parse_args()

try:
    inputf = open(args.fasta_file, 'r')
except IOError:
    print("ERROR: %s not found"%(args.fasta_file))
    sys.exit(1)

try:
    asvf = open(args.asv_table, 'r')
except IOError:
    print("ERROR: %s not found"%(args.asv_table))
    sys.exit(1)

seqdict={}
fastaL=inputf.read()
inputf.close()
fastaL=fastaL.split(">")
fastaL.pop(0)

print("Reading Fasta file")
for i in fastaL:
    spl=i.split("\n",1)
    seqdict[spl[0]]=spl[1].replace("\n","")

print("Reading ASV table")
fastaL=[]
asvL=asvf.readlines()
asvf.close()
header=asvL.pop(0)
header=header.replace("\n","")+"\t"+"Sequence\n"

print("Merging ASV table with fasta sequences")
savefile=open(args.asv_outfile,'w')
savefile.write(header)
for i in asvL:
    seqname=i.split("\t")[0]
    seq=seqdict[seqname]
    savefile.write(i.replace("\n","")+"\t"+seq+"\n")

savefile.close()
print("PROGRAM DONE")



