#!/bin/sh
scriptDir="`readlink -f $0 | xargs dirname`"
outputLog="$scriptDir/output.log"
propertyFile="$scriptDir/deploy.properties"
nmonTools="$scriptDir/nmon.tar"
modifyCron="true"
dependenciesFailed="false"
mode="deploy"
dependencies="netstat telnet cron"

nmonArgs="-f -T"
nmonLogDir=""

senderArgs="" 
senderKey=""

systemSender=""
systemServers=""
systemUser=""
systemKey=""
systemDirectory=""
systemUserSudo=""
systemKeySudo=""

cronShedule=""
testVar="test"

while getopts "nrc:i" opt
do
    case $opt in
        c) propertyFile="$OPTARG";;
        n) modifyCron="false";;
        r) mode="reset";;
        i) mode="install";;
        *) echo "Available arguments: "
           echo "-c [propertyFilePath] : set path to property file. Default path: $propertyFile."
           echo "-n                    : do not modify cron. Will useful to update nmon or sender script."
           echo "-r                    : reset servers to default state ( restore crontab, remove nmon directory )."
           echo "-i                    : install mode. Check and install dependencies only. Requires the sudo credendials."
           exit 1
           ;;
    esac
done

if [ ! -f "$propertyFile" ]; then
    echo "Property file not found. ERROR."
    exit 1
fi

readProperties () {
    echo "Parsing property file ..."
    senderServer=""
    cronHour=""
    cronMinute=""
    while read line; do
        if [ `echo "$line" | grep -q "^#.*$"` ]; then
            continue
        fi
        key="`echo $line | awk -F = '{print $1}'`" 
        value="`echo $line | awk -F = '{print $2}'`" 
        case "$key" in
            "nmon.s")
                validValue="`echo "$value" | sed s/[^0-9]//g`"
                if [ "$validValue" != "$value" -o "$validValue" = "" ]; then
                    echo "Invalid property: $key. Only digit value available."
                else
                    nmonArgs="$nmonArgs -s $value"
                    senderArgs="$senderArgs -s $value"
                fi
                ;;
            "nmon.c")
                validValue="`echo "$value" | sed s/[^0-9]//g`"
                if [ "$validValue" != "$value" -o "$validValue" = "" ]; then
                    echo "Invalid property: $key. Only digit value available."
                else
                    nmonArgs="$nmonArgs -c $value"
                    senderArgs="$senderArgs -c $value"
                fi
                ;;
            "nmon.cron.hour")
                validValue="`echo "$value" | sed s/[^0-9]//g`"
                if [ "$validValue" != "$value" -o "$validValue" = "" ]; then
                    echo "Invalid property: $key. Only digit value available."
                else
                    cronHour="$value"
                fi
                ;;
            "nmon.cron.minute")
                validValue="`echo "$value" | sed s/[^0-9]//g`"
                if [ "$validValue" != "$value" -o "$validValue" = "" ]; then
                    echo "Invalid property: $key. Only digit value available."
                else
                    cronMinute="$value"
                fi
                ;;
            "sender.port")
                validValue="`echo "$value" | sed s/[^0-9]//g`"
                if [ "$validValue" != "$value" -o "$validValue" = "" ]; then
                    echo "Invalid property: $key. Only digit value available."
                else
                    senderArgs="$senderArgs -p $value"
                fi
                ;;
            "sender.server")
                senderServer="$value"
                ;;
            "sender.user")
                senderArgs="$senderArgs -u $value"
                ;;
            "sender.key")
                if [ ! -f "$value" ]; then
                    echo "ssh key file to send nmon data not found. ERROR."
                    exit 1
                else
                    senderKey="`readlink -f $value`"
                fi
                ;;
            "system.server")
                systemServers="$systemServers $value"
                ;;
            "system.user")
                systemUser="$value"
                ;;
            "system.user.sudo")
                systemUserSudo="$value"
                ;;
            "system.key")
                if [ ! -f "$value" ]; then
                    echo "ssh key file to deploy nmon files not found. ERROR."
                    exit 1
                else
                    systemKey="`readlink -f $value`"
                fi
                ;;
            "system.key.sudo")
                if [ ! -f "$value" ]; then
                    echo "ssh key file to install nmon dependencies not found. ERROR."
                    exit 1
                else
                    systemKeySudo="`readlink -f $value`"
                fi
                ;;
            "system.sender")
                if [ ! -f "$value" ]; then
                    echo "file in property $key does not exist: $value."
                    exit 1
                else
                    systemSender="`readlink -f $value`"
                fi
                ;;
            "system.nmon")
                if [ ! -f "$value" ]; then
                    echo "file in property $key does not exist: $value."
                    exit 1
                else
                    systemNmon="`readlink -f $value`"
                fi
                ;;
            "system.directory.log")
                nmonLogDir="$value"
                ;;
            "system.directory")
                systemDirectory="$value"
                nmonLogDir="$value/nmon_logs"
                nmonArgs="$nmonArgs -m $value/nmon_logs/"
                senderArgs="$senderArgs -m $value/nmon_logs/"
                ;;
        esac
    done < $propertyFile

    [ "$systemNmon" = "" ] && echo "Nmon binary file is not set ( system.nmon property ). ERROR." && exit 1
    [ "$systemSender" = "" ] && echo "Sender script file is not set ( system.nmon property ). ERROR." && exit 1
    if [ "$senderKey" = "" ]; then
        senderArgs="$senderServer$senderArgs >> $systemDirectory/full.log 2>&1"
    else
        senderArgs="$senderServer$senderArgs -i $systemDirectory/`basename $senderKey` >> $systemDirectory/full.log 2>&1"
    fi
    cronShedule="$cronMinute $cronHour * * *"
    echo "Parsinig finished."
}

