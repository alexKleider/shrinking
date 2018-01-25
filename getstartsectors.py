#!/usr/bin/env python

# File: getstartectors.py

"""
Usage:
    getstartsectors.py FILE P1SECTOR P2SECTOR

Expect FILE to contain the output of the following command:
$ fdisk -l $DEV
We assume $DEV has two partitions.
FILE's last two lines should be of the form:
/dev/sdc1        8192   93236   85045 41.5M  c W95 FAT32 (LBA)
/dev/sdc2       94208 7744511 7650304  3.7G 83 Linux

Returns the two beginning block numbers in the
files P1SECTOR and P2SECTOR respectively.
"""

import sys

SOURCE = sys.argv[1]
P1SECTOR = sys.argv[2]
P2SECTOR = sys.argv[3]

p1sector = ""
p2sector = ""

with open(SOURCE, 'r') as f_obj:
    for line in f_obj:
        line_array = line.split()
#       print(line_array)
        p1sector = p2sector
        try:
            p2sector = line_array[1]
        except IndexError:
            p2sector = ''

with open(P1SECTOR, 'w') as f_obj:
    f_obj.write(p1sector)

with open(P2SECTOR, 'w') as f_obj:
    f_obj.write(p2sector)

print("Beginning (py) sectors are {} and {}."
    .format(p1sector, p2sector))
print("These were found in files {} and {} respectively."
    .format(P1SECTOR, P2SECTOR))

