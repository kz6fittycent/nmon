#!/bin/sh
distr=""
release="`cat /etc/*-release`"
if `echo $release | grep -qi "CentOS"`; then
    distr="centos"
elif `echo $release | grep -qi "Red Hat"`; then
    distr="redhat"
elif `echo $release | grep -qi "Ubuntu"`; then
    distr="ubuntu"
elif `echo $release | grep -qi "Debian"`; then
    distr="debian"
fi

case "$distr" in
    "centos" | "redhat" )
        make nmon_x86_rhel4
        ;;
    "debian" )
        make nmon_x86_debian3
        ;;
    "ubuntu" )
        make nmon_x86_ubuntu134
        ;;
    * )
        echo "Your operation system is not supported by build script. Please look makefile to build nmon for your operation system."
        exit 1
        ;;
esac
exit 0
        


