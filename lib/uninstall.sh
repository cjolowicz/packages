do_uninstall() {
    cd $installdir

    stow -D $package-$version
}

commands+=(uninstall)
