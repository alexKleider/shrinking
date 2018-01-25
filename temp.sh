#!/bin/bash

# File: temp.sh
# Used for testing code.

LOOPDEV=`losetup -f`  # Expect it to be /dev/loop0
echo "LOOPDEV <== $LOOPDEV"
