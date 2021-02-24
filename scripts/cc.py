import opencc
import sys
import argparse
import chardet

def run():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group()
    parser.add_argument('-e','--encoding', default="zh-hans", choices=['t','cht','zh-hant','s','chs','zh-hans'],
            help='encoding: zh-Hant(t, cht) or zh-Hans(s, chs)')
    group.add_argument('-i', '--file_in' , help='input file path')
    parser.add_argument('-o', '--file_out', help='output file path')
    group.add_argument('str', nargs='*', default=[], help='String...', metavar='Some strings.')
    options= parser.parse_args()
    if any(options.encoding == i for i in ['t','cht','zh-hant']):
        options.encoding = "s2t.json"
    else:
        options.encoding = "t2s.json"
    if options.file_in:
        with open(options.file_in, "rb") as f:
            file_in = f.read()
            enc = chardet.detect(file_in)['encoding']
            in_str = file_in.decode(enc)
    else:
        in_str = ' '.join(options.str)
    if in_str:
        c = opencc.OpenCC(options.encoding)
        if options.file_out:
            with open(options.file_out, 'wb') as f:
                f.write(c.convert(in_str).encode('utf-8'))
        else:
            file_out = sys.stdout.write(c.convert(in_str))


if __name__ == '__main__':
    run()