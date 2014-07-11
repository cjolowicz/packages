do_source() {
    cd $srcdir

    wget -O $file $url

    tar zxf $file
}

commands+=(source)
