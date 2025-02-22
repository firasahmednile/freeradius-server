dnl #
dnl #  Locate the directory in which a particular file is found.
dnl #
dnl #  Usage: FR_LOCATE_DIR(MYSQLLIB_DIR, libmysqlclient.a)
dnl #
dnl #    Defines the variable MYSQLLIB_DIR to be the directory(s) in
dnl #    which the file libmysqlclient.a is to be found.
dnl #
dnl #
AC_DEFUN([FR_LOCATE_DIR],
[
dnl # If we have the program 'locate', then the problem of finding a
dnl # particular file becomes MUCH easier.
dnl #

dnl #
dnl #  No 'locate' defined, do NOT do anything.
dnl #
if test "x$LOCATE" != "x"; then
dnl #
dnl #  Root through a series of directories, looking for the given file.
dnl #
DIRS=
file=$2

for x in `${LOCATE} $file 2>/dev/null`; do
  dnl #
  dnl #  When asked for 'foo', locate will also find 'foo_bar', which we
  dnl #  don't want.  We want that EXACT filename.
  dnl #
  dnl #  We ALSO want to be able to look for files like 'mysql/mysql.h',
  dnl #  and properly match them, too.  So we try to strip off the last
  dnl #  part of the filename, using the name of the file we're looking
  dnl #  for.  If we CANNOT strip it off, then the name will be unchanged.
  dnl #
  base=`echo $x | sed "s%/${file}%%"`
  if test "x$x" = "x$base"; then
    continue;
  fi

  dir=`${DIRNAME} $x 2>/dev/null`
  dnl #
  dnl #  Exclude a number of directories.
  dnl #
  exclude=`echo ${dir} | ${GREP} /home`
  if test "x$exclude" != "x"; then
    continue
  fi

  dnl #
  dnl #  OK, we have an exact match.  Let's be sure that we only find ONE
  dnl #  matching directory.
  dnl #
  already=`echo \$$1 ${DIRS} | ${GREP} ${dir}`
  if test "x$already" = "x"; then
    DIRS="$DIRS $dir"
  fi
done
fi

dnl #
dnl #  And remember the directory in which we found the file.
dnl #
eval "$1=\"\$$1 $DIRS\""
])

dnl #
dnl #  Auto-populate smart_try_dir for includes
dnl #
AC_DEFUN([FR_SMART_PKGCONFIG_INCLUDE], [
AC_MSG_CHECKING([for pkg-config $1 include paths])
if pkg-config --exists "$1"; then
	_pkgconfig_include_path=$(pkg-config --cflags-only-I $1 | sed -e 's/-I//g')
	AC_MSG_RESULT(${_pkgconfig_include_path})
	smart_try_dir="${_pkgconfig_include_path} $2"
else
	smart_try_dir="$2"
	AC_MSG_RESULT(no)
fi
])

dnl #
dnl #  Auto-populate smart_try_dir for libs
dnl #
AC_DEFUN([FR_SMART_PKGCONFIG_LIB], [
AC_MSG_CHECKING([for pkg-config $1 linker paths])
if pkg-config --exists "$1"; then
	_pkgconfig_lib_path="$(pkg-config --libs-only-L $1 | sed -e 's/-L//g')"
	AC_MSG_RESULT(${_pkgconfig_lib_path})
	smart_try_dir="${_pkgconfig_lib_path} $2"
else
	smart_try_dir="$2"
	AC_MSG_RESULT(no)
fi
])

dnl #######################################################################
dnl #
dnl #  Look for a library in a number of places.
dnl #
dnl #  FR_SMART_CHECK_LIB(library, function)
dnl #
AC_DEFUN([FR_SMART_CHECK_LIB], [

sm_lib_safe=`echo "$1" | sed 'y%./+-%__p_%'`
sm_func_safe=`echo "$2" | sed 'y%./+-%__p_%'`

dnl #
dnl #  We pass all arguments for linker testing in CCPFLAGS as these
dnl #  will be passed to the compiler (then linker) first.
dnl #
dnl #  The linker will search through -L directories in the order they
dnl #  appear on the command line.  Unfortunately the same rules appear
dnl #  to apply to directories specified with --sysroot, so we must
dnl #  pass the user specified directory first.
dnl #
dnl #  Really we should be using LDFLAGS (-L<dir>) for this.
dnl #
old_LIBS="$LIBS"
old_CPPFLAGS="$CPPFLAGS"
smart_lib=
smart_ldflags=
smart_lib_dir=

dnl #
dnl #  Try first any user-specified directory, otherwise we may pick up
dnl #  the wrong version.
dnl #
if test "x$smart_try_dir" != "x"; then
for try in $smart_try_dir; do
  AC_MSG_CHECKING([for $2 in -l$1 in $try])
  LIBS="-l$1 $old_LIBS"
  CPPFLAGS="-L$try -Wl,-rpath,$try $old_CPPFLAGS"
  AC_LINK_IFELSE([AC_LANG_PROGRAM([[extern char $2();]], [[$2()]])],
		 [
		   smart_lib="-l$1"
		   smart_ldflags="-L$try -Wl,-rpath,$try"
		   AC_MSG_RESULT(yes)
		   break
		 ],
		 [AC_MSG_RESULT(no)])
done
LIBS="$old_LIBS"
CPPFLAGS="$old_CPPFLAGS"
fi

dnl #
dnl #  Try using the default library path
dnl #
if test "x$smart_lib" = "x"; then
AC_MSG_CHECKING([for $2 in -l$1])
LIBS="-l$1 $old_LIBS"
  AC_LINK_IFELSE([AC_LANG_PROGRAM([[extern char $2();]], [[$2()]])],
	         [
	           smart_lib="-l$1"
	           AC_MSG_RESULT(yes)
	         ],
	         [AC_MSG_RESULT(no)])
LIBS="$old_LIBS"
fi

dnl #
dnl #  Try to guess possible locations.
dnl #
if test "x$smart_lib" = "x"; then
FR_LOCATE_DIR(smart_lib_dir,[lib$1${libltdl_cv_shlibext}])
FR_LOCATE_DIR(smart_lib_dir,[lib$1.a])

for try in $smart_lib_dir /usr/local/lib /opt/lib; do
  AC_MSG_CHECKING([for $2 in -l$1 in $try])
  LIBS="-l$1 $old_LIBS"
  CPPFLAGS="-L$try -Wl,-rpath,$try $old_CPPFLAGS"
  AC_LINK_IFELSE([AC_LANG_PROGRAM([[extern char $2();]], [[$2()]])],
		 [
		   smart_lib="-l$1"
		   smart_ldflags="-L$try -Wl,-rpath,$try"
		   AC_MSG_RESULT(yes)
		   break
		 ],
		 [AC_MSG_RESULT(no)])
done
LIBS="$old_LIBS"
CPPFLAGS="$old_CPPFLAGS"
fi

dnl #
dnl #  Found it, set the appropriate variable.
dnl #
if test "x$smart_lib" != "x"; then
eval "ac_cv_lib_${sm_lib_safe}_${sm_func_safe}=yes"
LIBS="$smart_ldflags $smart_lib $old_LIBS"
SMART_LIBS="$smart_ldflags $smart_lib $SMART_LIBS"
fi
])

