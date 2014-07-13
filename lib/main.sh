set -e

. $(dirname $0)/lib/config.sh
. $(dirname $0)/lib/settings.sh

_help() {
    printf '%s [' $prog
    for command in ${commands[@]} ; do
        printf '%s|' $command
    done | sed 's/.$/]../'
    printf '\n'
}

_init() {
    _init_settings

    . $proglibdir/deps.sh
    . $proglibdir/source.sh
    . $proglibdir/configure.sh
    . $proglibdir/build.sh
    . $proglibdir/stage.sh
    . $proglibdir/install.sh
    . $proglibdir/unconfigure.sh
    . $proglibdir/unstage.sh
    . $proglibdir/uninstall.sh
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

main() {
    [ $# -gt 0 ] || _help

    _init

    for arg ; do
        _dispatch $arg || status=$?
    done

    return $status
}
