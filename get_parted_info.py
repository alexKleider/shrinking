#!/usr/bin/env python3

# File: get_parted_info.py

"""
Usage:
    sudo parted DEVICE unit 's' print | ./get_parted_info.py

Use in conjunction with GNU parted as above.
Assume DEVICE has two partitions.
Returns a string containing the partition number and 
the start and end sectors of each of the two partitions
all in parentheses. (No commas)
In this form, the output can be provided as a bash script
array assignment. (see shrink.sh)

If any of the returned values are '0',
there's likely  been an error!
"""

import sys

def check_validity(string, has_s=True):
    try:
        if has_s:
            value = int(string[:-1])
        else:
            value = int(string)
    except ValueError:
        return 0
    return value

p1 = ""
p2 = ""
p1begin = ""
p2begin = ""
p1end = ""
p2end = ""
source = []

while True:
    try:
        source.append(input(""))
    except EOFError:
        break
for line in source:
    line_array = line.split()
    if len(line_array) > 2:
        p1 = p2
        p2 = line_array[0]
        p1begin = p2begin
        p2begin = line_array[1]
        p1end = p2end
        p2end = line_array[2]

print('({} {} {} {} {} {})'
    .format(
        check_validity(p1, False),
        check_validity(p1begin),
        check_validity(p1end),
        check_validity(p2, False),
        check_validity(p2begin),
        check_validity(p2end)))

