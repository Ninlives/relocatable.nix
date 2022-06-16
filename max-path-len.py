import os
import sys

store_dir_len = len(os.environ['storeDir'])
hash_len = 32


def get_hashes(file):
    hashes = []
    with open(file) as f:
        for path in f.readlines():
            hashes.append(path[:store_dir_len + hash_len])
    return hashes


def get_suffix(string, suffix_len):
    return string[-suffix_len:]


def get_unique_suffix_len(hashes):
    slen = 1
    for i in range(len(hashes)):
        hash_ = hashes[i]
        while get_suffix(hash_, slen) in map(lambda x: get_suffix(x, slen), hashes[:i]):
            slen += 1
            if slen == hash_len:
                return slen
    return slen


def main():
    hashes = get_hashes(sys.argv[1])
    unique_suffix_len = get_unique_suffix_len(hashes)
    print(store_dir_len + hash_len - unique_suffix_len, end='')


if __name__ == '__main__':
    main()
