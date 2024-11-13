#!/usr/bin/bash

find . -type f -iname "*cue" -exec rm {} \;
find . -type f -iname "*cue" -exec rm {} \;
find . -type f -iname "*m3u" -exec rm {} \;
find . -type f -iname "*txt" -exec rm {} \;
find . -type f -iname "*log" -exec rm {} \;
find . -type f -iname "*xlsx" -exec rm {} \;
find . -type f -iname "*md5" -exec rm {} \;
find . -type f -iname "*nzb" -exec rm {} \;
find . -type f -iname "*accurip" -exec rm {} \;
find . -type f -iname "*url" -exec rm {} \;
find . -type f -iname "foo_dy*" -exec rm {} \;
find . -type d -iname "artwork" -exec rm -rf {} \;
