# File: shrink.sh

### First be sure the following is what you want:
### Especially the first one!!!

export SRC="/Downloads/ph-w-books2shrink.img"  # source image
export SC="/Downloads/shrink-candidate.img"  # sacrificial copy

# Usage:
#   sudo ./shrink.sh  # takes <4 minutes (on my machine)

# Sets up a loop device and onto it loads the image to be shrunk.
# Shrinks the file system and then reports its size.
# After this need only to shrink the partition and then
# shrink and rename the image.

DATE=`date`

echo "Enable loopback (if not already enabled...)"
modprobe loop

echo "Detach all associated loop devices."
losetup -D

echo "Request a new/free loopback device..."
LOOPDEV=`losetup -f`  # Expect it to be /dev/loop0
echo " => $LOOPDEV"

# echo "remove $SC..."
# rm $SC
echo "Copy $SRC to $SC..."
cp $SRC $SC
echo " ... to leave original undisturbed."

echo "Create a device for the image..."
losetup $LOOPDEV $SC

echo "Ask kernel to load the partitions that are on the image..."
partprobe $LOOPDEV
echo "=> ${LOOPDEV}p1 & ${LOOPDEV}p2 (provides access to partitions)"

echo "resize2fs demands fsck first..."
fsck.ext4 -f ${LOOPDEV}p2
echo "resize partition to minimum size..."
resize2fs -M ${LOOPDEV}p2

echo "Use dumpe2fs to get block count and size of 2nd partition..."
dumpe2fs -h ${LOOPDEV}p2 | grep -e "Block count" -e "Block size"

echo "fdisk -l to just list partitions..."
fdisk -l $LOOPDEV

echo "loopback-device no longer needed..."
losetup -d $LOOPDEV

printf "Script began      %s\n" $DATE
printf "... and completed %s\n" `date` 

# Still to do:

# `sudo fdisk $SC` to shrink partition:
# $[(94208-1) + 680712 * 4096 / 512] => 5539903
# $[(94208-1) + 682573 * 4096 / 512] => 5554791
# $[(94208-1) + 684975 * 4096 / 512] => 5574007

# and shrink the image:
# `sudo truncate --size=$[(5539903+1)*512] $SC`
# `sudo truncate --size=$[(5554791+1)*512] $SC`
# `sudo truncate --size=$[(5554791+1)*512+14888] $SC`
# `sudo truncate --size=$[(5574007+1)*512+14888] $SC`
# For Rachel image:
# will try 'sudo truncate --size=$[(117856945+1)*512+14888] $SC`

# Rename shrunken image:
# mv $SC shrunk.img
# & then `dd` it to an sd card:
# sudo su && source load-shrunk.sh && exit
# export IMAGE="shrunk.img"

