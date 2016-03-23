##nmon for Linux

 

"... systems administrator, tuner, benchmark tool gives you a huge amount of important performance information in one go.", according to http://nmon.sourceforge.net/pmwiki.php

 

This fork displays steal time in both console (interactive) and file mode which is relevant for monitoring micro-partitioned virtual machines entitled to fractional CPU cores which is the case with AWS micro/small EC2 instances.

 

![CPU steal time, collected with nmon](https://www.axibase.com/images/nmon_stolen_cpu.png)

# Install
Download the latest version using git clone command:

```bash
git clone git://github.com/axibase/nmon.git
```

Or download an [nmon release](https://github.com/axibase/nmon/releases) from the site or Github.

To download a specific branch use the following command:

```bash
git clone git://github.com/axibase/nmon.git -b 16d
```

After this, you should enter the nmon sources directory and execute build.sh script to compile nmon ( on Debian, Ubuntu, Red Hat or Cent OS distributive ), or use 'make' utility to compile nmon from sources.

```bash
cd nmon
./build.sh
```

If compilation was successful, you should have an nmon file in the current directory.

You can now execute command-line tool by invoking ./nmon_{yourDistributive}. 

# Unistall
Just remove nmon binary file:

```bash
rm nmon
```
[![Build Status](https://travis-ci.org/axibase/nmon.svg)](https://travis-ci.org/axibase/nmon)
