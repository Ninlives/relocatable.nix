#!/bin/sh
DIR="$(realpath "${PWD}")/"
ROOT_LINK='root'
#VAR_PLACEHOLDER
HASH_LEN=32

usage(){
    echo "Usage: $0 [OPTION...]"
    echo "Available Options:"
    echo "    -d    The target directory. DEFAULT: current working directory."
    echo "    -r    The name of the symbol link to the root store path. DEFAULT: root."
    echo "    -h    Show this message."
    exit 0
}

ensure_capacity(){
    DIR_LEN=${#DIR}
    if test $DIR_LEN -gt $MAX_PATH_LEN;then
        echo "Cannot deploy to path with more than ${MAX_PATH_LEN} characters."
        exit 1
    fi
}

ensure_exe(){
    if ! type "$1" > /dev/null;then
        "$1 is required by this script."
        exit 1
    fi
}

construct_sed_patterns(){
    if test $DIR_LEN -gt $STORE_LEN;then
        prefix_num=$(( $DIR_LEN - $STORE_LEN ))
        remain_num=$(( $HASH_LEN - $prefix_num ))
        replace_sed="s#\(${STORE}[0-9a-z]\{${prefix_num}\}\)\([0-9a-z]\{${remain_num}\}\)-#${DIR}\2-#g"
        transform_sed="s#${RSTORE}[0-9a-z]\{${prefix_num}\}##g"
    else
        prefix_num=$(( $STORE_LEN - $DIR_LEN ))
        prefix=$(printf '%*s' "${prefix_num}"|tr ' ' 'e')
        replace_sed="s#\(${STORE}\)\([0-9a-z]\{${HASH_LEN}\}\)-#${DIR}${prefix}\2-#g"
        transform_sed="s#${RSTORE}\([0-9a-z]\{${HASH_LEN}\}\)#${prefix}\1#g"
    fi
}

unpack_data(){
    cat << % |
#DATA_PLACEHOLDER
%
    base64 -d|gzip -d|sed "${replace_sed}"|tar x --transform="${transform_sed}" --directory="${DIR}"
    link_src=$(echo "${ROOT_PATH}"|sed "${transform_sed}")
    ln -s "${DIR}${link_src}" "${DIR}${ROOT_LINK}"
}

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

ensure_capacity
ensure_exe cat
ensure_exe base64
ensure_exe gzip
ensure_exe sed
ensure_exe tar
ensure_exe ln
construct_sed_patterns
unpack_data
