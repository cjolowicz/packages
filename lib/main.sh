#!/bin/bash

set -e

_prog=$(basename $0)

## Constants ###########################################################

# The name of the package.
package=${_prog%%-*}

# The version of the package.
version=${_prog#*-}

# The directory where packages are installed.
prefix=$HOME/local

# The directory in which package scripts are kept.
packagedir=$HOME/sources/packages

# The directory in which source trees are located.
srcdir=$HOME/sources/thirdparty

# The directory in which build trees are located.
builddir=$HOME/build/thirdparty

# The directory into which packages are staged.
installdir=$prefix/stow

# The directory into which libraries are installed.
libdir=$prefix/lib

# The directory into which header files are installed.
includedir=$prefix/include

# The directory into which info documentation is installed.
infodir=$prefix/share/info

# The directory in which the source tree of a package is located.
pkgsrcdir=$srcdir/$package-$version

# The directory in which the build tree of a package is located.
pkgbuilddir=$builddir/$package-$version

# The directory in which the package is staged.
pkginstalldir=$installdir/$package-$version

commands=(
    # Command to install the dependencies.
    deps

    # Command to retrieve the source tree.
    source

    # Command to configure the package. Define configure_hook() for additional actions.
    configure

    # Command to build the package.
    build

    # Command to install the package into a staging area.
    stage

    # Command to install the package.
    install

    # Command to remove the build tree.
    unconfigure

    # Command to remove the staging area.
    unstage

    # Command to uninstall the package.
    uninstall)

configure_types=(
    # Configure via the autoconf-style configure script.
    autoconf

    # Configure via CMake.
    cmake

    # No configuration required.
    noop)

## Settings ############################################################

# How to configure the package, one of `autoconf', `cmake', and `noop'.
configure=autoconf

# Whether the package must be built inside the source tree.
build_in_srcdir=false

# Dependencies of the package, in the form `package-version'.
dependencies=()

# Additional sources, in the form `path=url'. The path is relative to $pkgsrcdir.
extra_sources=()

# Any patches to apply relative to $pkgsrcdir.
patches=()

# Read a patch from stdin and append it to `patches'.
define_patch() {
    patches+=("$(cat)")
}

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

# Options for wget.
wget_opts=()

# Environment variables for make, cmake, and configure.
env=()

# Targets for make install.
install_targets=(install)

# Directories to create before make install.
install_dirs=()

# Variables to pass to make install.
install_vars=()

## Main ################################################################

main() {
    [ $# -gt 0 ] || _help

    _init

    for arg ; do
        _command "$arg"
    done
}

## Commands ############################################################

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

    local type=

    for type in ${configure_types[@]} ; do
        if [ $configure = $type ] ; then
            _configure_${type//-/_}
            if _is_function configure_hook ; then
		cd $pkgbuilddir
		configure_hook
	    fi
            return
        fi
    done

    _error "invalid configure type"
}

_command_build() {
    [ -f $pkgbuilddir/Makefile ] || _command_configure

    cd $pkgbuilddir

    make "${env[@]}"
}

_command_stage() {
    [ -f $pkgbuilddir/Makefile ] || _command_build

    mkdir -p $installdir

    local dir=
    for dir in ${install_dirs[@]} ; do
        mkdir -p $pkginstalldir/$dir
    done

    cd $pkgbuilddir

    make ${install_targets[@]} "${env[@]}" "${install_vars[@]}"
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

## Functions ###########################################################

_error() {
    echo "$*" >&2
    exit 1
}

_is_function() {
    [ $(type -t "$1" 2>/dev/null) = 'function' ] || return 1
}

_help() {
    printf '%s [' $_prog
    for command in ${commands[@]} ; do
        printf '%s|' $command
    done | sed 's/.$/]../'
    printf '\n'
}

_command() {
    local command=

    for command in ${commands[@]} ; do
        if [ "$1" = $command ] ; then
            _command_$command
            return
        fi
    done

    _error "invalid command '$1'"
}

_init() {
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

    [ ${#cppflags[@]} -eq 0 ] || env+=("CPPFLAGS=${cppflags[*]}")
    [ ${#cflags[@]}   -eq 0 ] || env+=("CFLAGS=${cflags[*]}")
    [ ${#cxxflags[@]} -eq 0 ] || env+=("CXXFLAGS=${cxxflags[*]}")
    [ ${#ldflags[@]}  -eq 0 ] || env+=("LDFLAGS=${ldflags[*]}")
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

    env "${env[@]}" cmake $pkgsrcdir ${cmake_opts[@]}
}

_configure_autoconf() {
    if $build_in_srcdir ; then
        ln -sf $pkgsrcdir $pkgbuilddir
    else
        mkdir -p $pkgbuilddir
    fi

    cd $pkgbuilddir

    $pkgsrcdir/configure "${configure_opts[@]}" "${env[@]}"
}
