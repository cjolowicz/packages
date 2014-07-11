do_build() {
    [ -f $pkgbuilddir/Makefile ] || do_configure

    cd $pkgbuilddir

    make "${env[@]}" "${make_vars[@]}"
}

commands+=(build)
