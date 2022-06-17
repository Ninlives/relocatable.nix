#!/bin/sh
set -e -u
SKIP=#SKIP_PLACEHOLDER
DIR=""
ROOT_LINK='root'
HASH_LEN=32
#VAR_PLACEHOLDER
err() { echo "ERROR: $1"; }
info(){ echo "INFO:  $1"; }

usage(){
    echo "Usage: $0 [OPTION...]"
    echo "Available Options:"
    echo "    -d    The target directory."
    echo "    -r    The name of the symbol link to the root store path. DEFAULT: root."
    echo "    -h    Show this message."
    exit 0
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
        replace_sed="s#\(${STORE}[0-9a-z]\{${prefix_num}\}\)\([0-9a-z]\{${remain_num}\}\)-#${DIR}\2-#g"
        transform_sed="s#\(${RSTORE}[0-9a-z]\{${prefix_num}\}\)\([0-9a-z]\{${remain_num}\}\)-#${DIR}\2-#g"
    else
        prefix_num=$(( $STORE_LEN - $DIR_LEN ))
        prefix=$(printf '%*s' "${prefix_num}"|tr ' ' 'e')
        replace_sed="s#\(${STORE}\)\([0-9a-z]\{${HASH_LEN}\}\)-#${DIR}${prefix}\2-#g"
        transform_sed="s#\(${RSTORE}\)\([0-9a-z]\{${HASH_LEN}\}\)-#${DIR}${prefix}\2-#g"
    fi
}

unpack_data(){
    construct_sed_patterns
    info "Unpacking data.."
    dd if="$1" bs=$2 skip=1|gzip -d|sed "${replace_sed}"|tar x --transform="${transform_sed}" --strip-components=$3 --directory="${DIR}"
    link_src=$(echo "${ROOT_PATH}"|sed "${transform_sed}")
    info "Creating symbol link: ${DIR}${ROOT_LINK} -> ${DIR}${link_src}."
    ln -s "${link_src}" "${DIR}${ROOT_LINK}"
}

ensure_exe realpath
ensure_exe head
ensure_exe wc
ensure_exe tr
ensure_exe dd
ensure_exe gzip
ensure_exe sed
ensure_exe tar
ensure_exe ln

while getopts 'hd:r:' opt;do
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

ensure_dir
info "Deploy to ${DIR}."
me="$(realpath "$0")"
offset=$(head -n ${SKIP} "${me}"|wc -c)
compoents=$(( $(echo ${DIR}|tr -d -c '/'|wc -c) - 1 ))
unpack_data "${me}" "${offset}" ${compoents}
info "Done"
exit 0
