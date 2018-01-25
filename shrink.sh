# File: shrink.sh

### First be sure the following is what you want:
### Especially the first one!!!

export SRC="/Downloads/ph-w-books2shrink.img"  # source image
export SC="/Downloads/shrink-candidate.img"  # sacrificial copy

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

declare -i MYSTERY=14888
# The "MYSTERY" integer is the 'extra' number of bytes that seem to be
# needed when shrinking.  If anyone knows why they are needed, please
# let me know!

TIME="`date '+%T'`"

echo "Enable loopback (if not already enabled...)"
modprobe loop

echo "Detach all associated loop devices."
losetup -D

echo "Request a new/free loopback device..."
LOOPDEV=`losetup -f`  # Expect it to be /dev/loop0
echo " => $LOOPDEV"
PARTITION=${LOOPDEV}p2
echo "... and the second partition is $PARTITION"

BEGIN_COPY="`date '+%T'`"
echo "Copy $SRC to $SC..."
cp $SRC $SC
echo " ... to leave original undisturbed."
printf "Copy began %s\n" $BEGIN_COPY
printf " and ended %s\n" "`date '+%T'`"

echo "Create a device for the image..."
losetup $LOOPDEV $SC

echo "Ask kernel to load the partitions that are on the image..."
partprobe $LOOPDEV
echo "=> ${LOOPDEV}p1 & ${LOOPDEV}p2 (provides access to partitions)"

echo "resize2fs demands fsck first..."
fsck.ext4 -f $PARTITION
echo "resize partition to minimum size..."
resize2fs -M $PARTITION

# Prepare temporary files for fact gathering using Python:
RES="sh.tmp"
RES1="py1.tmp"
RES2="py2.tmp"

# Part ONE: use dumpe2fs to get the size of our 2nd partition:
echo "Use dumpe2fs to get block count and size of 2nd partition..."
dumpe2fs -h ${LOOPDEV}p2 | grep -e "Block count" -e "Block size" > $RES
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
echo "fdisk -l to collect partition data..."
fdisk -l $LOOPDEV > $RES
# The results are again dumped into a temporary file
# to be parsed by the next command:
./getstartsectors.py $RES $RES1 $RES2

# As before, We collect those values into integer variables:
exec 5< $RES1; read LINE <&5; declare -i P1_1stSECTOR=$LINE
exec 6< $RES2; read LINE <&6; declare -i P2_1stSECTOR=$LINE

printf "Beginning (sh) sectors are %d and %d.\n" \
$P1_1stSECTOR $P2_1stSECTOR
echo "We don't need the first sector of the first partition."

# We no longer have need of our temporary files...
rm $RES $RES1 $RES2  # ...unless we are still debugging.

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

# loopback device no longer needed.
losetup -d $LOOPDEV

printf "\nScript began      %s\n" $TIME
printf "... and completed %s\n" "`date '+%T'`"

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

# Notes used during development:

# `sudo fdisk $SC` to shrink partition:
# $[(94208-1) + 680712 * 4096 / 512] => 5539903
# $[(94208-1) + 682573 * 4096 / 512] => 5554791
# $[(94208-1) + 684975 * 4096 / 512] => 5574007

# and shrink the image:
# `sudo truncate --size=$[(5539903+1)*512] $SC`
# `sudo truncate --size=$[(5554791+1)*512] $SC`
# `sudo truncate --size=$[(5554791+1)*512+14888] $SC`
# `sudo truncate --size=$[(5574007+1)*512+14888] $SC`
# 14888 is the mystery number of extra bytes needed.
# For Rachel image:
# will try 'sudo truncate --size=$[(117856945+1)*512+14888] $SC`

