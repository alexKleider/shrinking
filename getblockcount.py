#!/usr/bin/env python3

# File: getblockcount.py

"""
Usage:
    getblockcount.py [ FILE BLKFILE SIZEFILE ]

When used with parameters:
Expect FILE to contain the output of the following command:
$ dumpe2fs -h $PARTITION | grep -e "Block count" -e "Block size" > $RES
which would look like the following:
Block count:              956288
Block size:               4096
Returns the two numbers- the Block count and the Block size
in the files BLKFILE and SIZEFILE respectively.
Without parameters:
Expects the output of the `dump2fs` command (see above) to come in on
stdin. Output (on stdout) can be read by the calling shell script as
a two integer array.
"""

import sys

ret = []

def getnumber(line_array):
    return line_array[-1]

if len(sys.argv) > 1:
    SOURCE = sys.argv[1]
    COUNTFILE = sys.argv[2]
    SIZEFILE = sys.argv[3]

    def getfile(line_array):
        if line_array[1][:-1] == "count":
            return COUNTFILE
        if line_array[1][:-1] == "size":
            return SIZEFILE
            

    with open(SOURCE, 'r') as f_obj:
        for line in f_obj:
            line_array = line.split()
            with open(getfile(line_array), 'w') as f1_obj:
                number = getnumber(line_array)
                f1_obj.write(number)
                ret.append(number)

else:
    source = []
    while True:
        try:
            source.append(input(""))
        except EOFError:
            break
    for line in source:
        line_array = line.split()
        number = getnumber(line_array)
        ret.append(number)

print('({} {})'.format(ret[0], ret[1]))


