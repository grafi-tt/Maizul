require 'serialport'
sio = SerialPort.new("/dev/ttyUSB0", 115200, 8, 1, 0)
STDOUT.sync = true
while c = sio.getbyte
  putc c
end
