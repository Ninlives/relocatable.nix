import sys

hash_len = 32


def get_hashes(store_paths_file, store_dir):
    hashes = []
    with open(store_paths_file) as f:
        for path in f.readlines():
            hashes.append(path[:len(store_dir) + hash_len])
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
    store_paths_file = sys.argv[1]
    store_dir = sys.argv[2]
    hashes = get_hashes(store_paths_file, store_dir)
    unique_suffix_len = get_unique_suffix_len(hashes)
    print(len(store_dir) + hash_len - unique_suffix_len, end='')


if __name__ == '__main__':
    main()
