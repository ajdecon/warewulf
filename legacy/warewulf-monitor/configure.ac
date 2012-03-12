AC_PREREQ(2.59)
AC_INIT(warewulf-monitor-legacy, 2.9.90, warewulf@lbl.gov)
AC_CONFIG_SRCDIR([.])

AC_PROG_INSTALL
AM_INIT_AUTOMAKE
AC_PROG_CC

AC_PATH_PROG(PERLBIN, perl)
if test -z "$PERLBIN"; then
   AC_MSG_ERROR([perl not found])
fi
AC_SUBST(PERLBIN)

dnl# Try to get SVN revision
SVNVERSION=`svnversion -c | sed 's/^.*://g' 2>/dev/null || echo 0000`
if test "$SVNVERSION" = "0000" ; then
    SVNVERSION=`svnversion 2>/dev/null || echo 0000`
fi
AC_SUBST(SVNVERSION)

AC_OUTPUT([
   Makefile
   warewulf-monitor-legacy.spec
   scripts/lib/Warewulf/Makefile
   scripts/lib/Makefile
   scripts/bin/Makefile
   scripts/bin/wwnodes
   scripts/bin/wwmpirun
   scripts/bin/wwstats
   scripts/bin/wwsummary
   scripts/bin/wwtop
   scripts/sbin/warewulfd
   scripts/sbin/Makefile
   scripts/share/Makefile
   scripts/share/web/Makefile
   scripts/init/Makefile
   scripts/init/warewulf
   scripts/init/wwproxy
   scripts/init/wulfd
   etc/Makefile
   scripts/Makefile
   src/Makefile
])
