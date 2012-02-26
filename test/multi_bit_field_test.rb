require 'minitest_helper'

describe MultiBitField do
  #
  # class Person < ActiveRecord::Base
  #   has_bit_fields :birthday, 0..3 => :month, 4..8 => :day
  # end
  #
  describe "class methods" do
    subject do
      Person
    end
    
    let(:bitfields) { {:birthday => 9} }
    
    it "implements a bitfields method" do
      subject.bitfields.must_equal bitfields
    end
    
  end
  
  describe "instance methods with nil value" do
    subject do
      Person.new
    end
    
    it "has bitfield accessors" do
      subject.month.must_equal nil
      subject.day.must_equal nil
    end
  end
  
  describe "instance methods with bitfield values" do
    subject do
      Person.new :month => 2, :day => 28
    end
    
    it "has correct month value" do
      subject.month.must_equal 2
    end
    
    it "has correct day value" do
      subject.day.must_equal 28
    end
    
    #  field  month    day  all-together
    # ------  -----   ----  ------------
    # binary   010   11100      01011100
    # value     02      28            92
    it "has correct birthday value" do
      subject.birthday.must_equal 92
    end
  end
  
  describe "instance methods with raw value" do
    subject do
      Person.new :birthday => 358
    end
    
    it "has the correct month value" do
      subject.month.must_equal 11
    end
    
    it "has the correct day" do
      subject.day.must_equal 6
    end
  end
  
end