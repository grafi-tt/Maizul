STDOUT.set_encoding("ASCII-8BIT")
ARGF.each_line do |l|
  bits = l.gsub(/[^01]/,"")
  print([bits].pack("B32"))
end
