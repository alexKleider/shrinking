#!/bin/bash

# File: try.sh

# This script must be executed (or sourced) with root privileges.

# It was written to check feasability of letting a script
# calculate numbers needed for the fdisk partition shrinkage
# and subsequent truncation of the image.
# This code has been incorporated into shrink.sh

# Discovers what we need to know to shrink an image.
# We assume the image contains two partitions and
# we are trying to shrink the second of these which
# we further assume to be a Linux (e2fs) file type.

# WARNING: be sure the following two variables are properly set:
DEV="/dev/sdc"
# DEV="/dev/loop0"
PARTITION=${DEV}2
# PARTITION=${DEV}p2

declare -i MYSTERY=14888
# The "MYSTERY" integer is the 'extra' number of bytes that seem to be
# needed when shrinking.  If anyone knows why they are needed, please
# let me know!

RES="sh.tmp"
RES1="py1.tmp"
RES2="py2.tmp"

# Part ONE (V1): use dumpe2fs to get the size of our 2nd partition:
##dumpe2fs -h $PARTITION | grep -e "Block count" -e "Block size" > $RES
# The result goes into a temporary file to be parsed...
# ...by the next command: 
##./getblockcount.py $RES $RES1 $RES2
# Takes as input content of the $HRES file and puts the block count
# and the block size into the $RES1 and $RES2 files respectively.

# We now collect those values into integer variables:
#exec 3< $RES1; read LINE <&3; declare -i COUNT=$LINE
#exec 4< $RES2; read LINE <&4; declare -i SIZE=$LINE

# Part ONE (V2):
declare -a DATA=`dumpe2fs -h $PARTITION | \
    grep -e "Block count" -e "Block size" | \
    ./getblockcount.py`
declare -i COUNT=${DATA[0]}
declare -i SIZE=${DATA[1]}

# Progress report:
printf "Count (sh) is %d, and size is %d.\n" $COUNT $SIZE


# Part TWO: get the starting blocks of each of the partitions:
##echo "fdisk -l to list partitions..."
##fdisk -l $DEV > $RES
# The results are again dumped into a temporary file
# to be parsed by the next command:
##./getstartsectors.py $RES $RES1 $RES2

# As before, We collect those values into integer variables:
##exec 5< $RES1; read LINE <&5; declare -i P1_1stSECTOR=$LINE
##exec 6< $RES2; read LINE <&6; declare -i P2_1stSECTOR=$LINE

# Part TWO (V2): get the starting blocks of each of the partitions:
echo "fdisk -l to list partitions..."
declare -a DATA=`fdisk -l $DEV | ./getstartsectors.py`
declare -i P1_1stSECTOR=${DATA[0]}
declare -i P2_1stSECTOR=${DATA[1]}

printf "Beginning (sh) sectors are %d and %d.\n" \
$P1_1stSECTOR $P2_1stSECTOR

# We no longer have need of our temporary files...
if test -f $RES ; then
    rm $RES $RES1 $RES2  # ...unless we are still debugging.
fi

# So now we have
# 1. The block count of the second partition &
# 2. the size of each of these blocks...
# ... allowing us to calculate the size of the second partition.
# We have also captured the beginning block of the second partition so
# we can then calculate its ending block.
declare -i P2SIZE=COUNT*SIZE
declare -i P2_lastSECTOR
P2_lastSECTOR=(P1_1stSECTOR-1)+P2SIZE/512
declare -i TRUNC_SIZE
TRUNC_SIZE=(P2_lastSECTOR+1)*512+MYSTERY


printf "\nStill TO-DO:\n"
echo "1. run sudo fdisk $SC to set the 2nd partition's"
printf "first sector to %d,\n" $P2_1stSECTOR
printf "and last sector to %d\n" $P2_lastSECTOR
printf "2. $ sudo truncate --size=%d %s\n" $TRUNC_SIZE $SC
echo "3. After truncation, it would be a good idea to"
echo "rename $SC to something more appropriate:"
echo " $ mv $SC shrunk.img"
echo '4. the script `$ sudo ./load-shrunk.sh` is provided'
echo "to help get the image back onto an SD card. Look it"
echo "over before using!!"

echo
echo "Hope this was successful and helpful. Have a nice day! :-)"

