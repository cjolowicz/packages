_extract_tar_gz() {
    tar zxf "$1"
}

_extract_tar_bz2() {
    tar jxf "$1"
}

_extract_tar_xz() {
    tar Jxf "$1"
}

_extract() {
    case $1 in
        *.tgz)     _extract_tar_gz  "$1" ;;
        *.tar.gz)  _extract_tar_gz  "$1" ;;
        *.tar.bz2) _extract_tar_bz2 "$1" ;;
        *.tar.xz)  _extract_tar_xz  "$1" ;;
    esac
}

do_source() {
    cd $srcdir

    wget "${wget_opts[@]}" -O $file $url

    _extract $file
}

commands+=(source)
