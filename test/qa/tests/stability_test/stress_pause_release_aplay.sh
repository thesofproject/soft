#!/bin/bash

# set default
DEV='hw:0,0'
FREQ=48000
FORMAT=S16_LE
CHL=2
DURATION=600
TIME=0.5 # do pause/release per * second

# get parameters
while getopts ':D:r:f:c:' OPT &> /dev/null;
do
	case $OPT in
		D)
		PCM_DEV=$OPTARG;;
		r)
		FREQ=$OPTARG;;
		f)
		FORMAT=$OPTARG;;
		c)
		CHL=$OPTARG;;
		*)
		echo "Usage : ./stress_pause_release_aplay.sh -D$pcm_device -r $frequency -f $format -c $channel \n"
		echo "Default will play 48K 16bit stereo wav via PCM0"
	exit 7;;
	esac
done

expect << EOF

spawn aplay -D$DEV -r $FREQ -f $FORMAT -c $CHL -i -vv -d $DURATION /dev/zero
expect {
	"Input/output" { send_user "error\n" }
	"#+*" {
	sleep $TIME
	send " "
	exp_continue
	}
    "*PAUSE*" {
	sleep $TIME
	send " ";
	exp_continue
	}
}

EOF
