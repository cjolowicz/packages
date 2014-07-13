do_configure() {
    [ -f $pkgsrcdir/CMakeLists.txt ] || do_source

    mkdir -p $pkgbuilddir

    cd $pkgbuilddir

    env "${env[@]}" cmake $pkgsrcdir ${cmake_opts[@]}
}

commands+=(configure)
