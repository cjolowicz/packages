do_source() {
    cd $srcdir

    wget "${wget_opts[@]}" -O $file $url

    tar zxf $file
}

commands+=(source)
