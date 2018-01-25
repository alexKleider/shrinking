#!/usr/bin/env python

# File: getblockcount.py

"""
Usage:
    getblockcount.py FILE BLKFILE SIZEFILE

Expect FILE to contain the output of the following command:
$ dumpe2fs -h $PARTITION | grep -e "Block count" -e "Block size" > $RES
which would look like the following:
Block count:              956288
Block size:               4096

Returns the two numbers- the Block count and the Block size
in the files BLKFILE and SIZEFILE respectively.
"""

import sys

SOURCE = sys.argv[1]
COUNTFILE = sys.argv[2]
SIZEFILE = sys.argv[3]

ret = []

def getfile(line_array):
    if line_array[1][:-1] == "count":
        return COUNTFILE
    if line_array[1][:-1] == "size":
        return SIZEFILE

def getnumber(line_array):
    return line_array[-1]
        

with open(SOURCE, 'r') as f_obj:
    for line in f_obj:
        line_array = line.split()
        with open(getfile(line_array), 'w') as f1_obj:
            number = getnumber(line_array)
            f1_obj.write(number)
            ret.append(number)

# Had hoped results could be passed back to the shell by the
# following:
print('({} {})'.format(ret[0], ret[1]))
# ...but that didn't work.


