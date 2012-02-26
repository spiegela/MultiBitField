class Person < ActiveRecord::Base
  include MultiBitField
  
  has_bit_field :birthday, :month => 0..3, :day => 4..8
end
