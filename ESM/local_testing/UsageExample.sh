#! /bin/bash

# example script for generating PDB files and some general data about
# model resource usage

# script expects:
# GetStructs.py

python tempdir/GetStructs.py tempdir/${1} --model esm3_sm_open_v1 --device cpu

# tar czf tempdir/structs.tar.gz *.pdb
# tar czf tempdir/etc.tar.gz *.txt


