# Low Power PCM Media Pipeline
#
#  Low power PCM media playback with SRC and volume.
#
# Pipeline Endpoints for connection are :-
#
#  host PCM_P --B0--> volume(0P) --B1--> SRC -- B2 --> Endpoint Pipeline
#

# Include topology builder
include(`utils.m4')
include(`src.m4')
include(`buffer.m4')
include(`pga.m4')
include(`mixercontrol.m4')
include(`pipeline.m4')
include(`pcm.m4')

#
# Controls
#
# Volume Mixer control with max value of 32
C_CONTROLMIXER(PCM PCM_ID Playback Volume, PIPELINE_ID,
	CONTROLMIXER_OPS(volsw, 256 binds the mixer control to volume get/put handlers, 256, 256),
	CONTROLMIXER_MAX(, 32),
	false,
	CONTROLMIXER_TLV(TLV 32 steps from -90dB to +6dB for 3dB, vtlv_m90s3),
	Channel register and shift for Front Left/Right,
	LIST(`	', KCONTROL_CHANNEL(FL, 1, 0), KCONTROL_CHANNEL(FR, 1, 1)))

#
# SRC Configuration
#

W_VENDORTUPLES(media_src_tokens, sof_src_tokens, LIST(`		', `SOF_TKN_SRC_RATE_OUT	"48000"'))

W_DATA(media_src_conf, media_src_tokens)

#
# Components and Buffers
#

# Host "Low latency Playback" PCM
# with 2 sink and 0 source periods
W_PCM_PLAYBACK(PCM_ID, Media Playback, 2, 0, 2)

# "Playback Volume" has 2 sink period and 2 source periods for host ping-pong
W_PGA(0, PIPELINE_FORMAT, 2, 2, 2, LIST(`		', "PCM PCM_ID Playback Volume PIPELINE_ID"))

# "SRC 0" has 2 sink and source periods.
W_SRC(0, PIPELINE_FORMAT, 2, 2, media_src_conf, 2)

# Media Source Buffers to SRC, make them big enough to deal with 2 * rate.
W_BUFFER(0, COMP_BUFFER_SIZE(4,
	COMP_SAMPLE_SIZE(PIPELINE_FORMAT), PIPELINE_CHANNELS, SCHEDULE_FRAMES),
	PLATFORM_HOST_MEM_CAP)
W_BUFFER(1,COMP_BUFFER_SIZE(4,
	COMP_SAMPLE_SIZE(PIPELINE_FORMAT), PIPELINE_CHANNELS, SCHEDULE_FRAMES),
	PLATFORM_COMP_MEM_CAP)

# Buffer B2 is on fixed rate sink side of SRC. Set it 1.5 * rate.
W_BUFFER(2, COMP_BUFFER_SIZE(3,
	COMP_SAMPLE_SIZE(PIPELINE_FORMAT), PIPELINE_CHANNELS, SCHEDULE_FRAMES),
	PLATFORM_COMP_MEM_CAP)

#
# Pipeline Graph
#
#  PCM --B0--> volume --B1--> SRC --> B2 --> Endpoint Pipeline
#

P_GRAPH(pipe-media-PIPELINE_ID, PIPELINE_ID,
	LIST(`		',
	`dapm(N_PCMP(PCM_ID), Media Playback PCM_ID)',
	`dapm(N_BUFFER(0), N_PCMP(PCM_ID))',
	`dapm(N_PGA(0), N_BUFFER(0))',
	`dapm(N_BUFFER(1), N_PGA(0))',
	`dapm(N_SRC(0), N_BUFFER(1))'
	`dapm(N_BUFFER(2), N_SRC(0))'))

#
# Pipeline Source and Sinks
#
indir(`define', concat(`PIPELINE_SOURCE_', PIPELINE_ID), N_BUFFER(2))

#
# Pipeline Configuration.
#

W_PIPELINE(N_SRC(0), SCHEDULE_DEADLINE, SCHEDULE_PRIORITY, SCHEDULE_FRAMES, SCHEDULE_CORE, 1, pipe_media_schedule_plat)

#
# PCM Configuration
#

# PCM capabilities supported by FW

PCM_CAPABILITIES(Media Playback PCM_ID, `S32_LE,S24_LE,S16_LE', PCM_MIN_RATE, PCM_MAX_RATE, 2, PIPELINE_CHANNELS, 2, 32, 192, 262144, 8388608, 8388608)

# PCM Low Latency Playback and Capture
SectionPCM.STR(Media Playback PCM_ID) {

	index STR(PIPELINE_ID)

	# used for binding to the PCM
	id STR(PCM_ID)

	dai.STR(Media Playback PCM_ID) {
		id STR(PCM_ID)
	}

	# Playback and Capture Configuration
	pcm."playback" {

		capabilities STR(Media Playback PCM_ID)
	}
}
