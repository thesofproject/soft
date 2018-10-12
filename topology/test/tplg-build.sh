#!/bin/bash

# Utility script to pre-process and compile topology sources into topology test
# binaries. Currently supports simple PCM <-> component <-> SSP style tests
# using simple_test()

# fail immediately on any errors
set -e

# M4 preprocessor flags
export M4PATH="../:../m4:../common:../platform/intel:../platform/common"

# Simple component test cases
# can be used on components with 1 sink and 1 source.
SIMPLE_TESTS=(test-all test-capture test-playback)
TONE_TEST=test-tone-playback
DMIC_TEST=test-capture
TEST_STRINGS=""
M4_STRINGS=""
# process m4 simple tests -
# simple_test(name, pipe_name, be_name, format, dai_id, dai_format, dai_phy_bits, dai_data_bits dai_bclk)
# 1) name - test filename suffix
# 2) pipe_name - test component pipeline filename in sof/
# 3) be_name - BE DAI link name in machine driver, used for matching
# 4) format - PCM sample format
# 5) dai_type - dai type e.g. SSP/DMIC
# 5) dai_id - SSP port number
# 6) dai_format - SSP sample format
# 7) dai_phy_bits - SSP physical number of BLKCs per slot/channel
# 8) dai_data_bits - SSP number of valid data bits per slot/channel
# 9) dai_bclk - SSP BCLK in HZ
# 10) dai_mclk - SSP MCLK in HZ
# 11) SSP mode - SSP mode e.g. I2S, LEFT_J, DSP_A and DSP_B
# 12) SSP mclk_id
# 13) Test pipelines
#

function simple_test {
	if [ $5 == "SSP" ]
	then
		TESTS=("${!16}")
	elif [ $5 == "DMIC" ]
	then
		TESTS=("${!17}")
	fi
	for i in ${TESTS[@]}
	do
		if [ $5 == "DMIC" ]
		then
			TFILE="$i-dmic$6-${14}-$2-$4-$7-$((${13} / 1000))k-$1"
			echo "M4 pre-processing test $i -> ${TFILE}"
			m4 ${M4_FLAGS} \
				-DTEST_PIPE_NAME="$2" \
				-DTEST_DAI_LINK_NAME="$3" \
				-DTEST_DAI_PORT=$6 \
				-DTEST_DAI_FORMAT=$7 \
				-DTEST_PIPE_FORMAT=$4 \
				-DTEST_DAI_TYPE=$5 \
				-DTEST_DMIC_DRIVER_VERSION=$8 \
				-DTEST_DMIC_CLK_MIN=$9 \
				-DTEST_DMIC_CLK_MAX=${10} \
				-DTEST_DMIC_DUTY_MIN=${11} \
				-DTEST_DMIC_DUTY_MAX=${12} \
				-DTEST_DMIC_SAMPLE_RATE=${13} \
				-DTEST_DMIC_PDM_CONFIG=${14} \
				-DTEST_PCM_MIN_RATE=${15} \
				-DTEST_PCM_MAX_RATE=${16} \
				$i.m4 > ${TFILE}.conf
			echo "Compiling test $i -> ${TFILE}.tplg"
			alsatplg -v 1 -c ${TFILE}.conf -o ${TFILE}.tplg
		else
			if [ "$USE_XARGS" == "yes" ]
			then
				#if DAI type is SSP, define the SSP specific params
				if [ $5 == "SSP" ]
				then
					if [ $i == "test-all" ]
					then
						TFILE="test-ssp$6-mclk-${13}-${12}-$2-$4-$7-48k-$((${11} / 1000))k-$1"
					else
						TFILE="$i-ssp$6-mclk-${13}-${12}-$2-$4-$7-48k-$((${11} / 1000))k-$1"
					fi
					#create input string for batch m4 processing
					M4_STRINGS+="-DTEST_PIPE_NAME=$2,-DTEST_DAI_LINK_NAME=$3\
						-DTEST_DAI_PORT=$6,-DTEST_DAI_FORMAT=$7\
						-DTEST_PIPE_FORMAT=$4,-DTEST_SSP_BCLK=${10}\
						-DTEST_SSP_MCLK=${11},-DTEST_SSP_PHY_BITS=$8\
						-DTEST_SSP_DATA_BITS=$9,-DTEST_SSP_MODE=${12}\
						-DTEST_SSP_MCLK_ID=${13},-DTEST_DAI_TYPE=$5\
						-DTEST_PCM_MIN_RATE=${14},-DTEST_PCM_MAX_RATE=${15}\
						$i.m4,${TFILE},"
					#create input string for batch processing of conf files
					TEST_STRINGS+=${TFILE}","
				fi
			else
				#if DAI type is SSP, define the SSP specific params
				if [ $5 == "SSP" ]
				then
					if [ $i == "test-all" ]
					then
						TFILE="test-ssp$6-mclk-${13}-${12}-$2-$4-$7-48k-$((${11} / 1000))k-$1"
					else
						TFILE="$i-ssp$6-mclk-${13}-${12}-$2-$4-$7-48k-$((${11} / 1000))k-$1"
					fi
					echo "M4 pre-processing test $i -> ${TFILE}"
					m4 ${M4_FLAGS} \
						-DTEST_PIPE_NAME="$2" \
						-DTEST_DAI_LINK_NAME="$3" \
						-DTEST_DAI_PORT=$6 \
						-DTEST_DAI_FORMAT=$7 \
						-DTEST_PIPE_FORMAT=$4 \
						-DTEST_SSP_BCLK=${10} \
						-DTEST_SSP_MCLK=${11} \
						-DTEST_SSP_PHY_BITS=$8 \
						-DTEST_SSP_DATA_BITS=$9 \
						-DTEST_SSP_MODE=${12} \
						-DTEST_SSP_MCLK_ID=${13} \
						-DTEST_DAI_TYPE=$5 \
						-DTEST_PCM_MIN_RATE=${14} \
						-DTEST_PCM_MAX_RATE=${15} \
						$i.m4 > ${TFILE}.conf
					echo "Compiling test $i -> ${TFILE}.tplg"
					alsatplg -v 1 -c ${TFILE}.conf -o ${TFILE}.tplg
				fi
			fi
		fi
	done
}

