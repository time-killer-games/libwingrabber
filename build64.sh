#!/bin/sh
cd "${0%/*}"

clang++ wingrabber.mm -o libwingrabber.dylib -shared -ObjC++ -std=c++17 -framework CoreFoundation -framework CoreGraphics -framework Cocoa -arch arm64 -arch x86_64