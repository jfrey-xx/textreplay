#!/bin/bash

# resizing version

i=0
while IFS='' read -r line ;  do
    printf -v num '%07d' $i
    echo "Converting hash: $line --> ${num}.png"
    if [ -s  ${line}.html ] ; then
       i=$((i+1))
       cutycapt --min-width=7680 --min-height=4320 --url=file://$(pwd)/${line}.html --out=${num}.png 

    echo "Resizing..."
    convert ${num}.png -resize 3840x2160 ${num}.png

    else
        echo "empty file, skip."
    fi ;
done < "$1"
