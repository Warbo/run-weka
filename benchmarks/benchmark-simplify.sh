#!/usr/bin/env bash

echo "$0: not implemented yet" >> /dev/stderr
exit 1

while read -r CLUSTERS
do
    benchmark simplify equations from CLUSTERS output
done < <(clusterList)