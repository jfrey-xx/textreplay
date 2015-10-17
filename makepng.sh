#!/bin/bash
i=0
while IFS='' read -r line ;  do
    $((++i))
    printf -v num '%07d' $i
    echo "Converting hash: $line --> ${num}.png"
    if [ -s  ${line} ] ; then
       cutycapt --url=file://$(pwd)/${line}.html --out=${num}.png 
    else
        echo "empty file, skip."
    fi ;
done < "$1"
