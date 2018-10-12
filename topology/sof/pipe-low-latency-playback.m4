# Low Latency Pipeline
#
#  Low Latency Playback PCM mixed into single sink pipe.
#  Low latency Capture PCM.
#
# Pipeline Endpoints for connection are :-
#
#	LL Playback Mixer (Mixer)
#	LL Capture Volume B4 (DAI buffer)
#	LL Playback Volume B3 (DAI buffer)
#
#
#  host PCM_P --B0--> volume(0P) --B1--+
#                                      |--ll mixer(M) --B2--> volume(LL) ---B3-->  sink DAI0
#                     pipeline n+1 >---+
#                                      |
#                     pipeline n+2 >---+
#                                      |
#                     pipeline n+3 >---+  .....etc....more pipes can be mixed here
#

# Include topology builder
include(`utils.m4')
include(`buffer.m4')
include(`pcm.m4')
include(`pga.m4')
include(`mixer.m4')
include(`mixercontrol.m4')

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
	LIST(KCONTROL_CHANNEL(FL, 0, 0), KCONTROL_CHANNEL(FR, 0, 1)))

# Volume Mixer control with max value of 32
C_CONTROLMIXER(Master Playback Volume, PIPELINE_ID,
	CONTROLMIXER_OPS(volsw, 256 binds the mixer control to volume get/put handlers, 256, 256),
	CONTROLMIXER_MAX(, 32),
	false,
	CONTROLMIXER_TLV(TLV 32 steps from -90dB to +6dB for 3dB, vtlv_m90s3),
	Channel register and shift for Front Left/Right,
	LIST(`	', KCONTROL_CHANNEL(FL, 1, 0), KCONTROL_CHANNEL(FR, 1, 1)))

#
# Components and Buffers
#

# Host "Low latency Playback" PCM
# with 2 sink and 0 source periods
W_PCM_PLAYBACK(PCM_ID, Low Latency Playback, 2, 0, 2)

# "Playback Volume" has 1 sink period and 2 source periods for host ping-pong
W_PGA(0, PIPELINE_FORMAT, 1, 2, 1, LIST(`		', "PCM PCM_ID Playback Volume PIPELINE_ID"))

# "Master Playback Volume" has 1 source and 2 sink periods for DAI ping-pong
W_PGA(1, PIPELINE_FORMAT, 2, 1, 1, LIST(`		', "Master Playback Volume PIPELINE_ID"))

# Mixer 0 has 1 sink and source periods.
W_MIXER(0, PIPELINE_FORMAT, 1, 1, 1)

# Low Latency Buffers
W_BUFFER(0, COMP_BUFFER_SIZE(2,
	COMP_SAMPLE_SIZE(PIPELINE_FORMAT), PIPELINE_CHANNELS, SCHEDULE_FRAMES),
	PLATFORM_HOST_MEM_CAP)
W_BUFFER(1, COMP_BUFFER_SIZE(1,
	COMP_SAMPLE_SIZE(PIPELINE_FORMAT), PIPELINE_CHANNELS,SCHEDULE_FRAMES),
	PLATFORM_COMP_MEM_CAP)
W_BUFFER(2, COMP_BUFFER_SIZE(1,
	COMP_SAMPLE_SIZE(PIPELINE_FORMAT), PIPELINE_CHANNELS, SCHEDULE_FRAMES),
	PLATFORM_COMP_MEM_CAP)
W_BUFFER(3, COMP_BUFFER_SIZE(2,
	COMP_SAMPLE_SIZE(PIPELINE_FORMAT), PIPELINE_CHANNELS, SCHEDULE_FRAMES),
	PLATFORM_DAI_MEM_CAP)

#
# Pipeline Graph
#
#  host PCM_P --B0--> volume(0P) --B1--+
#                                      |--ll mixer(M) --B2--> volume(LL) ---B3-->  sink DAI0
#                     pipeline n+1 >---+
#                                      |
#                     pipeline n+2 >---+
#                                      |
#                     pipeline n+3 >---+  .....etc....more pipes can be mixed here
#

P_GRAPH(pipe-ll-playback-PIPELINE_ID, PIPELINE_ID,
	LIST(`		',
	`dapm(N_PCMP(PCM_ID), Low Latency Playback PCM_ID)',
	`dapm(N_BUFFER(0), N_PCMP(PCM_ID))',
	`dapm(N_PGA(0), N_BUFFER(0))',
	`dapm(N_BUFFER(1), N_PGA(0))',
	`dapm(N_MIXER(0), N_BUFFER(1))',
	`dapm(N_BUFFER(2), N_MIXER(0))',
	`dapm(N_PGA(1), N_BUFFER(2))',
	`dapm(N_BUFFER(3), N_PGA(1))'))

#
# Pipeline Source and Sinks
#
indir(`define', concat(`PIPELINE_SOURCE_', PIPELINE_ID), N_BUFFER(3))
indir(`define', concat(`PIPELINE_MIXER_', PIPELINE_ID), N_MIXER(0))
indir(`define', concat(`PIPELINE_PCM_', PIPELINE_ID), Low Latency Playback PCM_ID)

#
# PCM Configuration
#


# PCM capabilities supported by FW
PCM_CAPABILITIES(Low Latency Playback PCM_ID, `S32_LE,S24_LE,S16_LE', PCM_MIN_RATE, PCM_MAX_RATE, 2, PIPELINE_CHANNELS, 2, 16, 192, 16384, 65536, 65536)

