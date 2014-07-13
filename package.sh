#!/bin/bash

set -e

_prog=$(basename $0)

### usage ##############################################################

_usage() {
    echo "usage: $_prog [options] [package] [commands]
Install source archives from upstream into the home directory.

commands:
    deps           Install the dependencies.
    source         Retrieve the source tree.
    configure      Configure the package.
    build          Build the package.
    stage          Install the package into a staging area.
    install        Install the package.
    unconfigure    Remove the build tree.
    unstage        Remove the staging area.
    uninstall      Uninstall the package.

options:
    -h, --help    Display this message."
}

### command line #######################################################

_error() {
    echo "$_prog: $*" >&2
    exit 1
}

_bad_option() {
    echo "$_prog: unrecognized option \`$1'" >&2
    echo "Try \`$_prog --help' for more information." >&2
    exit 1
}

_missing_arg() {
    echo "$_prog: $1 expected" >&2
    echo "Try \`$_prog --help' for more information." >&2
    exit 1
}

_is_valid_command() {
    local available=(
        deps
        source
        configure
        build
        stage
        install
        unconfigure
        unstage
        uninstall)

    local command=
    for command in ${available[@]} ; do
        if [ "$1" = $command ] ; then
            return
        fi
    done

    return 1
}

while [ $# -gt 0 ]
do
    _option="$1"
    shift

    case $_option in
	-h | --help)
	    _usage
	    exit
	    ;;

	--)
	    break
	    ;;

	-*)
	    _bad_option $_option
	    ;;

	*)
	    set -- "$_option" "$@"
	    break
	    ;;
    esac
done

