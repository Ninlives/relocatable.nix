#!/bin/sh
set -e -u
SHA256SUM='#SHA256SUMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX#'
OFFSET=#OFFSET#
ROOT_PATH='#ROOT_PATH#'
STORE='#STORE#'
RSTORE='#RSTORE#'
STORE_LEN=#STORE_LEN#
MAX_PATH_LEN=#MAX_PATH_LEN#

ME=''
DIR=''
SSH_SERVER=''
SSH_OPTION=''
UPDATE=''
ROOT_LINK='root'
HASH_LEN=32

err() { echo "ERROR: $1" 1>&2; }
info(){ echo "INFO:  $1"; }

usage(){
    echo "Usage: $0 [OPTION...]"
    echo "Available Options:"
    echo "    -d    The target directory."
    echo "    -s    Set the remote ssh server for deployment."
    echo "    -o    Extra command line options passed to ssh."
    echo "    -r    The name of the symbol link to the root store path. DEFAULT: root."
    echo "    -u    Use update mode."
    echo "    -v    Verify integrity."
    echo "    -h    Show this message."
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
        err "$1 is required by this operation."
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
    if test -z "${UPDATE}";then
        extra_tar_flags='--keep-old-files'
        extra_link_flags=''
    else
        extra_tar_flags='--skip-old-files'
        extra_link_flags='-f'
    fi
    info "Unpacking data.."
    dd if="${ME}" bs=${OFFSET} skip=1 2> /dev/null|gzip -d|sed -r "${replace_sed}"|tar x \
        --xform="flags=r;${rxform_sed}x" \
        --xform="flags=s;${sxform_sed}x" \
        ${extra_tar_flags} \
        -C "${DIR}"
    link_src="${DIR}$(echo "${ROOT_PATH}"|sed -r "${rxform_sed}")"
    link_dst="${DIR}${ROOT_LINK}"
    info "Creating symbol link: ${link_dst} -> ${link_src}."
    if test -L "${link_dst}";then
        if test -z "${UPDATE}";then
            err "${link_dst} already exists."
            exit 1
        else
            chmod +w "${link_dst}"
        fi
    fi
    ln -s ${extra_link_flags} "${link_src}" "${link_dst}"
}

execute_remote(){
    exe="${DIR}/deploy"
    dd if="${ME}" 2> /dev/null|ssh ${SSH_OPTION} "${SSH_SERVER}" \
    "dd of='${exe}' && chmod +x '${exe}' && ${exe} -d '${DIR}' -r '${ROOT_LINK}' && rm '${exe}'"
    exit $?
}

execute_local(){
    DIR="$(realpath "${DIR}")/"
    ensure_dir
    info "Deploy to ${DIR}."
    unpack_data
    info "Done"
    exit 0
}

ME="$(realpath "$0")"

while getopts 'huvd:s:o:r:' opt;do
    case "${opt}" in
        d)
            DIR="${OPTARG}"
            ;;
        r)
            ROOT_LINK="${OPTARG}"
            ;;
        s)
            SSH_SERVER="${OPTARG}"
            ;;
        o)
            SSH_OPTION="${OPTARG}"
            ;;
        u)
            UPDATE=1
            ;;
        v) 
            ensure_exe dd
            ensure_exe sed
            ensure_exe sha256sum
            check_integrity
            ;;
        h)
            usage
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

if test -n "${SSH_SERVER}";then
    ensure_exe dd
    ensure_exe ssh
    info "Execute on ${SSH_SERVER}"
    execute_remote
else
    ensure_exe dd
    ensure_exe ln
    ensure_exe sed
    ensure_exe tar
    ensure_exe gzip
    execute_local
fi
exit 127
