do_install() {
    [ -d $pkginstalldir ] || do_stage

    rm -f $infodir/dir

    cd $installdir

    stow $package-$version
}

commands+=(install)
