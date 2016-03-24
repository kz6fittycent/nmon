##nmon for Linux
[![Build Status](https://travis-ci.org/axibase/nmon.svg)](https://travis-ci.org/axibase/nmon)
 

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

# Simple sender examples

* Create a file ```/opt/nmon/nmon_script.sh``` and add it to the cron schedule:

```
0 * * * * /opt/nmon/nmon_script.sh
```

* Put one of the following examples to ```/opt/nmon/nmon_script.sh```

> **Note:** Make sure that ```/opt/nmon/nmon``` binary is exist and executable.




## Send by ```wget```



```bash
#!/bin/sh
fn="/tmp/nmon/`date +%y%m%d_%H%M`.nmon";pd="`/opt/nmon/nmon_rpm -F $fn -s 60 -c 60 -T -p`"; \
while kill -0 $pd; do sleep 15; done; \
wget -t 1 -T 10 --user=atsd_user --password=atsd_password --no-check-certificate -O - --post-file="$fn" \
--header="Content-type: text/csv" "https://atsd_server/api/v1/nmon?f=`basename $fn`"
```

## Send by ```unix socket``` ( ```bash``` is required ):

```bash
#!/bin/sh
fn="/opt/nmon/`date +%y%m%d_%H%M`.nmon";pd="`/opt/nmon/nmon -F $fn -s 6 -c 2 -T -p`"; \
while kill -0 $pd; do sleep 15; done; \
{ echo "nmon p:default e:`hostname` f:`hostname`_file.nmon"; cat $fn; } > /dev/tcp/atsd_server/8081
```

## Send by ```nc``` util:

```bash
#!/bin/sh
fn="/opt/nmon/`date +%y%m%d_%H%M`.nmon";pd="`/opt/nmon/nmon -F $fn -s 6 -c 2 -T -p`"; \
while kill -0 $pd; do sleep 15; done; \
{ echo "nmon p:default e:`hostname` f:`hostname`_file.nmon"; cat $fn; } | nc atsd_server 8081
```


