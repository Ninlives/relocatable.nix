import os
import sys


def compute(file, placeholder):
    size = os.path.getsize(file)
    plen = len(placeholder)

    def ls(num):
        return len(str(num))

    guess_offset = size - plen
    update_offset = guess_offset + ls(guess_offset)
    while ls(update_offset) != ls(guess_offset):
        difference = ls(update_offset) - ls(guess_offset)
        guess_offset, update_offset = update_offset, update_offset + difference
    return update_offset


def main():
    file = sys.argv[1]
    placeholder = sys.argv[2]
    print(compute(file, placeholder))


if __name__ == '__main__':
    main()
