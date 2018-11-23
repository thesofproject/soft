#!/bin/bash

# set default
TEST_TYPE='aplay'
DEV='hw:0,0'
FREQ=48000
FORMAT=S16_LE
CHL=2
DURATION=600 # testing time
TIME=0.5 # do pause/release per * second

# get parameters
while getopts ':t:D:r:f:c:' OPT &> /dev/null;
do
	case $OPT in
		t)
		TEST_TYPE=$OPTARG;;
		D)
		PCM_DEV=$OPTARG;;
		r)
		FREQ=$OPTARG;;
		f)
		FORMAT=$OPTARG;;
		c)
		CHL=$OPTARG;;
		*)
		echo "Usage : ./stress_pause_release.sh -t aplay/arecord -Dpcm_device -r frequency -f format -c channel"
		echo "Default will play 48K 16bit stereo wav via PCM0"
	exit 7;;
	esac
done

# get the test type
if [ $TEST_TYPE == aplay ]
then
	WAV_FILE=/dev/zero
elif [ $TEST_TYPE == arecord ]
then
	WAV_FILE=/dev/null
else
	echo "Wrong test type: $TEST_TYPE, shoule be aplay or arecord."
fi

# inset expect interactive programs to simulate the action of pressing the space key
expect << EOF

spawn $TEST_TYPE -D$DEV -r $FREQ -f $FORMAT -c $CHL -i -vv -d $DURATION $WAV_FILE
expect {
	{ # wait for the "message" prompt, once 'Input/Ouput occurs, output error }
	"Input/output" { send_user "error\n" }
	{ # once '#+' occurs, send the space key, then continue }
	"*#+*" {
	sleep $TIME
	send " "
	exp_continue
	}
	{ # once 'PAUSE' occurs, send the space key, then continue }
	"*PAUSE*" {
	sleep $TIME
	send " "
	exp_continue
	}
}

EOF
