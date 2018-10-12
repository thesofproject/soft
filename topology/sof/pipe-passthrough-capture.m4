# Capture Passthrough Pipeline and PCM
#
# Pipeline Endpoints for connection are :-
#
#  host PCM_C <-- B0 <-- sink DAI0

# Include topology builder
include(`utils.m4')
include(`buffer.m4')
include(`pcm.m4')
include(`dai.m4')
include(`pipeline.m4')

#
# Components and Buffers
#

# Host "Passthrough Capture" PCM
# with 0 sink and 2 source periods
W_PCM_CAPTURE(PCM_ID, Passthrough Capture, 0, 2, 2)

# Capture Buffers
W_BUFFER(0, COMP_BUFFER_SIZE(2,
	COMP_SAMPLE_SIZE(PIPELINE_FORMAT), PIPELINE_CHANNELS, SCHEDULE_FRAMES),
	PLATFORM_PASS_MEM_CAP)

#
# Pipeline Graph
#
#  host PCM_C <-- B0 <-- sink DAI0

P_GRAPH(pipe-pass-capture-PIPELINE_ID, PIPELINE_ID,
	LIST(`		',
	`dapm(Passthrough Capture PCM_ID, N_PCMC(PCM_ID))',
	`dapm(N_PCMC(PCM_ID), N_BUFFER(0))'))

#
# Pipeline Source and Sinks
#
indir(`define', concat(`PIPELINE_SINK_', PIPELINE_ID), N_BUFFER(0))
indir(`define', concat(`PIPELINE_PCM_', PIPELINE_ID), Passthrough Capture PCM_ID)

#
# PCM Configuration
#

PCM_CAPABILITIES(Passthrough Capture PCM_ID, COMP_FORMAT_NAME(PIPELINE_FORMAT), PCM_MIN_RATE, PCM_MAX_RATE, 1, PIPELINE_CHANNELS, 2, 16, 192, 16384, 65536, 65536)