echo "Preparing topology build input..."

# Pre-process the simple tests
simple_test nocodec passthrough "NoCodec-2" s16le SSP 2 s16le 20 16 1920000 19200000 I2S 0 48000 48000 SIMPLE_TESTS[@]
simple_test nocodec passthrough "NoCodec-2" s24le SSP 2 s24le 25 24 2400000 19200000 I2S 0 48000 48000 SIMPLE_TESTS[@]
simple_test nocodec volume "NoCodec-2" s16le SSP 2 s16le 20 16 1920000 19200000 I2S 0 48000 48000 SIMPLE_TESTS[@]
simple_test nocodec volume "NoCodec-2" s24le SSP 2 s24le 25 24 2400000 19200000 I2S 0 48000 48000 SIMPLE_TESTS[@]
simple_test nocodec volume "NoCodec-2" s16le SSP 2 s24le 25 24 2400000 19200000 I2S 0 48000 48000 SIMPLE_TESTS[@]
simple_test nocodec src "NoCodec-2" s24le SSP 2 s24le 25 24 2400000 19200000 I2S 0 8000 192000 SIMPLE_TESTS[@]

simple_test codec passthrough "SSP2-Codec" s16le SSP 2 s16le 20 16 1920000 19200000 I2S 0 48000 48000 SIMPLE_TESTS[@]
simple_test codec passthrough "SSP2-Codec" s24le SSP 2 s24le 25 24 2400000 19200000 I2S 0 48000 48000 SIMPLE_TESTS[@]
simple_test codec volume "SSP2-Codec" s16le SSP 2 s16le 20 16 1920000 19200000 I2S 0 48000 48000 SIMPLE_TESTS[@]
simple_test codec volume "SSP2-Codec" s24le SSP 2 s24le 25 24 2400000 19200000 I2S 0 48000 48000 SIMPLE_TESTS[@]
simple_test codec volume "SSP2-Codec" s24le SSP 2 s16le 20 16 1920000 19200000 I2S 0 48000 48000 SIMPLE_TESTS[@]
simple_test codec volume "SSP2-Codec" s16le SSP 2 s24le 25 24 2400000 19200000 I2S 0 48000 48000 SIMPLE_TESTS[@]
simple_test codec src "SSP2-Codec" s24le SSP 2 s24le 25 24 2400000 19200000 I2S 0 8000 192000 SIMPLE_TESTS[@]

# for APL
APL_PROTOCOL_TESTS=(I2S LEFT_J DSP_A DSP_B)
APL_SSP_TESTS=(0 1 2 3 4 5)
APL_MODE_TESTS=(volume src)
APL_FORMAT_TESTS=(s16le s24le s32le)
MCLK_IDS=(0 1)

