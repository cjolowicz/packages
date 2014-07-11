: ${package:=${prog%%-*}}
: ${version:=${prog#*-}}
: ${extension:=tar.gz}
: ${file:=$package-$version.$extension}
: ${url:=$baseurl/$file}

[ -n "${dependencies+x}" ] || dependencies=()
[ -n "${env+x}"		 ] || env=()
[ -n "${config+x}"	 ] || config=()
[ -n "${vars+x}"	 ] || make_vars=()
[ -n "${wget_opts+x}"	 ] || wget_opts=()

: ${configure_type:=autoconf}

prefix=$HOME/local
packagedir=$HOME/sources/packages
srcdir=$HOME/sources/thirdparty
builddir=$HOME/build/thirdparty

installdir=$prefix/stow
libdir=$prefix/lib
includedir=$prefix/include
infodir=$prefix/share/info

pkgsrcdir=$srcdir/$package-$version
pkgbuilddir=$builddir/$package-$version
pkginstalldir=$installdir/$package-$version

config+=(--prefix $pkginstalldir)

env+=(
    CPPFLAGS=-I$includedir
    LDFLAGS="-L$libdir -Wl,-rpath=$libdir")

commands=()
