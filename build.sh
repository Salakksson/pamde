#!/usr/bin/env bash

set -e

CC=gcc
CCFLAGS="\
-Wall \
-O0 -g \
-fsanitize=address,undefined \
-fno-PIE \
"

LDFLAGS="\
-ltcl86 \
-fsanitize=address,undefined \
-no-pie \
"

BIN_DIR="./bin"

mkdir -p $BIN_DIR

TARGET=./pamde

objects=""
for file in src/*.c
do
	out=${file/src/$BIN_DIR}.o
	objects="$objects $out"

	echo $CC -c $CCFLAGS $file -o $out
	$CC -c $CCFLAGS $file -o $out
done

$CC $LDFLAGS $objects -o $TARGET

# change for linux
proccontrol -m aslr -s disable $TARGET














