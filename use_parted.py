#!/usr/bin/env python3

# File: use_parted.py

"""
Usage:
    sudo parted DEVICE unit 's' print | ./use_parted.py

Use in conjunction with GNU parted as above.
Assume DEVICE has two partitions.
Returns a string containing the start sectors of the two
partitions in parentheses (no comma.)
In this form, the output can be provided as a bash script
array assignment. (see shrink.sh)

If either or both of the returned values are '0',
there's likely  been an error!
"""

import sys

def check_validity(s):
    try:
        sector = int(s[:-1])
    except ValueError:
        return 0
    return sector

p1sector = ""
p2sector = ""
source = []
while True:
    try:
        source.append(input(""))
    except EOFError:
        break
for line in source:
    line_array = line.split()
    if len(line_array) > 1:
        p1sector = p2sector
        p2sector = line_array[1]
#       print("2nd word is: {}".format(p2sector),
#           file=sys.stderr)

print('({} {})'.format(check_validity(p1sector), check_validity(p2sector)))