showParsed () {
    echo ""
    echo "nmonArgs: $nmonArgs"
    echo "senderArgs: $senderArgs"
    echo "senderKey: $senderKey"
    echo "systemServers: $systemServers"
    echo "systemUser: $systemUser"
    echo "systemKey: $systemKey"
    echo "systemUserSudo: $systemUserSudo"
    echo "systemKeySudo: $systemKeySudo"
    echo "systemDirectory: $systemDirectory"
    echo "cronShedule: $cronShedule"
    echo "nmon: $systemNmon"
    echo "sender: $systemSender"
    echo ""
}

tarFiles () {
    rm -rf $scriptDir/tarTmp 
    mkdir $scriptDir/tarTmp
    [ "$senderKey" = "" ] || cp $senderKey $scriptDir/tarTmp/
    cp $systemNmon $scriptDir/tarTmp/
    cp $systemSender $scriptDir/tarTmp/
    cd $scriptDir/tarTmp
    tar -cvf $nmonTools * >/dev/null >>$outputLog 2>&1
    cd - >/dev/null >>$outputLog 2>&1
    rm -rf $scriptDir/tarTmp
}

configureServers () {
    echo "stage: deploy files ..."
    echo ""
    nmon="`basename $systemNmon`"
    sender="`basename $systemSender`"
    [ "$senderKey" = "" ] && key="" || key="`basename $senderKey`"
    for server in $systemServers; do
        addr="`echo $server | awk -F : '{print $1}'`" 
        port="`echo $server | awk -F : '{print $2}'`" 
        [ "$port" = "" ] && port=22
        echo "Working with server: $addr, port: $port"
        echo "Configure server ..."
        ssh -o "StrictHostKeyChecking no" -i $systemKey -p $port $systemUser@$addr "mkdir -p $nmonLogDir; [ ! -f /home/$systemUser/.cronDefault ] && crontab -l > /home/$systemUser/.cronDefault"  >>$outputLog 2>&1 #create cron backup if no exist and required directories.
        scp -i $systemKey -P $port $nmonTools $systemUser@$addr:$systemDirectory/ >>$outputLog 2>&1 #copy archive to server
        echo "Archive copied."

        if [ "$modifyCron" = "true" ]; then
            echo "Cron will be modified." 
            ssh -o "StrictHostKeyChecking no" -i $systemKey -p $port $systemUser@$addr "cd $systemDirectory && tar -xf nmon.tar; crontab -l > tmpcron; echo \"$cronShedule $systemDirectory/$nmon $nmonArgs\" >>tmpcron && echo \"$cronShedule $systemDirectory/$sender $senderArgs\" >>tmpcron; echo "" >>tmpcron; crontab tmpcron" >>$outputLog 2>&1 #extracting files, modify cron
        else
            echo "Cron will not be modified ( -n )."
            ssh -o "StrictHostKeyChecking no" -i $systemKey -p $port $systemUser@$addr "cd $systemDirectory && tar -xf nmon.tar" >>$outputLog 2>&1 #just extracting files ( update mode )
        fi
        echo "Nmon deployed."
    done
}

resetServers () {
    for server in $systemServers; do
        addr="`echo $server | awk -F : '{print $1}'`" 
        port="`echo $server | awk -F : '{print $2}'`" 
        [ "$port" = "" ] && port=22
        echo "Working with server: $addr, port: $port"
        ssh -o "StrictHostKeyChecking no" -i $systemKey -p $port $systemUser@$addr "rm -rf $systemDirectory; if [ -f /home/$systemUser/.cronDefault ]; then crontab /home/$systemUser/.cronDefault; exit 0; else exit 1; fi;" >>$outputLog 2>&1
        if [ $? -eq 0 ]; then
            echo "Server reset."
        else
            echo "Directory clean up, but default nmon file was not found to reset cron. Server reset."
        fi
    done
}

