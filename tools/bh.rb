begin
  while (b = STDIN.readbyte)
    puts "%02x" % b
  end
rescue EOFError
end