[ $# -gt 0 ] || _missing_arg package

_package="$1"
shift

[ $# -gt 0 ] || _missing_arg command

_commands=()
while [ $# -gt 0 ] ; do
    _is_valid_command "$1" || _error "invalid command '$1'"
    _commands+=("$1")
    shift
done

## constants ###########################################################

# The name of the package.
package=

# The version of the package.
version=

# The directory where packages are installed.
prefix=$HOME/local

# The directory in which package definitions are kept.
packagedir=$HOME/sources/packages/lib

# The directory in which source trees are located.
srcdir=$HOME/sources/thirdparty

# The directory in which build trees are located.
builddir=$HOME/build/thirdparty

# The directory into which packages are staged.
installdir=$prefix/stow

# The directory in which the source tree of a package is located.
pkgsrcdir=

# The directory in which the build tree of a package is located.
pkgbuilddir=

# The directory in which the package is staged.
pkginstalldir=

# The directory into which configuration files are installed.
confdir=$prefix/etc

# The directory into which libraries are installed.
libdir=$prefix/lib

# The directory into which header files are installed.
includedir=$prefix/include

# The directory into which info documentation is installed.
infodir=$prefix/share/info

## defaults ############################################################

# How to configure the package, one of `autoconf', `cmake', and
# `noop'. Define configure_hook() to perform additional actions.
configure=autoconf

# Whether the package must be built inside the source tree.
build_in_srcdir=false

# Dependencies of the package, in the form `package-version'.
dependencies=()

# Additional sources, in the form `path=url'. The path is relative to $pkgsrcdir.
extra_sources=()

# Any patches to apply relative to $pkgsrcdir.
patches=()

# Flags for the C compiler.
cflags=()

# Flags for the C preprocessor.
cppflags=()

# Flags for the C++ compiler.
cxxflags=()

# Flags for the linker.
ldflags=()

# Options for the configure script.
configure_opts=()

# Options for cmake.
cmake_opts=()

# Environment variables for configure and cmake.
configure_env=()

# Options for wget.
wget_opts=()

# Targets for make install.
install_targets=(install)

# Directories to create before make install.
install_dirs=()

# Variables to pass to make install.
install_vars=()

# Read a patch from stdin and append it to `patches'.
define_patch() {
    patches+=("$(cat)")
}

### package ############################################################

_packagefile=$(
    find $packagedir -type f -name "$_package-*" |
    sort -r | head -n1)

[ -f "$_packagefile" ] || _error "package '$_package' not found"

_pkgver=$(basename $_packagefile)

package=${_pkgver%%-*}
version=${_pkgver#*-}

pkgsrcdir=$srcdir/$package-$version
pkgbuilddir=$builddir/$package-$version
pkginstalldir=$installdir/$package-$version

. $_packagefile

if [ -n "$url" ] ; then
    : ${file:=$(basename $url)}
else
    : ${file:=$package-$version.tar.gz}
    : ${url:=$baseurl/$file}
fi

[ "$file" = $(basename $url) ] ||
    _error "url and file are in conflict"

cppflags+=(-I$includedir)
ldflags+=(-L$libdir -Wl,-rpath=$libdir)
configure_opts+=(--prefix $pkginstalldir)
cmake_opts+=(-DCMAKE_INSTALL_PREFIX=$pkginstalldir)

[ ${#cppflags[@]} -eq 0 ] || configure_env+=("CPPFLAGS=${cppflags[*]}")
[ ${#cflags[@]}   -eq 0 ] || configure_env+=("CFLAGS=${cflags[*]}")
[ ${#cxxflags[@]} -eq 0 ] || configure_env+=("CXXFLAGS=${cxxflags[*]}")
[ ${#ldflags[@]}  -eq 0 ] || configure_env+=("LDFLAGS=${ldflags[*]}")

mkdir -p $srcdir
mkdir -p $builddir
mkdir -p $installdir
mkdir -p $includedir
mkdir -p $libdir

## functions ###########################################################

_is_function() {
    [ "$(type -t "$1" 2>/dev/null)" = 'function' ] || return 1
}

_is_valid_configure_type() {
    local available=(
        autoconf
        cmake
        noop)

    local type=
    for type in ${available[@]} ; do
        if [ "$1" = $type ] ; then
            return
        fi
    done

    return 1
}

_extract_archive() {
    for file ; do
        case $file in
            *.tgz)     tar zxf "$file" ;;
            *.tar.gz)  tar zxf "$file" ;;
            *.tar.bz2) tar jxf "$file" ;;
            *.tar.xz)  tar Jxf "$file" ;;
        esac
    done
}

_list_archive() {
    for file ; do
        case $file in
            *.tgz)     tar ztf "$file" ;;
            *.tar.gz)  tar ztf "$file" ;;
            *.tar.bz2) tar jtf "$file" ;;
            *.tar.xz)  tar Jtf "$file" ;;
        esac
    done
}

_get_archive_dir() {
    for file ; do
        _list_archive "$file" | head -n1 | cut -d/ -f1
    done
}

_get_source() {
    local url="$1" target="$2"
    local file=$(basename $url)

    cd $srcdir

    wget "${wget_opts[@]}" $url

    _extract_archive $file

    dir=$(_get_archive_dir $file)

    [ "$dir" = $target ] || ln -s "$dir" $target
}

_configure_noop() {
    ln -sf $pkgsrcdir $pkgbuilddir
}

_configure_cmake() {
    if $build_in_srcdir ; then
        ln -sf $pkgsrcdir $pkgbuilddir
    else
        mkdir -p $pkgbuilddir
    fi

    cd $pkgbuilddir

    env "${configure_env[@]}" cmake $pkgsrcdir ${cmake_opts[@]}
}

_configure_autoconf() {
    if $build_in_srcdir ; then
        ln -sf $pkgsrcdir $pkgbuilddir
    else
        mkdir -p $pkgbuilddir
    fi

    cd $pkgbuilddir

    $pkgsrcdir/configure "${configure_opts[@]}" "${configure_env[@]}"
}

## commands ############################################################

_command_deps() {
    for dependency in "${dependencies[@]}" ; do
        $packagedir/$dependency install
    done
}

_command_source() {
    _get_source $url $package-$version

    local arg=
    for arg in ${extra_sources[@]} ; do
        _get_source ${arg#*=} $pkgsrcdir/${arg%%=*}
    done

    for patch in "${patches[@]}" ; do
        patch -p1 -d $pkgsrcdir <<<"$patch"
    done
}

_command_configure() {
    [ -d $pkgsrcdir ] || _command_source

    _is_valid_configure_type "$configure" ||
        _error "invalid configure type"

    _configure_$configure

    if _is_function configure_hook ; then
        cd $pkgbuilddir
        configure_hook
    fi
}

_command_build() {
    [ -f $pkgbuilddir/Makefile ] || _command_configure

    cd $pkgbuilddir

    make
}

_command_stage() {
    [ -f $pkgbuilddir/Makefile ] || _command_build

    mkdir -p $installdir

    local dir=
    for dir in ${install_dirs[@]} ; do
        mkdir -p $pkginstalldir/$dir
    done

    cd $pkgbuilddir

    make ${install_targets[@]} "${install_vars[@]}"
}

_command_install() {
    [ -d $pkginstalldir ] || _command_stage

    rm -f $infodir/dir

    cd $installdir

    stow $package-$version
}

_command_unconfigure() {
    rm -rf $pkgbuilddir
}

_command_unstage() {
    if [ -d $pkginstalldir ] ; then
        _command_uninstall

        rm -rf $pkginstalldir
    fi
}

_command_uninstall() {
    cd $installdir

    stow -D $package-$version
}

for command in "${_commands[@]}" ; do
    _command_$command
done
