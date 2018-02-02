#!/usr/bin/env python3

# File: get_dump.py

"""
Usage:
    get_dump.py FILE

FILE is expected to be the FILE produced by: 
    # sfdisk --dump DEVICE > FILE
Typically the following:
"
label: dos
label-id: 0x4bfd7db0
device: /dev/loop1
unit: sectors

/dev/loop1p1 : start=        8192, size=       85045, type=c
/dev/loop1p2 : start=       94208, size=     7650304, type=83
"

Assume DEVICE has two partitions.

Returns a string containing 4 space separated integers with in
a single set of parentheses. (No commas)
"(1stPartStartSector 1stPartSize 2ndPartStartSector 2ndPartSize)"
Sizes are in 512 byte sectors.
In this form, the output can be provided as a bash script array
assignment. (see shrink.sh)

If any of the returned values are '0',
there's likely  been an error!
"""

import sys

def assign(array1, array2):
    """Assigns values of array1 to the values of array2."""
    for i in range(len(array1)):
        array2[i] = array1[i]

if not len(sys.argv)==2:
    print("get_dump.py did not receive one and only one argument.",
        file=sys.stderr)
    print("(0 0 0 0)")
    sys.exit()

FILE = sys.argv[1]

values1 = [0, 0]
values2 = [0, 0]
try:
    with open(FILE) as fobj:
        for line in fobj:
            line_array = line.split()
            if len(line_array)==7:
                assign(values2, values1)
#               print("Evaluating:", file=sys.stderr)
#               print(line_array, file=sys.stderr))
                try:
#                   print("getting {} and {}"
#                       .format(line_array[3][:-1], line_array[5][:-1]),
#                       file=sys.stderr)
                    values2[0] = int(line_array[3][:-1])
                    values2[1] = int(line_array[5][:-1])
#                   print(values2, file=sys.stderr)
                except ValueError:
                    print("Unexpected values passed to get_dump.py.",
                        file=sys.stderr)
                    print("(0 0 0 0)")
                    sys.exit()
except FileNotFoundError:
    print("File passed to get_dump.py not found.",
        file=sys.stderr)
    print("(0 0 0 0)")
    sys.exit()

print("sys.stderr in get_dump.py reports last item: '{}'."
    .format(values2[1]), file=sys.stderr)

print("({} {} {} {})".format(
    values1[0],  # start sector of 1st partition
    values1[1],  # size of 1st partition
    values2[0],  # start sector of 2nd partition
    values2[1],  # size of 2nd partition
    ))

