#!/bin/bash

# File: shrink.sh

### First be sure the following is what you want:
### Especially the first one!!!

declare SRC="/Downloads/ph-w-books2shrink.img"  # source image
declare SC="/Downloads/shrink-candidate.img"  # sacrificial copy
declare SHRUNK="/Downloads/shrunk.img"  # name for end product
declare ZIPPED="/Downloads/shrunk.zip"  # for distribution

shopt -s -o nounset

declare DATESTAMP="`date '+%y%m%d%H%M'`"
declare TODO="todo-${DATESTAMP}.txt"
declare LOG="calc-${DATESTAMP}.py"

# Usage:
#   sudo ./shrink.sh

# takes <4 minutes (on my machine)

# Steps:
#  1. Create a sacrificial copy of the image file
# (to preserve the original.)
#  2. Set up a loop device, associate it with (the sacrificial
# copy of) the image and announce its partitions to the OS.
#  3. Check the second partition's file system as a prelude to...
#  4. Resize the second partition's file system to the minimum.
#  5. Discover the second partition's Block count and Block size
# using ./use_dumpe2fs.py
#  6. Discover the partition table (number and begin & end sectors
# for each of the two partitions.)
#  7. Change the second partition's end sector to match the size of its
# resized file system.
#  8. Detach the loop device.
#  9. Truncate (the sacrificial copy of) the image file.
# 10. Provide suggested commands to run after the script ends
# (assuming it ends successfully!)

# Before embarking, that is to say, before you `dd` your SD Card to
# the image, you might want to add a readme file to the root
# file system- the file readme2add is provided as a template.
# Be sure the partitions are all unmounted before the `dd`.

# Progress reports as well as
# Suggestions for what should still be done after the script ends
# are provided to stdout and to a (time stamped) file (named by the
# TODO variable.) Also have a look at the (also time stamped) file
# (named by the LOG variable.)

declare -i MYSTERY
MYSTERY=0   # to add space if we are short.
# MYSTERY=5505024  # ok jan 26, 2017
# The "MYSTERY" integer was initially introduced when I was getting
# a 'dmesg' report that there was a mismatch of logical blocks.
# This problem seems to have gone away.  This variable is being left
# in the code in case of a recurrence.

# Still unexplained is why 'dmesg' reports:
# "EXT4-fs (sdc2): mounted filesystem with ordered data mode. \
# Opts: (null)"

BEGINTIME="`date '+%H:%M'`"
printf \
"\n\n#####\nScript: shrink.sh  Beginning: %s\n#####\n" \
"$BEGINTIME" | tee -a $TODO

# Step 1.
BEGIN_COPY="`date '+%H:%M'`"
printf \
"Copy %s to...\n... %s...\n...starting at %s (>3 min)...\n" \
"$SRC"  "$SC" "${BEGIN_COPY}"
# ... to leave original undisturbed.
if cp $SRC $SC ; then
    printf "\nCopy completed at %s\n" "`date '+%H:%M'`" \
    | tee -a $TODO
    printf "..having begun at %s\n" "$BEGIN_COPY"
else
    printf "Error: copy failed! Exit (Stage) 1\n" \
    | tee -a $TODO
    exit 1
fi

# Step 2.
printf "Enable loopback (if not already enabled...)\n"
if modprobe loop ; then
    printf "... modprobe loop ran successfully.\n" \
    | tee -a $TODO
else
    ec="$?"
    print "... modprobe returned exit code %s.\n" \
    "$ec" | tee -a $TODO
fi

printf "Detach all associated loop devices.\n"
if losetup -D ; then
    print "... losetup -D ran successfully.\n" "$?" \
    | tee -a $TODO
else
    ec="$?"
    print "... losetup -D returned exit code %s.\n" \
    "$ec" | tee -a $TODO
    exit 2
fi

printf "Request a new/free loopback device...\n"
if LOOPDEV=`losetup -f` ; then
    printf \
        " ... output of loosetup -f was %s which is being"\n \
        "$LOOPDEV" | tee -a $TODO
    printf "assigned to LOOPDEV.\n" | tee -a $TODO
