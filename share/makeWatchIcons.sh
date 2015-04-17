#!/bin/bash
#############################################################################
# makeWatchIcons.sh
#
# Call with the original image path from which to generate the image.
# Saves all icons required for Apple Watch Apps to the current directory. 
#############################################################################
# Copyright (c) 2015 VideoLAN. All rights reserved.
# $Id$
#
# Author: Tobias Conradi <videolan # tobias-conradi.de>
#
# Refer to the COPYING file of the official project for license.
#############################################################################

sips $1 --out AppIcon24@2x.png --resampleWidth 48
sips $1 --out AppIcon27.5@2x.png --resampleWidth 55
sips $1 --out AppIcon29@2x.png --resampleWidth 58
sips $1 --out AppIcon29@3x.png --resampleWidth 87
sips $1 --out AppIcon40@2x.png --resampleWidth 80
sips $1 --out AppIcon44@2x.png --resampleWidth 88
sips $1 --out AppIcon86@2x.png --resampleWidth 172
sips $1 --out AppIcon98@2x.png --resampleWidth 196