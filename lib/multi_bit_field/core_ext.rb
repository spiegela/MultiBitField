Range.class_eval do
  def <=> other
    max <=> other.max
  end

  def + other
    first, second = [self, other].sort
    first.min .. second.max
  end
  
  def invert new_start=0
    (new_start - last)..(new_start - first)
  end
  
  def to_bits
    self.sum{|i| 2 ** i}
  end
end