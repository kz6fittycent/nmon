#!/bin/sh
CFLAGS="-g -O2 -D JFS -D GETUSER -Wall -D LARGEMEM"
LDFLAGS="-lncurses -g"
COMPILER="gcc"
FILE="lmon14i.c"
if [ `which $COMPILER` ]; then
    $COMPILER -o nmon $FILE $CFLAGS $LDFLAGS -D X86
else
    echo "Please install gnu linux compiler or fix COMPILE variable for your system in the build script"
fi

