#!/bin/sh
set -e -u
SHA256SUM='#SHA256SUMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX#'
OFFSET=#OFFSET#
ROOT_PATH='#ROOT_PATH#'
STORE='#STORE#'
RSTORE='#RSTORE#'
STORE_LEN=#STORE_LEN#
MAX_PATH_LEN=#MAX_PATH_LEN#

ME=''
DIR=''
ROOT_LINK='root'
HASH_LEN=32

err() { echo "ERROR: $1" 1>&2; }
info(){ echo "INFO:  $1"; }

usage(){
    echo "Usage: $0 [OPTION...]"
    echo "Available Options:"
    echo "    -d    The target directory."
    echo "    -r    The name of the symbol link to the root store path. DEFAULT: root."
    echo "    -h    Show this message."
    echo "    -v    Check integrity."
    exit 0
}

check_integrity(){
    info 'Check integrity.'
    sum=$(dd if="${ME}" 2> /dev/null|sed "s#${SHA256SUM}##"|sha256sum)
    if test "${sum}" = "${SHA256SUM}";then
        info 'No error detected.'
        exit 0
    else
        err 'Looks like the file is corrupted!'
        exit 1
    fi
}

realpath() {
    if test -d "$1"; then
        (cd "$1"; pwd)
    elif test -f "$1"; then
        case "$1" in
            '/'*)
                echo "$1"
                ;;
            *'/'*)
                echo "$(cd "${1%/*}"; pwd)/${1##*/}"
                ;;
            *)
                echo "$(pwd)/$1"
                ;;
        esac
    else
        err "File or directory '$1' does not exist."
        exit 1
    fi
}

ensure_dir(){
    DIR_LEN=${#DIR}
    if test $DIR_LEN -gt $MAX_PATH_LEN;then
        err "Cannot deploy to path with more than ${MAX_PATH_LEN} characters."
        exit 1
    fi
    if test ! -d "${DIR}";then
        err "${DIR} does not exist or is not a directory."
        exit 1
    fi
}

ensure_exe(){
    if ! type "$1" > /dev/null;then
        err "$1 is required by this script."
        exit 1
    fi
}

construct_sed_patterns(){
    if test $DIR_LEN -gt $STORE_LEN;then
        prefix_num=$(( $DIR_LEN - $STORE_LEN ))
        remain_num=$(( $HASH_LEN - $prefix_num ))
        replace_sed="s#(${STORE}[0-9a-z]{${prefix_num}})([0-9a-z]{${remain_num}})-#${DIR}\2-#g"
        rxform_sed="s#${RSTORE}[0-9a-z]{${prefix_num}}##"
        sxform_sed="s#(${RSTORE}[0-9a-z]{${prefix_num}})([0-9a-z]{${remain_num}})-#${DIR}\2-#"
    else
        prefix_num=$(( $STORE_LEN - $DIR_LEN ))
        prefix=$(printf '%*s' "${prefix_num}"|tr ' ' 'e')
        replace_sed="s#(${STORE})([0-9a-z]{${HASH_LEN}})-#${DIR}${prefix}\2-#g"
        rxform_sed="s#${RSTORE}([0-9a-z]{${HASH_LEN}})#${prefix}\1#"
        sxform_sed="s#(${RSTORE})([0-9a-z]{${HASH_LEN}})-#${DIR}${prefix}\2-#"
    fi
}

unpack_data(){
    construct_sed_patterns
    info "Unpacking data.."
    dd if="$1" bs=$2 skip=1|gzip -d|sed -r "${replace_sed}"|tar x \
        --xform="flags=r;${rxform_sed}x" \
        --xform="flags=s;${sxform_sed}x" \
        -C "${DIR}"
    link_src=$(echo "${ROOT_PATH}"|sed -r "${rxform_sed}")
    info "Creating symbol link: ${DIR}${ROOT_LINK} -> ${DIR}${link_src}."
    ln -s "${link_src}" "${DIR}${ROOT_LINK}"
}

ME="$(realpath "$0")"

while getopts 'hvd:r:' opt;do
    case "${opt}" in
        d)
            DIR="$(realpath "${OPTARG}")/"
            ;;
        r)
            ROOT_LINK="${OPTARG}"
            ;;
        h)
            usage
            ;;
        v) 
            ensure_exe sed
            ensure_exe sha256sum
            check_integrity
            ;;
        *)
            usage
            ;;
    esac
done

if test -z "${DIR}";then
    err 'Target directory not set. Use \`-d\` option to speficy a target directory.'
    echo
    usage
fi

ensure_exe dd
ensure_exe ln
ensure_exe sed
ensure_exe tar
ensure_exe gzip
ensure_dir

info "Deploy to ${DIR}."
unpack_data "${me}" "${OFFSET}"
info "Done"
exit 0
