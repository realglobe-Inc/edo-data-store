class Integer
  def to_bytesize_format
    byte_names = %w(KB MB GB TB PB)
    byte_length = abs.to_s(2).length
    if byte_length <= 10
      "#{self} bytes"
    else
      exponent = [byte_names.length, (byte_length - 1) / 10].min
      sprintf("%0.2f%s", self.to_f / (2 ** (10 * exponent)), byte_names[exponent - 1])
    end
  end
end
