#!/usr/bin/env python3

# File: use_dumpe2fs.py

"""
Usage:
    sudo dumpe2fs -h $PARTITION | \
    grep -e "Block count" -e "Block size" | \
    ./use_dumpe2fs.py

Use in conjunction with the 'dumpe2fs' and grep commands as above.
Expects the specified two lines (selected by 'grep') of output from
the 'dumpe2fs' command (see above) to come in on stdin. Output (on
stdout) is a string containing the two values in parentheses (no
coma.) In this form, the output can be read by the calling shell
script as a two integer array. (see shrink.sh)
The two integers will be the Block count and the Block size in that
order (not that order matters, since it's only the product of the two
that is crucial to the calling script.
"""

import sys

ret = []

def getnumber(line_array):
    return line_array[-1]

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


