---
layout: default
title: Shrink Image Files
---
[![CircleCI](https://circleci.com/gh/alexKleider/phInfo.svg?style=svg)](https://circleci.com/gh/alexKleider/phInfo)

# How To Shrink Image Files

This repo contains my exploration of how to go about creating the
smallest possible image files.  This is done in the context of the
Raspberry Pi- more specifically, trying to shrink the Raspbian Image
after the standard Raspbian OS has been updated and configured to suit
certain purposes.

Here's the work flow:
    Configure the Raspberry Pi to suit your purposes.
    Create an '.img' file of your Pi's sd card using 'dd'.
    Edit shrink.sh[1] to adjust the name(s) of the file(s).
    Run shrink.sh with root privileges. i.e. $ sudo shrink.sh
    Have a look at the newly created (by shrink.sh) TODO file
    for further suggestions.

[1] Currently there are two versions of shrink.sh:
    shrinkv1.sh uses GNU parted and depends on get_parted_info.py
    shrinkv2.sh uses sfdisk and depends on get_dump.py
    Both depend on use_dump2efs.py
    Take your pick.
