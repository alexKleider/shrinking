#!/bin/bash

# File: shrink.sh

### First be sure the following is what you want:
### Especially the first one!!!

declare SRC="/Downloads/ph-w-books2shrink.img"  # source image
declare SC="/Downloads/shrink-candidate.img"  # sacrificial copy
declare SHRUNK="/Downloads/shrunk.img"  # name for end product

declare DATESTAMP="`date '+%y%m%d%H%M'`"
declare TODO="todo-${DATESTAMP}.txt"

# Usage:
#   sudo ./shrink.sh  # takes <4 minutes (on my machine)

# Sets up a loop device and onto it loads the image to be shrunk.
# Shrinks the file system and then calculates information needed to
# complete the process of shrinking the partition and then truncating
# the image.  Presents this information to stdout along with other
# advice.
# Before embarking, that is to say, before you `dd` your SD Card to
# the image, you might want to add a readme file to the root
# file system- the file readme2add is provided as a template.
# Be sure the partitions are all unmounted before the `dd`.

# Instructions as to what has still to be done after the script ends
# are provided to stdout and to a file assigned to the TODO variable.
# Change the name of that file as you see fit (next line.)

declare -i MYSTERY
MYSTERY=0   # to check by how much we are short.
# MYSTERY=5505024  # ok jan 26, 07
# The "MYSTERY" integer was initially introduced when I was getting
# a 'dmesg' report that there was a mismatch of logical blocks. This
# problem seems to have gone away.  Leaving this in the code in case
# of a recurrence.
# Still unexplained is why 'dmesg' reports:
# "EXT4-fs (sdc2): mounted filesystem with ordered data mode. \
# Opts: (null)"

BEGINTIME="`date '+%H:%M'`"

printf \
"\n\n#####\nScript: shrink.sh  Beginning: %s\n#####\n" \
"$BEGINTIME" | tee -a $TODO

echo "Enable loopback (if not already enabled...)"
modprobe loop

echo "Detach all associated loop devices."
losetup -D

echo "Request a new/free loopback device..."
LOOPDEV=`losetup -f`  # Expect it to be /dev/loop0
PARTITION=${LOOPDEV}p2
printf " => %s; its 2nd partition is %s.\n" "$LOOPDEV" "$PARTITION"

BEGIN_COPY="`date '+%H:%M'`"
printf "Copy %s to %s...\n...starting at %s (expect 3+minutes)...\n" \
"$SRC"  "$SC" "${BEGIN_COPY}"
# ... to leave original undisturbed.
cp $SRC $SC
printf "\nCopy completed at %s\n" "`date '+%H:%M'`"
printf "..having begun at %s\n" "$BEGIN_COPY"

echo "Create a device for the image..."
losetup $LOOPDEV $SC

echo "Ask kernel to load the partitions that are on the image..."
partprobe $LOOPDEV
printf "... partitions are %sp1 & %sp2\n" \
"${LOOPDEV}" "${LOOPDEV}" 

echo "resize2fs demands fsck first..."
fsck.ext4 -f $PARTITION #  | /dev/null
echo "... finished fsck."
echo "resize partition to minimum size..."
resize2fs -M $PARTITION #  | /dev/null
echo "... finished resize2fs."

# Part ONE (V2):
declare -a DATA=`dumpe2fs -h $PARTITION | \
    grep -e "Block count" -e "Block size" | \
    ./getblockcount.py`
declare -i COUNT=${DATA[0]}
declare -i SIZE=${DATA[1]}
declare -i P2SIZE=COUNT*SIZE

# Progress report:
printf \
"The size of Partition 2 is (%d * %d) %d bytes.\n" \
"$COUNT" "$SIZE" "$P2SIZE" | tee -a $TODO

# Part TWO (V2): get the starting blocks of each of the partitions:
echo "fdisk -l to list partitions..."
declare -a DATA=`fdisk -l $LOOPDEV | ./getstartsectors.py`
declare -i P1_1stSECTOR=${DATA[0]}
declare -i P2_1stSECTOR=${DATA[1]}

printf "Beginning (sh) sectors are %d and %d.\n" \
$P1_1stSECTOR $P2_1stSECTOR
echo "We don't need the first sector of the first partition."

# So now we have
# 1. The block count of the second partition &
# 2. the size of each of these blocks...
# ... allowing us to calculate the size of the 2nd partition.
# We have also captured the beginning block of the second
# partition so we can then calculate its ending block.

declare -i P2_lastSECTOR=(P2_1stSECTOR-1)+P2SIZE/512

printf \
"Set the ending sector of the 2nd partition to %d.\n" \
"$P2_lastSECTOR" | tee -a $TODO

declare -i TRUNC_SIZE=(P2_lastSECTOR+1)*512+MYSTERY


# loopback device no longer needed.
losetup -d $LOOPDEV

printf "\nScript completed at %s\n" "`date '+%H:%M'`"
printf   "... having begun at %s\n" "$BEGINTIME"

printf "\nStill TO-DO:\n" | tee -a $TODO

printf \
"\n1. run sudo fdisk %s\n" $SC | tee -a $TODO
printf \
"(Be sure the last number in each of next 2 lines is the same.)\n" \
 | tee -a $TODO
printf \
"  a. Check that the beginning sectors are %d and %d.\n" \
"$P1_1stSECTOR" "$P2_1stSECTOR" | tee -a $TODO
printf \
"  b. Reset the 2nd partition's beginning sector to %d.\n" \
"$P2_1stSECTOR" | tee -a $TODO
printf \
"  c. Set its last sector to %d\n" $P2_lastSECTOR | tee -a $TODO


printf "\n2. %s ...\n" "$SC" | tee -a $TODO
printf \
".. was created by root so chanage its ownership:\n" | tee -a $TODO
printf "   $ sudo chown \$USER:\$USER %s\n" "$SC" | tee -a $TODO

printf \
"\n3. $ truncate --size=%d %s\n" \
"$TRUNC_SIZE" "$SC" | tee -a $TODO

printf \
"\n4. After truncation, it would be a good idea to\n" | tee -a $TODO
printf \
"rename %s to something more appropriate:\n" "$SC" | tee -a $TODO
printf \
"   $ mv %s %s\n" "$SC" "$SHRUNK" | tee -a $TODO

printf "\n5. Sometimes the partition auto mounts ...\n" \
| tee -a $TODO
printf \
"   $ sudo umount %s\n" "$PARTITION" | tee -a $TODO

printf \
"\n6. the script $ sudo ./load-shrunk.sh is provided\n" | tee -a $TODO
printf \
"to help get the image back onto an SD card. Look it\n" | tee -a $TODO
printf \
"over before using!!\n" | tee -a $TODO
printf \
"\nHope this was successful and helpful. Have a nice day! :-)\n"
printf \
"PS: Check out %s for a synopsis. (Also %s.)n" "$TODO"
printf \
"PPS: Direct comments, criticisms, &c. to alex@kleider.ca\n"