else
    ec="$?"
    printf \
    "... losetup -f > LOOPDEV failed with code %s! \n" \
    "$ec" | tee -a $TODO
    exit 2
fi
PART_NUMBER=2  # We assume a two partition device and...
            # ... we are resizing only the second partition.
PARTITION=${LOOPDEV}p${PART_NUMBER}
printf " => %s; its 2nd partition is %s.\n" "$LOOPDEV" "$PARTITION"

printf "Associate device and image.\n" | tee -a $TODO
losetup $LOOPDEV $SC

printf "Inform the OS of partition table changes.\n" | tee -a $TODO
partprobe $LOOPDEV

# Step 3.
printf "resize2fs demands e2fsck first...\n"
printf "... so running command: e2fsck -f %s...\n" "$PARTITION"
if e2fsck -f $PARTITION; then
    printf "... successfully finished e2fsck.\n" | tee -a $TODO
else
    printf "Error: e2fsck failed! \n" | tee -a $TODO
    exit 3
fi

# Step 4.
printf "resize partition to minimum size...\n"
if resize2fs -M $PARTITION ; then
    printf "... successfully ran resize2fs.\n" | tee -a $TODO
else
    printf "Error running resize2fs! \n" | tee -a $TODO
    exit 4
fi

# Step 5.
# Capture the block count and block size of the resized file
# system on the second partition. The product = size in bytes.
declare -a DATA=`dumpe2fs -h $PARTITION | \
    grep -e "Block count" -e "Block size" | \
    ./use_dumpe2fs.py`
declare -i COUNT=${DATA[0]}
declare -i SIZE=${DATA[1]}
# ... so we can calculate the size (in bytes) of the 2nd partition:
declare -i P2SIZE=COUNT*SIZE

# Progress report:
printf \
"Partition 2 file system size is now (%d * %d) %d bytes.\n" \
"$COUNT" "$SIZE" "$P2SIZE" | tee -a $TODO

# Step 6.
# Get the the number and sector boundaries of each of the partitions:
# We only need to know the second partition beginning sector but
# reporting (and checking) all of it might help debugging.
printf "Use GNU parted to list partitions...\n"
printf "  $ parted %s unit 's' print\n" "$LOOPDEV " 
printf "...and pipe it into ./get_parted_info.py\n"
declare -a DATA=`parted $LOOPDEV unit 's' print \
    | ./get_parted_info.py`
declare -i P1=${DATA[0]}
declare -i P1_1stSECTOR=${DATA[1]}
declare -i P1_lastSECTOR=${DATA[2]}
declare -i P2=${DATA[3]}
declare -i P2_1stSECTOR=${DATA[4]}
declare -i P2_lastSECTOR=${DATA[5]}

printf "For each partition:\n" | tee -a $TODO
printf "  #  Begin    End\n" | tee -a $TODO
printf "  %d  %d     %s\n" \
"$P1" "$P1_1stSECTOR" "$P1_lastSECTOR" | tee -a $TODO
printf "  %d  %d     %s\n" \
"$P2" "$P2_1stSECTOR" "$P2_lastSECTOR" | tee -a $TODO

# Exit with warning if any of the values is 0:
if [ $P1 -eq 0 ]           || [ $P2 -eq 0 ] \
|| [ $P1_1stSECTOR -eq 0 ] || [ $P2_1stSECTOR -eq 0 ] \
|| [ $P1_lastSECTOR -eq 0 ] || [ $P2_lastSECTOR -eq 0 ] ; then
    printf \
    "Error: partition tables have not been read correctly! \n" \
    | tee -a $TODO
    exit 1
fi

# Setp 7.
# Knowing 1.the size of the file system on the 2nd partition,
# and 2.the second partition's beginning sector: we can
# calculate a new ending sector:
declare -i ENDING_SECTOR=(P2_1stSECTOR-1)+P2SIZE/512
printf "About to run following command:\n"
printf "  $ parted -s %s resizepart %s %s\n" \
"$LOOPDEV" "$P2" "$ENDING_SECTOR" | tee -a $TODO
printf "...to resize the second partition.\n" | tee -a $TODO

