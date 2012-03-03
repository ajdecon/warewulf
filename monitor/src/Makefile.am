MAINTAINERCLEANFILES = Makefile.in aclocal.m4 configure compile config.* ltmain.sh depcomp install-sh missing stamp-*
DISTCLEANFILES =
CLEANFILES = wwmon_aggregator.o wwmon_collector.o core.* *~ 

bin_PROGRAMS = aggregator collector 

AM_CXXFLAGS = $(INTI_CFLAGS)

aggregator_SOURCES = wwmon_aggregator.c util.c
collector_SOURCES = wwmon_collector.c getstats.c util.c
aggregator_LDADD = $(INTI_LIBS)
collector_LDADD = $(INTI_LIBS)

EXTRA_DIST = util.c util.h getstats.c getstats.h globals.h.in
