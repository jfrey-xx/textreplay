#!/bin/sh

avconv  -f image2 -r 6 -i '%07d.png' output.mp4
