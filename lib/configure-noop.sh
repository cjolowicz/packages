do_configure() {
    [ -d $pkgsrcdir ] || do_source

    mkdir -p $builddir

    cd $builddir

    ln -sf $pkgsrcdir
}

commands+=(configure)