for protocol in ${APL_PROTOCOL_TESTS[@]}
do
	for ssp in ${APL_SSP_TESTS[@]}
	do
		for mode in ${APL_MODE_TESTS[@]}
		do
			for format in ${APL_FORMAT_TESTS[@]}
			do
				for mclk_id in ${MCLK_IDS[@]}
				do
					if [ $mode == "volume" ]
					then
						pcm_min=48000
						pcm_max=48000
					elif [ $mode == "src" ]
					then
						pcm_min=8000
						pcm_max=192000
					else
						pcm_min=48000
						pcm_max=48000
					fi

					simple_test nocodec $mode "NoCodec-${ssp}" $format SSP $ssp s16le 16 16 1536000 24576000 $protocol $mclk_id $pcm_min $pcm_max SIMPLE_TESTS[@]
					simple_test nocodec $mode "NoCodec-${ssp}" $format SSP $ssp s24le 32 24 3072000 24576000 $protocol $mclk_id $pcm_min $pcm_max SIMPLE_TESTS[@]
					simple_test nocodec $mode "NoCodec-${ssp}" $format SSP $ssp s32le 32 32 3072000 24576000 $protocol $mclk_id $pcm_min $pcm_max SIMPLE_TESTS[@]

					simple_test codec $mode "SSP${ssp}-Codec" $format SSP $ssp s16le 16 16 1536000 24576000 $protocol $mclk_id $pcm_min $pcm_max SIMPLE_TESTS[@]
					simple_test codec $mode "SSP${ssp}-Codec" $format SSP $ssp s24le 32 24 3072000 24576000 $protocol $mclk_id $pcm_min $pcm_max SIMPLE_TESTS[@]
					simple_test codec $mode "SSP${ssp}-Codec" $format SSP $ssp s32le 32 32 3072000 24576000 $protocol $mclk_id $pcm_min $pcm_max SIMPLE_TESTS[@]
				done
			done
		done
		for mclk_id in ${MCLK_IDS[@]}
		do
			simple_test nocodec passthrough "NoCodec-${ssp}" s16le SSP $ssp s16le 16 16 1536000 24576000 $protocol $mclk_id 48000 48000 SIMPLE_TESTS[@]
			simple_test nocodec passthrough "NoCodec-${ssp}" s24le SSP $ssp s24le 32 24 3072000 24576000 $protocol $mclk_id 48000 48000 SIMPLE_TESTS[@]
			simple_test nocodec passthrough "NoCodec-${ssp}" s32le SSP $ssp s32le 32 32 3072000 24576000 $protocol $mclk_id 48000 48000 SIMPLE_TESTS[@]

			simple_test codec passthrough "SSP${ssp}-Codec" s16le SSP $ssp s16le 16 16 1536000 24576000 $protocol $mclk_id 48000 48000 SIMPLE_TESTS[@]
			simple_test codec passthrough "SSP${ssp}-Codec"	s24le SSP $ssp s24le 32 24 3072000 24576000 $protocol $mclk_id 48000 48000 SIMPLE_TESTS[@]
			simple_test codec passthrough "SSP${ssp}-Codec"	s32le SSP $ssp s32le 32 32 3072000 24576000 $protocol $mclk_id 48000 48000 SIMPLE_TESTS[@]
		done
	done
done

for protocol in ${APL_PROTOCOL_TESTS[@]}
do
	for ssp in ${APL_SSP_TESTS[@]}
	do
		for mode in ${APL_MODE_TESTS[@]}
		do
			for format in ${APL_FORMAT_TESTS[@]}
			do
				if [ $mode == "volume" ]
				then
					pcm_min=48000
					pcm_max=48000
				elif [ $mode == "src" ]
				then
					pcm_min=8000
					pcm_max=192000
				else
					pcm_min=48000
					pcm_max=48000
				fi

				simple_test nocodec $mode "NoCodec-${ssp}" $format SSP $ssp s16le 20 16 1920000 19200000 $protocol 0 $pcm_min $pcm_max SIMPLE_TESTS[@]
				simple_test nocodec $mode "NoCodec-${ssp}" $format SSP $ssp s24le 25 24 2400000 19200000 $protocol 0 $pcm_min $pcm_max SIMPLE_TESTS[@]

				simple_test codec $mode "SSP${ssp}-Codec" $format SSP $ssp s16le 20 16 1920000 19200000 $protocol 0 $pcm_min $pcm_max SIMPLE_TESTS[@]
				simple_test codec $mode "SSP${ssp}-Codec" $format SSP $ssp s24le 25 24 2400000 19200000 $protocol 0 $pcm_min $pcm_max SIMPLE_TESTS[@]
			done
		done
		simple_test nocodec passthrough "NoCodec-${ssp}" s16le SSP $ssp s16le 20 16 1920000 19200000 $protocol 0 48000 48000 SIMPLE_TESTS[@]
		simple_test nocodec passthrough "NoCodec-${ssp}" s24le SSP $ssp s24le 25 24 2400000 19200000 $protocol 0 48000 48000 SIMPLE_TESTS[@]

		simple_test codec passthrough "SSP${ssp}-Codec" s16le SSP $ssp s16le 20 16 1920000 19200000 $protocol 0 48000 48000 SIMPLE_TESTS[@]
		simple_test codec passthrough "SSP${ssp}-Codec" s24le SSP $ssp s24le 25 24 2400000 19200000 $protocol 0 48000 48000 SIMPLE_TESTS[@]
	done
