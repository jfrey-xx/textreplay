#!/bin/bash
i=0
while IFS='' read -r line ;  do
    $((++i))
    printf -v num '%07d' $i
    echo "Converting hash: $line --> ${num}.png"
    cutycapt --url=file://$(pwd)/${line}.html --out=${num}.png 
done < "$1"
