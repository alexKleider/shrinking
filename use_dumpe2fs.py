#!/usr/bin/env python3

# File: getfromdumpe2fs.py

"""
Usage:
    sudo dumpe2fs -h $PARTITION | \
    grep -e "Block count" -e "Block size" | \
    ./getfromdumpe2fs.py

Use in conjunction with the 'dumpe2fs' and grep commands as above.
Expects the specified two lines (selected by 'grep') of output from
the 'dumpe2fs' command (see above) to come in on stdin. Output (on
stdout) is a string containing the two values in parentheses (no
coma.) In this form, the output can be read by the calling shell
script as a two integer array. (see shrink.sh)
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