dnl #######################################################################
dnl #
dnl #  Look for a header file in a number of places.
dnl #
dnl #  FR_SMART_CHECK_INCLUDE(foo.h, [ #include <other.h> ])
dnl #
AC_DEFUN([FR_SMART_CHECK_INCLUDE], [

ac_safe=`echo "$1" | sed 'y%./+-%__pm%'`
old_CPPFLAGS="$CPPFLAGS"
smart_include=
dnl #  The default directories we search in (in addition to the compilers search path)
smart_include_dir="/usr/local/include /opt/include"

dnl #  Our local versions
_smart_try_dir=
_smart_include_dir=

dnl #  Add variants with the different prefixes and one with no prefix
for _prefix in $smart_prefix ""; do
for _dir in $smart_try_dir; do
  _smart_try_dir="${_smart_try_dir} ${_dir}/${_prefix}"
done

for _dir in $smart_include_dir; do
  _smart_include_dir="${_smart_include_dir} ${_dir}/${_prefix}"
done
done

dnl #
dnl #  Try any user-specified directory first otherwise we may pick up
dnl #  the wrong version.
dnl #
if test "x$_smart_try_dir" != "x"; then
for try in $_smart_try_dir; do
  AC_MSG_CHECKING([for $1 in $try])
  CPPFLAGS="-isystem $try $old_CPPFLAGS"
  AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
  		                        $2
		                        #include <$1>
		                     ]],
                                     [[
                                        int a = 1;
                                     ]]
                                     )
                    ],
		    [
		      smart_include="-isystem $try"
		      AC_MSG_RESULT(yes)
		      break
		    ],
		    [
		      smart_include=
		      AC_MSG_RESULT(no)
		    ])
done
CPPFLAGS="$old_CPPFLAGS"
fi

dnl #
dnl #  Try using the default includes (with prefixes).
dnl #
if test "x$smart_include" = "x"; then
for _prefix in $smart_prefix; do
  AC_MSG_CHECKING([for ${_prefix}/$1])

  AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
  		                        $2
		                        #include <$1>
		                     ]],
                                     [[
                                        int a = 1;
                                     ]]
                                     )
                    ],
		    [
		      smart_include="-isystem ${_prefix}/"
		      AC_MSG_RESULT(yes)
		      break
		    ],
		    [
		      smart_include=
		      AC_MSG_RESULT(no)
		    ])
done
fi

dnl #
dnl #  Try using the default includes (without prefixes).
dnl #
if test "x$smart_include" = "x"; then
  AC_MSG_CHECKING([for $1])

  AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
  		                        $2
		                        #include <$1>
		                     ]],
                                     [[
                                        int a = 1;
                                     ]]
                                     )
                    ],
		    [
		      smart_include=" "
		      AC_MSG_RESULT(yes)
		      break
		    ],
		    [
		      smart_include=
		      AC_MSG_RESULT(no)
		    ])
fi

dnl #
dnl #  Try to guess possible locations.
dnl #
if test "x$smart_include" = "x"; then

for prefix in $smart_prefix; do
  FR_LOCATE_DIR(_smart_include_dir,"${_prefix}/${1}")
done
FR_LOCATE_DIR(_smart_include_dir, $1)

for try in $_smart_include_dir; do
  AC_MSG_CHECKING([for $1 in $try])
  CPPFLAGS="-isystem $try $old_CPPFLAGS"
  AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
  		                        $2
		                        #include <$1>
		                     ]],
                                     [[
                                        int a = 1;
                                     ]]
                                     )
                    ],
		    [
		      smart_include="-isystem $try"
		      AC_MSG_RESULT(yes)
		      break
		    ],
		    [
		      smart_include=
		      AC_MSG_RESULT(no)
		    ])
done
CPPFLAGS="$old_CPPFLAGS"
fi

dnl #
dnl #  Found it, set the appropriate variable.
dnl #
if test "x$smart_include" != "x"; then
eval "ac_cv_header_$ac_safe=yes"
CPPFLAGS="$smart_include $old_CPPFLAGS"
SMART_CPPFLAGS="$smart_include $SMART_CPPFLAGS"
fi

dnl #
dnl #  Consume prefix, it's not likely to be used
dnl #  between multiple calls.
dnl #
smart_prefix=
])
