#!/bin/bash
i=0
while IFS='' read -r line ;  do
    printf -v num '%07d' $i
    echo "Converting hash: $line --> ${num}.png"
    if [ -s  ${line} ] ; then
       i=$((i+1))
       cutycapt --url=file://$(pwd)/${line}.html --out=${num}.png 
    else
        echo "empty file, skip."
    fi ;
done < "$1"