#return 0 if dependencies satisfied, else 1
checkDependencies () {
    echo "stage: Checking dependencies ..."
    echo ""
    for server in $systemServers; do
        addr="`echo $server | awk -F : '{print $1}'`" 
        port="`echo $server | awk -F : '{print $2}'`" 
        [ "$port" = "" ] && port=22
        echo "Working with server: $addr, port: $port"
        ssh -o "StrictHostKeyChecking no" -i $systemKey -p $port $systemUser@$addr "for util in $dependencies; do if ! which \$util >/dev/null 2>&1; then if [ \"\$util\" != \"cron\" ]; then exit 1; fi; fi; done; if [ \"\`ps -ef | grep cron | grep -v \"grep\"\`\" = \"\" ]; then exit 2; fi; if [ \"\`ps -ef | grep -i "nmon[[:space:]]" | grep -v \"\$\$\" |grep -v \"grep\"\`\" != \"\" ]; then exit 3; fi; exit 0" >>$outputLog 2>&1
        ec=$?
        echo -n "$addr:$port "
        if [ $ec -eq 1 ]; then
            echo "One of the following dependencies: [ $dependencies ] is not installed."
            echo "$addr:$port Please install dependencies manually or run script in installation mode ( -i ) with sudo user credentials ( system.user.sudo & system.key.sudo )"
            dependenciesFailed="true"
        elif [ $ec -eq 2 ]; then
            echo "Cron daemon is not running ( or is not installed )."
            echo "$addr:$port Run or install&run it before procceeding ( you are able to run $0 -i to fix it )."
            dependenciesFailed="true"
        elif [ $ec -eq 3 ]; then
            echo "nmon already running on current machine. Deploying to this machine will not continue."
            dependenciesFailed="true"
        else
            echo "is OK"
        fi
        echo ""
    done

    [ "$dependenciesFailed" = "true" ] && return 1 || return 0
}


installDependencies () {
    for server in $systemServers; do
        addr="`echo $server | awk -F : '{print $1}'`" 
        port="`echo $server | awk -F : '{print $2}'`" 
        [ "$port" = "" ] && port=22
        echo "Installation of dependencies: Working with server: $addr, port: $port"
        ssh -o "StrictHostKeyChecking no" -i $systemKeySudo -p $port $systemUserSudo@$addr "which yum && yum install -y cronie telnet net-tools || which zypper && zypper -n install cron telnet net-tools || which apt-get && apt-get install -y cron telnet net-tools; if [ \"\`ps -ef | grep cron | grep -v \"grep\"\`\" = \"\" ]; then cron; fi; for util in $dependencies; do if ! which \$util >/dev/null 2>&1; then if [ \"\$util\" != \"cron\" ]; then exit 1; fi; fi; done; if [ \"\`ps -ef | grep cron | grep -v \"grep\"\`\" = \"\" ]; then exit 2; fi; exit 0" >>$outputLog 2>&1
        ec=$?
        if [ $ec -eq 1 ]; then
            echo "Cannot install dependencies on current server. Please install them manually."
        elif [ $ec -eq 2 ]; then
            echo "Cannot run cron daemon ( or install it ) automaticly. Please start it manually before procceeding."
        else
            echo "Dependencies on server $server have been installed."
        fi
        echo ""
    done
    exit 0

}



readProperties
showParsed

echo "Current mode: $mode"
echo ""
case "$mode" in
    "reset")
        [ "$systemUser" = "" ] && echo "User not defined. ERROR." && exit 1
        [ "$systemKey" = "" ] && echo "ssh-key not defined. ERROR." && exit 1
        resetServers
        exit 0
        ;;
    "install")
        [ "$systemUserSudo" = "" ] && echo "Sudo user not defined. ERROR." && exit 1
        [ "$systemKeySudo" = "" ] && echo "Sudo ssh-key not defined. ERROR." && exit 1
        installDependencies
        exit 0
        ;;
    *)
        [ "$systemUser" = "" ] && echo "User not defined. ERROR." && exit 1
        [ "$systemKey" = "" ] && echo "ssh-key not defined. ERROR." && exit 1
        tarFiles
        checkDependencies
        if [ $? -eq 0 ]; then
            configureServers
        else
            echo "Some servers do not have the required dependencies. Install dependencies before procceeding."
        fi
        exit 0
        ;;
esac


