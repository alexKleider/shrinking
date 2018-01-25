#!/bin/bash

# File: try.sh

# This script must be executed (or sourced) with root privileges.

# Discovers what we need to know to shrink an image.
# We assume the image contains two partitions and
# we are trying to shrink the second of these which
# we further assume to be a Linux (e2fs) file type.

# WARNING: be sure the following two variables are properly set:
DEV="/dev/sdc"
# DEV="/dev/loop0"
PARTITION=${DEV}2
# PARTITION=${DEV}p2

RES="sh.tmp"
RES1="py1.tmp"
RES2="py2.tmp"

# Part ONE: use dumpe2fs to get the size of our 2nd partition:
dumpe2fs -h $PARTITION | grep -e "Block count" -e "Block size" > $RES
# The result goes into a temporary file to be parsed...
# ...by the next command: 
./getblockcount.py $RES $RES1 $RES2
# Takes as input content of the $HRES file and puts the block count
# and the block size into the $RES1 and $RES2 files respectively.

# We now collect those values into integer variables:
exec 3< $RES1; read LINE <&3; declare -i COUNT=$LINE
exec 4< $RES2; read LINE <&4; declare -i SIZE=$LINE

# Progress report:
printf "Count (sh) is %d, and size is %d.\n" $COUNT $SIZE


# Part TWO: get the starting blocks of each of the partitions:
echo "fdisk -l to list partitions..."
fdisk -l $DEV > $RES
# The results are again dumped into a temporary file
# to be parsed by the next command:
./getstartsectors.py $RES $RES1 $RES2

# As before, We collect those values into integer variables:
exec 5< $RES1; read LINE <&5; declare -i P1SECTOR=$LINE
exec 6< $RES2; read LINE <&6; declare -i P2SECTOR=$LINE

printf "Beginning (sh) sectors are %d and %d.\n" $P1SECTOR $P2SECTOR

# We no longer have need of our temporary files...
rm $RES $RES1 $RES2  # ...unless we are still debugging.




