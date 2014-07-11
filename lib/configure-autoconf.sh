do_configure() {
    [ -f $pkgsrcdir/configure ] || do_source

    mkdir -p $pkgbuilddir

    cd $pkgbuilddir

    $pkgsrcdir/configure "${config[@]}" "${env[@]}"
}

commands+=(configure)
