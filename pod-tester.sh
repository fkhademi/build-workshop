#!/bin/bash

for i in {1..46}
do
 curl -s -w "Pod $i: %{http_code}\n" https://client.pod$i.avxlab.cc/ -o /dev/null
done