done

# for CNL
simple_test nocodec passthrough "NoCodec-2" s16le SSP 2 s16le 25 16 2400000 24000000 I2S 0 48000 48000 SIMPLE_TESTS[@]
simple_test nocodec passthrough "NoCodec-2" s24le SSP 2 s24le 25 24 2400000 24000000 I2S 0 48000 48000 SIMPLE_TESTS[@]
simple_test nocodec volume "NoCodec-2" s16le SSP 2 s16le 25 16 2400000 24000000 I2S 0 48000 48000 SIMPLE_TESTS[@]
simple_test nocodec volume "NoCodec-2" s16le SSP 2 s24le 25 24 2400000 24000000 I2S 0 48000 48000 SIMPLE_TESTS[@]
simple_test nocodec volume "NoCodec-2" s24le SSP 2 s24le 25 24 2400000 24000000 I2S 0 48000 48000 SIMPLE_TESTS[@]
simple_test nocodec volume "NoCodec-2" s24le SSP 2 s16le 25 16 2400000 24000000 I2S 0 48000 48000 SIMPLE_TESTS[@]
simple_test nocodec src "NoCodec-4" s24le SSP 4 s24le 25 24 2400000 24000000 I2S 0 8000 192000 SIMPLE_TESTS[@]

# Tone test: Tone component only supports s32le currently
simple_test codec tone "SSP2-Codec" s32le SSP 2 s16le 20 16 1920000 19200000 I2S 0 48000 48000 TONE_TEST[@]
#Tone Test for APL
simple_test codec tone "SSP5-Codec" s32le SSP 5 s24le 32 24 3072000 24576000 I2S 0 48000 48000 TONE_TEST[@]
simple_test codec tone "SSP5-Codec" s32le SSP 5 s32le 32 32 3072000 24576000 I2S 0 48000 48000 TONE_TEST[@]

# DMIC Test Topologies for APL/GLK
DMIC_PDM_CONFIGS=(MONO_PDM0_MICA MONO_PDM0_MICB STEREO_PDM0 STEREO_PDM1 FOUR_CH_PDM0_PDM1)
DMIC_SAMPLE_RATE=(8000 16000 24000 32000 48000 64000 96000)
DMIC_SAMPLE_FORMATS=(s16le s32le)

for pdm in ${DMIC_PDM_CONFIGS[@]}
do
	for rate in ${DMIC_SAMPLE_RATE[@]}
	do
		for format in ${DMIC_SAMPLE_FORMATS[@]}
		do
			simple_test nocodec passthrough "DMIC0" $format DMIC 0\
				$format 1 500000 4800000 40 60 $rate $pdm\
				8000 96000\
				DMIC_TEST[@]
		done
	done
done

if [ "$USE_XARGS" == "yes" ]
then
	echo "Batch processing m4 files..."
	M4_STRINGS=${M4_STRINGS%?}
	#m4 processing
	echo $M4_STRINGS | tr " " "," | tr '\n' '\0' | xargs -P0 -d ',' -n16 bash -c 'm4 "${@:1:${#}-1}" > ${16}.conf' m4

	#execute alsatplg to create topology binary
	TEST_STRINGS=${TEST_STRINGS%?}
	echo $TEST_STRINGS | tr '\n' ',' |\
		xargs -d ',' -P0 -n1 -I string alsatplg -v 1 -c\
			string".conf" -o string".tplg"
fi

