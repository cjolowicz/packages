#!/bin/bash

set -e

_prog=riverside

### usage ##############################################################

_usage() {
    echo "usage: $_prog [options] [package]
Install source archives from upstream into the home directory.

options:
    -d, --deps           Install the dependencies.
    -s, --source         Retrieve the source tree.
    -c, --configure      Configure the package.
    -b, --build          Build the package.
    -t, --stage          Install the package into a staging area.
    -i, --install        Install the package.
    -S, --unsource       Remove the source tree.
    -C, --unconfigure    Remove the build tree.
    -T, --unstage        Remove the staging area.
    -I, --uninstall      Uninstall the package.
        --install-self   Install this program.
        --show           Display the package definition.
        --show-var VAR   Display a variable.
        --show-vars      Display all variables.
    -h, --help           Display this message."
}

## internal ############################################################

# The installation prefix for this program.
_prefix=$HOME/local

# The installation prefix for packages.
_installdir=$HOME/local

# The directory in which package definitions are kept.
_proglibdir=$_prefix/lib/$_prog

# The data directory for this program.
_progdatadir=$_prefix/var/$_prog

# The directory in which source trees are located.
_progsrcdir=$_progdatadir/src

# The directory in which build trees are located.
_progbuilddir=$_progdatadir/build

# The directory into which packages are staged.
_progstowdir=$_progdatadir/stow

# The externally visible variables.
_variables=(
    includedir
    libdir
    package
    pkgbuilddir
    pkgsrcdir
    pkgstowdir
    version)

## constants ###########################################################

# The directory into which header files are installed.
includedir=$_installdir/include

# The directory into which libraries are installed.
libdir=$_installdir/lib

# The name of the package.
package=

# The version of the package.
version=

# The directory in which the source tree of a package is located.
pkgsrcdir=

# The directory in which the build tree of a package is located.
pkgbuilddir=

# The directory in which the package is staged.
pkgstowdir=

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

### installation #######################################################

install_self() {
    local self=$0
    local selflibdir=$(dirname $0)/lib

    [ -d $_prefix       ] || install --mode 755 --directory $_prefix
    [ -d $_prefix/bin   ] || install --mode 755 --directory $_prefix/bin
    [ -d $_proglibdir   ] || install --mode 755 --directory $_proglibdir
    [ -d $_progdatadir  ] || install --mode 755 --directory $_progdatadir
    [ -d $_progsrcdir   ] || install --mode 755 --directory $_progsrcdir
    [ -d $_progbuilddir ] || install --mode 755 --directory $_progbuilddir
    [ -d $_progstowdir  ] || install --mode 755 --directory $_progstowdir

    install --mode 0755 $self $_prefix/bin/$_prog

    find $selflibdir -type f -print0 |
    xargs --null --no-run-if-empty \
        install --mode 0644 --target-directory $_proglibdir $file
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

_commands=()
_show_variables=()

while [ $# -gt 0 ]
do
    _option="$1"
    shift

    case $_option in
        -d | --deps)
            _commands+=(deps)
            ;;

        -s | --source)
            _commands+=(source)
            ;;

        -c | --configure)
            _commands+=(configure)
            ;;

        -b | --build)
            _commands+=(build)
            ;;

        -t | --stage)
            _commands+=(stage)
            ;;

        -i | --install)
            _commands+=(install)
            ;;

        --install-self)
            install_self
            exit
            ;;

        -S | --unsource)
            _commands+=(unsource)
            ;;

        -C | --unconfigure)
            _commands+=(unconfigure)
            ;;

        -T | --unstage)
            _commands+=(unstage)
            ;;

        -I | --uninstall)
            _commands+=(uninstall)
            ;;

        --show)
            _commands+=(show)
            ;;

        --show-vars)
            _show_variables+=("${variables[@]}")
            ;;

        --show-var)
            [ $# -gt 0 ] || missing_arg "$option"
            _show_variables+=("$1")
            shift
            ;;

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

[ ${#_commands[@]} -gt 0 ] || _commands=(show)

### package ############################################################

_packagefile=$(
    find $_proglibdir -type f -name "$_package-*" |
    sort -r | head -n1)

[ -f "$_packagefile" ] || _error "package '$_package' not found"

_pkgver=$(basename $_packagefile)

package=${_pkgver%%-*}
version=${_pkgver#*-}

pkgsrcdir=$_progsrcdir/$package-$version
pkgbuilddir=$_progbuilddir/$package-$version
pkgstowdir=$_progstowdir/$package-$version

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
configure_opts+=(--prefix $pkgstowdir)
cmake_opts+=(-DCMAKE_INSTALL_PREFIX=$pkgstowdir)

[ ${#cppflags[@]} -eq 0 ] || configure_env+=("CPPFLAGS=${cppflags[*]}")
[ ${#cflags[@]}   -eq 0 ] || configure_env+=("CFLAGS=${cflags[*]}")
[ ${#cxxflags[@]} -eq 0 ] || configure_env+=("CXXFLAGS=${cxxflags[*]}")
[ ${#ldflags[@]}  -eq 0 ] || configure_env+=("LDFLAGS=${ldflags[*]}")

configure_env+=(PKG_CONFIG_PATH=$libdir/pkgconfig)

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

_is_valid_variable() {
    local variable=
    for variable in ${_variables[@]} ; do
        if [ "$1" = $variable ] ; then
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
        _list_archive "$file" 2>/dev/null | head -n1 | cut -d/ -f1
    done
}

_get_source() {
    local url="$1" target="$2"
    local file=$(basename $url)

    cd $_progsrcdir

    wget "${wget_opts[@]}" -O $file $url

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

_show_variables() {
    for variable in ${show_variables[@]} ; do
        is_valid_variable "$variable" || _error "invalid variable '$variable'"

        value=$(eval "echo \"$variable\"")

        echo "$variable=$value"
    done
}

## commands ############################################################

_command_deps() {
    for dependency in "${dependencies[@]}" ; do
        $0 --install $dependency
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

    mkdir -p $_progstowdir

    local dir=
    for dir in ${install_dirs[@]} ; do
        mkdir -p $pkgstowdir/$dir
    done

    cd $pkgbuilddir

    make ${install_targets[@]} "${install_vars[@]}"
}

_command_install() {
    [ -d $pkgstowdir ] || _command_stage

    rm -f $_installdir/share/info/dir

    stow --dir $_progstowdir --target $_installdir $package-$version
}

_command_unsource() {
    if [ -d $pkgbuilddir ] ; then
        _command_unconfigure

        rm -rf $pkgsrcdir
    fi
}

_command_unconfigure() {
    rm -rf $pkgbuilddir
}

_command_unstage() {
    if [ -d $pkgstowdir ] ; then
        _command_uninstall

        rm -rf $pkgstowdir
    fi
}

_command_uninstall() {
    cd $_progstowdir

    stow -D $package-$version
}

_command_show() {
    cat $_packagefile
}

## main ################################################################

show_variables

for command in "${_commands[@]}" ; do
    _command_$command
done
