configure_type=autoconf

dependencies=()
cflags=()
cppflags=()
cxxflags=()
ldflags=()
config=()
cmake_opts=()
make_vars=()
wget_opts=()
commands=()
env=()

_init_settings() {
    if [ -n "$url" -a -z "$file" ] ; then
        file=$(basename $url)
    else
        : ${file:=$package-$version.tar.gz}
        : ${url:=$baseurl/$file}
    fi

    cppflags+=(-I$includedir)
    ldflags+=(-L$libdir -Wl,-rpath=$libdir)
    config+=(--prefix $pkginstalldir)
    cmake_opts+=(-DCMAKE_INSTALL_PREFIX=$pkginstalldir)

    [ ${#cppflags[@]} -eq 0 ] || env+=("CPPFLAGS=${cppflags[*]}")
    [ ${#cflags[@]}   -eq 0 ] || env+=("CFLAGS=${cflags[*]}")
    [ ${#cxxflags[@]} -eq 0 ] || env+=("CXXFLAGS=${cxxflags[*]}")
    [ ${#ldflags[@]}  -eq 0 ] || env+=("LDFLAGS=${ldflags[*]}")
}
