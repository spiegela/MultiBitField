Range.class_eval do
  def <=> other
    max <=> other.max
  end

  def + other
    first, second = [self, other].sort
    first.min .. second.max
  end
end