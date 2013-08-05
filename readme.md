JPEGrescan plugin for Adobe Photoshop Lightroom
===============================================

Lightroom plugin by Jarno Heikkinen <info@capturemonkey.com>  
Based on jpegrescan by Loren Merritt  


Introduction
------------

This is a simple Lightroom export plugin, which attempts to reduce JPEG files
by using different lossless compression parameters on the exported file.

There are two modes of operation; fast mode which uses static scans file; and
a brute-force method using jpegrescan script.  jpegrescan is always smallest,
but it can take several seconds per image.

Currently, only Mac OS X is supported with jpegrescan; I don't have a working 
Windows environment  available for development or testing (jpegrescan requires 
Perl and jpegtran).

Simply install the plugin and add the export filter in the Lightroom's export dialog.
In the export settings, you can also optionally set removal of _ALL_ metadata, including
ICC profiles and such.

You can also see some byte statistics in the plugin manager.


jpegtran
--------
Mac OS X binary of jpegtran was compiled from
[jpegsrc.v9.tar.gz](http://www.ijg.org/files/jpegsrc.v9.tar.gz) with commands:

    ./configure -disable-shared CFLAGS="-Os -arch i386 -arch x86_64 -mmacosx-version-min=10.5" LDFLAGS="-arch i386 -arch x86_64 -mmacosx-version-min=10.5" --disable-dependency-tracking
    make jpegtran
    strip jpegtran