#          script: never prompt the user
#          v
if parted -s $LOOPDEV resizepart $PART_NUMBER $ENDING_SECTOR; then
    printf \
    "Set the ending sector of the 2nd partition to %d.\n" \
    "$ENDING_SECTOR" \
    | tee -a $TODO
else
    printf "Error setting last sector of 2nd partition! \n" \
    | tee -a $TODO
    exit 1
fi

# Step 8.
printf "Detach the no longer needed loopback device.\n"
losetup -d $LOOPDEV

# Step 9.
declare -i TRUNC_SIZE=(ENDING_SECTOR+1)*512+MYSTERY
printf \
"Calculate image size to be %d bytes.\n" \
"$TRUNC_SIZE" | tee -a $TODO

if truncate --size=$TRUNC_SIZE $SC; then
    printf \
    "%s has been truncated to $d bytes.\n" \
    "$SC" "$TRUNC_SIZE" | tee -a $TODO
else
    printf "Error truncating  %s! \n" "$SC" | tee -a $TODO
    exit 1
fi

printf "\n\nStill TO-DO:\n" | tee -a $TODO

printf "1. %s ...\n" "$SC" | tee -a $TODO
printf \
".. was created by root so chanage its ownership:\n" | tee -a $TODO
printf "   $ sudo chown \$USER:\$USER %s\n" "$SC" | tee -a $TODO

printf \
"2. After shrinkage, it would be a good idea to\n" | tee -a $TODO
printf \
"rename %s ...\n" "$SC" | tee -a $TODO
printf \
"   $ mv %s %s\n" "$SC" "$SHRUNK" | tee -a $TODO

# printf "3a. Sometimes the partition auto mounts, if so ...\n" \
# | tee -a $TODO
# printf \
# "   $ sudo umount %s\n" "$PARTITION" | tee -a $TODO

printf \
"3. the script $ sudo ./load-shrunk.sh is provided\n" | tee -a $TODO
printf \
"to help get the image back onto an SD card. Look it\n" | tee -a $TODO
printf \
"over before using!! \n" | tee -a $TODO

printf \
"4. To distribute your new image file, you'll want to compress it:\n" \
| tee =a $TODO
printf "   $ zip -r %s %s\n" "$ZIPPED" "$SHRUNK" | tee -a $TODO

printf \
"\nHope this was successful and helpful. Have a nice day! :-)\n"
printf \
"PS: Check out %s for a synopsis. (Also %s.)\n" "$TODO" "$LOG"
printf \
"PPS: Direct comments, criticisms, &c. to alex@kleider.ca\n"


TIMESTAMP="`date '+%y-%m-%d %H:%M'`"
echo "" >> "$LOG"
echo "" >> "$LOG"

echo "# Python code- dated $TIMESTAMP" >> "$LOG"
echo "" >> "$LOG"
echo "blk_count = $SIZE" >> "$LOG"
echo "blk_size = $COUNT" >> "$LOG"
echo "p2size = blk_count * blk_size" >> "$LOG"
echo "p1first = $P1_1stSECTOR" >> "$LOG"
echo "p2first = $P2_1stSECTOR" >> "$LOG"
echo "p2last = (p2first -1) + p2size / 512" >> "$LOG"
echo "mystery = $MYSTERY" >> "$LOG"
echo "size = (p2last +1) * 512 + mystery" >> "$LOG"

echo 'print("""' >> "$LOG"
echo 'Regarding the second partition:' >> "$LOG"
echo '         Size:{:11.0f}' >> "$LOG"
echo '    Add extra:{:11.0f}' >> "$LOG"
echo 'P1 1st sector:{:11.0f}' >> "$LOG"
echo 'P2 1st Sector:{:11.0f}' >> "$LOG"
echo '  Last Sector:{:11.0f}' >> "$LOG"
echo '""".format(' >> "$LOG"
echo 'p2size,' >> "$LOG"
echo 'mystery,' >> "$LOG"
echo 'p1first,' >> "$LOG"
echo 'p2first,' >> "$LOG"
echo 'p2last,' >> "$LOG"
echo '))' >> "$LOG"


printf "\nScript completed at %s\n" \
"`date '+%%H:%M'`" | tee -a $TODO
printf   "... having begun at %s\n" "$BEGINTIME" | tee -a $TODO
