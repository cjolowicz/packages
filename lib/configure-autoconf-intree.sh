do_configure() {
    [ -f $pkgsrcdir/configure ] || do_source

    mkdir -p $builddir && cd $builddir && ln -sf $pkgsrcdir

    cd $pkgbuilddir

    $pkgsrcdir/configure "${config[@]}" "${env[@]}"
}

commands+=(configure)
