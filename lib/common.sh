: ${package:=${prog%%-*}}
: ${version:=${prog#*-}}
: ${extension:=tar.gz}
: ${file:=$package-$version.$extension}
: ${url:=$baseurl/$file}

[ -n "${dependencies+x}" ] || dependencies=()
[ -n "${cflags+x}"       ] || cflags=()
[ -n "${cppflags+x}"     ] || cppflags=()
[ -n "${cxxflags+x}"     ] || cxxflags=()
[ -n "${ldflags+x}"      ] || ldflags=()
[ -n "${config+x}"       ] || config=()
[ -n "${vars+x}"         ] || make_vars=()
[ -n "${wget_opts+x}"    ] || wget_opts=()

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
cppflags+=(-I$includedir)
ldflags+=(-L$libdir -Wl,-rpath=$libdir)

commands=()
env=()

[ ${#cppflags[@]} -eq 0 ] || env+=("CPPFLAGS=${cppflags[*]}")
[ ${#cflags[@]}   -eq 0 ] || env+=("CFLAGS=${cflags[*]}")
[ ${#cxxflags[@]} -eq 0 ] || env+=("CXXFLAGS=${cxxflags[*]}")
[ ${#ldflags[@]}  -eq 0 ] || env+=("LDFLAGS=${ldflags[*]}")

