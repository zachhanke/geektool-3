#!/bin/bash
############################
# Kill NerdTool RO process #
############################
# Return codes
# -1 : help was accessed
#  0 : NTRO is should not be running
#  1 : NTRO is should be running

killProc=0
while [ $# -gt 0 ]
    do
        case $1 in

        "-k" ) killProc=1
            shift 1
        ;;
        "-h" ) echo "Usage: `basename $0` [-hk]"
            echo "Finds the NerdToolRO process"
            echo "-k"
            echo "	kill the NerdToolRO process if it exists"
            echo "-h"
            echo "  display this help message"
            shift 1
            exit -1
        ;;
        esac
    done

#nerdtoolROPID=`grep "You have used" /tmp/bandDump.txt | sed -E 's/.*used ([0-9]+) MB.*/\1/'`
nerdtoolROPID=`ps -A | grep '[/]NerdToolRO.app' | awk '{print $1}'`

if [ -z $nerdtoolROPID ] 
    then
        echo "NerdToolRO not found to be running. Exiting"
        exit 0
    fi

if [ $killProc -eq 1 ] 
    then 
        echo "NerdToolRO found to be running. Killing."
        kill $nerdtoolROPID
        exit 1
    fi

exit 1
