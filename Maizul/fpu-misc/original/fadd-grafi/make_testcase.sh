#!/bin/sh
./TestData $1 > input-expect
cat input-expect | cut -d' ' -f1,2 | sed -e "s/^/2 fadd /" > input
cat input-expect | cut -d' ' -f3 > expect
