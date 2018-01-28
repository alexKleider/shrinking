#!/bin/bash

# File: load-shrunk.sh

# Restore a shrunken image
# Assume we have a shrunken image (its file name assigned to IMAGE)
# in the directory assigned to DLDir
# and we want to load the image on to a (SD card) device
# specified by DeviceName.  (eg: sdc, NOT: /dev/sdc)

# The code unmounts up to 2 partitions (just in case you haven't
# already done it- if there are more: it's your look out!)

# USEAGE:
#	sudo load-shrunk.sh

declare IMAGE="shrunk.img"
declare DLDir="/Downloads"
declare DeviceName="sdc"
declare P1="/dev/${DeviceName}1"
declare P2="/dev/${DeviceName}2"

# Want to be sure any and all partitions are unmountd:
printf "Unmounting any possibly still mounted partitions.\n"

declare MOUNTED1=`mount | grep -e "$P1"`
if [ "$MOUNTED1" ] ; then 
    printf "Unmounting %s\n" "$P1"
    umount "$P1"
fi
declare MOUNTED2=`mount | grep -e "$P2"`
if [ "$MOUNTED2" ] ; then
    printf "Unmounting %s\n" "$P2"
    umount "$P2"
fi

BEGIN="`date '+%T'`"
printf \
"Begin copying %s to %s\n" \
"${DLDir}/${IMAGE}" "/dev/${DeviceName}"
printf "...at %s (takes about 9 min.)\n" "$BEGIN"
dd if="${DLDir}/${IMAGE}" of="/dev/${DeviceName}" bs=4M 
sync

END="`date '+%T'`"
printf "\nCopy completed at %s\n" "$END"
printf   "..having begun at %s\n" "$BEGIN"

