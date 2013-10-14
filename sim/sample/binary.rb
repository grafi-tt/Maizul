ARGF.each_line do |l|
  STDOUT.set_encoding("ASCII-8BIT")
  bits = l.gsub(/[^01]/,"")
  print([bits].pack("B32"))
end
