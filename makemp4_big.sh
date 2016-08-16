#!/bin/sh

# newer version of ffmpeg for x265
ffmpeg3.0  -f image2 -r 30 -i '%07d.png' -s:v 7680x4320 -c:v libx265  -crf 20 output_big_fbs30_crf20.mp4
