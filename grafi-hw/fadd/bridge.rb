require 'serialport'

sio = SerialPort.new("/dev/ttyUSB0", 115200, 8, 1, 0)

INSTS = {
  fadd: {
    op: 0x53,
    in: [4, 4],
    out: [4]
  }
}

while line = gets
  tokens = *line.split(' ')
  next unless (tokens.length >= 2)

  radix = tokens[0].to_i
  inst = tokens[1].to_sym
  args = tokens[2..-1].map{|t|t.to_i(radix)}

  spec = INSTS[inst]
  next unless spec

  sio.putc spec[:op]

  args.zip(spec[:in]) do |a, s|
    (s-1).downto(0) do |i|
      sio.putc a>>i*8 & 0xFF
    end
  end

  spec[:out].each do |n|
    val = sio.read(n).bytes.inject(0){|x,b|x<<8|b}
    str = radix==2 ? "%0#{8*n}b" % val : radix==16 ? "%0#{2*n}x" % val : val.to_s(radix)
    puts str
  end
end
