##nmon for Linux

 

"... systems administrator, tuner, benchmark tool gives you a huge amount of important performance information in one go.", according to http://nmon.sourceforge.net/pmwiki.php

 

This fork displays steal time in both console (interactive) and file mode which is relevant for monitoring micro-partitioned virtual machines entitled to fractional CPU cores which is the case with AWS micro/small EC2 instances.

 

![CPU steal time, collected with nmon](https://www.axibase.com/images/nmon_stolen_cpu.png)

# Build

```bash
make nmon_x86_ubuntu134
```
or

```bash
./build.sh
```

[![Build Status](https://travis-ci.org/axibase/nmon.svg)](https://travis-ci.org/axibase/nmon)
