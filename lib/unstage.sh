do_unstage() {
    if [ -d $pkginstalldir ] ; then
        do_uninstall

        rm -rf $pkginstalldir
    fi
}

commands+=(unstage)
