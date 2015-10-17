#!/bin/sh

avconv  -f image2 -r 6 -i '%07d.png' -s:v 1280x720  output.mp4