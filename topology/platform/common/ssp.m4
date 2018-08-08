divert(-1)

dnl SSP related macros

dnl SSP_CLOCK(clock, freq, codec_master)
define(`SSP_CLOCK',
	$1		STR($3)
	$1_freq	STR($2))


dnl SSP_TDM(slots, width, tx_mask, rx_mask)
define(`SSP_TDM',
`tdm_slots	'STR($1)
`	tdm_slot_width	'STR($2)
`	tx_slots	'STR($3)
`	rx_slots	'STR($4)
)
dnl SSP_CONFIG(format, mclk, bclk, fsync, tdm, ssp_config_data)
define(`SSP_CONFIG',
`	format		"'$1`"'
`	'$2
`	'$3
`	'$4
`	'$5
`}'
$6
)

dnl SSP_CONFIG_DATA(type, idx, valid bits, mclk_id, quirks, frame_pulse_width)
dnl mclk_id quirks frame_pulse_width are optional
define(`SSP_CONFIG_DATA',
`SectionVendorTuples."'N_DAI_CONFIG($1$2)`_tuples" {'
`	tokens "sof_ssp_tokens"'
`	tuples."word" {'
`		SOF_TKN_INTEL_SSP_SAMPLE_BITS'	STR($3)
`	}'
`	tuples."short" {'
`		SOF_TKN_INTEL_SSP_MCLK_ID'	ifelse($4, `', "0", STR($4))
`	}'
`	tuples."word" {'
`		SOF_TKN_INTEL_SSP_QUIRKS'	ifelse($5, `', "0", STR($5))
`	}'
`	tuples."short" {'
`		SOF_TKN_INTEL_SSP_FRAME_PULSE_WIDTH'	ifelse($6, `', "0", STR($6))
`	}'
`}'
`SectionData."'N_DAI_CONFIG($1$2)`_data" {'
`	tuples "'N_DAI_CONFIG($1$2)`_tuples"'
`}'
)

divert(0)dnl
