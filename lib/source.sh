_extract_archive() {
    for file ; do
        case $file in
            *.tgz)     tar zxf "$file" ;;
            *.tar.gz)  tar zxf "$file" ;;
            *.tar.bz2) tar jxf "$file" ;;
            *.tar.xz)  tar Jxf "$file" ;;
        esac
    done
}

_list_archive() {
    for file ; do
        case $file in
            *.tgz)     tar ztf "$file" ;;
            *.tar.gz)  tar ztf "$file" ;;
            *.tar.bz2) tar jtf "$file" ;;
            *.tar.xz)  tar Jtf "$file" ;;
        esac
    done
}

_get_archive_dir() {
    for file ; do
        _list_archive "$file" | head -n1 | cut -d/ -f1
    done
}

do_source() {
    cd $srcdir

    wget "${wget_opts[@]}" -O $file $url

    _extract_archive $file

    dir=$(_get_archive_dir $file)

    [ "$dir" = $package-$version ] ||
        ln -s "$dir" $package-$version
}

commands+=(source)
