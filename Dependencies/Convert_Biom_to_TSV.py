#!/usr/bin/env python3
# -*- coding: utf-8 -*-


# WARNING - UNTESTED SCRIPT

import sys,os
import argparse
import zipfile
import tempfile


try:
    import biom
except ImportError:
    print("ERROR: biom package not found. Please install it using 'pip install biom-format'")
    sys.exit(1) 


parser=argparse.ArgumentParser(description='Convert a Qiime2 artifact Feature-Table (QZA) to TSV file V1.0')

parser.add_argument("-q","--qza_input", dest="qza_file",required=True, help=("Qiime2 Artifact QZA (must be FeatureTable[Frequency] type) [REQUIRED]"))
parser.add_argument("-t","--tsv_output", dest="tsv_outfile",required=True, help=("Output filename [REQUIRED]"))

args=parser.parse_args()


temp_dir_obj = tempfile.TemporaryDirectory()

with zipfile.ZipFile(args.qza_file, 'r') as zip_ref:
    # List all files in the archive
    file_list = zip_ref.namelist()
    biom_path = os.path.join(temp_dir_obj, "feature-table.biom")
    # Find the feature-table.biom file
    for file_path in file_list:
        if file_path.endswith('/data/feature-table.biom'):
            # Extract the file
            with zip_ref.open(file_path) as source_file, open(biom_path, 'wb') as target_file:
                target_file.write(source_file.read())
        else:
            print("ERROR: feature-table.biom not found in the QZA file.")
            temp_dir_obj.cleanup()
            sys.exit(2)

biom_table = biom.load_table(biom_path)
# Convert the biom table to a TSV format
with open(args.tsv_outfile,'w') as fh:
    fh.write(biom_table.to_tsv())
    print(f"Converted {args.qza_file} to {args.tsv_outfile} successfully.")

temp_dir_obj.cleanup()

                


