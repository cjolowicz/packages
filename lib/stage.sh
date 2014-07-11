do_stage() {
    [ -f $pkgbuilddir/Makefile ] || do_build

    mkdir -p $installdir

    cd $pkgbuilddir

    make install "${env[@]}" "${make_vars[@]}"
}

commands+=(stage)
