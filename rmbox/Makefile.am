bin_PROGRAMS = sof-rmbox sof-logger

SOF_INCDIR = \
	-I $(top_builddir)/sof/src/include/uapi

sof_rmbox_SOURCES = \
	rmbox.c \
	rmbox_convert.c

sof_rmbox_CFLAGS = \
	${SOF_INCDIR}

sof_logger_SOURCES = \
	rmbox.c \
	logger_convert.c

sof_logger_CFLAGS = \
	-DLOGGER_FORMAT \
	${SOF_INCDIR}
