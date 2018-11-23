#!/bin/bash

set -e

ITERATIONS=1000
COUNTER=0

while [ $COUNTER -lt $ITERATIONS ]; do
	echo "Test $COUNTER"
	dmesg -C

	SUSPEND_TIME=$(($RANDOM%5+5)) # suspend: 5~10 seconds
	echo “System will suspend after $SUSPEND_TIME seconds ...”
	sleep $SUSPEND_TIME
	WAKE_TIME=$(($RANDOM%5+5)) # wake: 5~10 seconds
	echo "system will resume after $WAKE_TIME seconds ..."
	# do system suspend and resume
	rtcwake -m mem -s $WAKE_TIME

	# check error
	unset ERROR
	ERROR=$(dmesg | grep sof-audio | grep -v "failed" | grep "error")
	if [ ! -z "$ERROR" ]
	then
		dmesg > test_${COUNTER}_fail.log
		echo "Suspend/resume failed, see test_${COUNTER}_fail.log for details"
		exit 1
	else
		echo "Test ${COUNTER} success"
	fi

	dmesg > test_${COUNTER}_pass.log
	let COUNTER+=1
done
