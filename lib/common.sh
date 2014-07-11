: ${prefix:=$HOME/local}
: ${packagedir:=$HOME/sources/packages}
: ${srcdir:=$HOME/sources/thirdparty}
: ${builddir:=$HOME/build/thirdparty}

: ${installdir:=$prefix/stow}
: ${libdir:=$prefix/lib}
: ${includedir:=$prefix/include}
: ${infodir:=$prefix/share/info}

: ${package:=${prog%%-*}}
: ${version:=${prog#*-}}
: ${extension:=tar.gz}
: ${file:=$package-$version.$extension}
: ${url:=$baseurl/$file}

: ${pkgsrcdir:=$srcdir/$package-$version}
: ${pkgbuilddir:=$builddir/$package-$version}
: ${pkginstalldir:=$installdir/$package-$version}

[ -n "${dependencies+x}" ] || dependencies=()
[ -n "${env+x}"		 ] || env=()
[ -n "${config+x}"	 ] || config=()
[ -n "${vars+x}"	 ] || make_vars=()
[ -n "${commands+x}"	 ] || commands=()

: ${configure_type:=autoconf}

config+=(--prefix $pkginstalldir)
