STDIN.set_encoding(Encoding::ASCII_8BIT)
bin = STDIN.read
len = bin.length / 4
putc len / 256
putc len % 256
print bin
