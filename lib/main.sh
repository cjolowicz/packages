set -e

prog=$(basename $0)
progdir=$(dirname $0)
proglibdir=$progdir/lib

. $proglibdir/common.sh
. $proglibdir/deps.sh
. $proglibdir/source.sh
. $proglibdir/configure.sh
. $proglibdir/build.sh
. $proglibdir/stage.sh
. $proglibdir/install.sh
. $proglibdir/unconfigure.sh
. $proglibdir/unstage.sh
. $proglibdir/uninstall.sh

_help() {
    printf '%s [' $prog
    for command in ${commands[@]} ; do
        printf '%s|' $command
    done | sed 's/.$/]../'
    printf '\n'
}

_dispatch() {
    for command in ${commands[@]} ; do
        case $1 in
            $command)
                do_$command
                return $?
                ;;
        esac
    done

    _help >&2
    exit 1
}

_main() {
    [ $# -gt 0 ] || _help

    for arg ; do
        _dispatch $arg || status=$?
    done

    return $status
}

_main "$@"
