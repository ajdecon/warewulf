MAINTAINERCLEANFILES = Makefile.in aclocal.m4 configure compile config.* ltmain.sh depcomp install-sh missing
DISTCLEANFILES =
CLEANFILES = wwmon_aggregator.o wwmon_collector.o 

bin_PROGRAMS = aggregator collector 

AM_CXXFLAGS = $(INTI_CFLAGS)

aggregator_SOURCES = wwmon_aggregator.c globals.h
collector_SOURCES = wwmon_collector.c globals.h
aggregator_LDADD = $(INTI_LIBS)
collector_LDADD = $(INTI_LIBS)

EXTRA_DIST = util.c getstats.c
