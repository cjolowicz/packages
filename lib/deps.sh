do_deps() {
    for dependency in "${dependencies[@]}" ; do
        $packagedir/$dependency install
    done
}

commands+=(deps)
