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

export IMAGE="shrunk.img"
export DLDir="/Downloads"
export DeviceName="sdc"

# Want to be sure any and all partitions are unmountd:
umount /dev/${DeviceName}1
umount /dev/${DeviceName}2
# ....

DATE=`date`
sudo dd if="${DLDir}/${IMAGE}" of=/dev/$DeviceName bs=4M && sudo sync
printf "Transfer began    %s\n" $DATE
printf "... and completed %s\n" `date` 

