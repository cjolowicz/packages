prog=$(basename $0)
progdir=$(dirname $0)
proglibdir=$progdir/lib

package=${prog%%-*}
version=${prog#*-}

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
