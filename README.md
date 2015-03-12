##nmon for Linux

 

"... systems administrator, tuner, benchmark tool gives you a huge amount of important performance information in one go.", according to http://nmon.sourceforge.net/pmwiki.php

 

This fork displays steal time in both console (interactive) and file mode which is relevant for monitoring micro-partitioned virtual machines entitled to fractional CPU cores which is the case with AWS micro/small EC2 instances.

 

![CPU steal time, collected with nmon](https://www.axibase.com/images/nmon_stolen_cpu.png)

# Install
Download the latest version using git clone command or download an [nmon release](https://github.com/axibase/nmon/releases) from the site or Github.

Run the build.sh script.

This script helps run all the processes needed to compile nmon: it runs ./bootstrap (only once, when you first check out the code), followed by ./configure and make. The output of the build process is put into the current directory.

```bash
git clone git://github.com/axibase/nmon.git
cd nmon
./build.sh
```
If compilation was successful, you should have an nmon file in the current directory.

You can now execute command-line tool by invoking ./nmon. 

# Unistall
Just remove nmon binary file:

```bash
rm nmon
```
[![Build Status](https://travis-ci.org/axibase/nmon.svg)](https://travis-ci.org/axibase/nmon)
