#!/bin/bash
#
## @file get-number.sh
## @brief Download Wallhaven wallpaper by number
## @author Ronald Joe Record (rr at ronrecord dot com)
## @copyright Copyright (c) 2016, Ronald Joe Record, all rights reserved.
## @date Written 17-Sep-2016
## @version 1.0.1
##

[ -r ./utils ] && . ./utils
[ "$WHDIR" ] || WHDIR="/Volumes/My_Book_Studio/Pictures/Work/Wallhaven"

DDIR="${WHDIR}/Misc"

[ "$numdown" ] || numdown=480
[ "$categories" ] || categories=001
[ "$filters" ] || filters=001

[ -d "${DDIR}" ] || mkdir -p "${DDIR}"
cd "${DDIR}"

url="https://wallpapers.wallhaven.cc/wallpapers/full/wallhaven"
client="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.99 Safari/537.36"
[ -r wallhaven-$numdown.jpg ] || {
    [ -r wallhaven-$numdown.png ] || {
        wget -q -U "$client" $url-$numdown.jpg
        wget -q -U "$client" $url-$numdown.png
        if [ -r wallhaven-$numdown.jpg ]
        then
            echo "$numdown" >> downloaded.txt
        else
            [ -r wallhaven-$numdown.png ] && {
                echo "$numdown" >> downloaded.txt
            }
        fi
    }
}
