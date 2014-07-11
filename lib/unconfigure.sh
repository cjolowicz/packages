do_unconfigure() {
    rm -rf $pkgbuilddir
}

commands+=(unconfigure)
