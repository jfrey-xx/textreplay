#!/bin/sh
while IFS='' read -r line ;  do
    echo "Converting hash: $line"
    cutycapt --url=file://$(pwd)/${line}.html --out=${line}.png 
done < "$1"
