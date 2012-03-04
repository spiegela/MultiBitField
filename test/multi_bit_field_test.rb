require 'minitest_helper'

describe MultiBitField do
  #
  # class Person < ActiveRecord::Base
  #   has_bit_fields :birthday, :month => 0..3, :day => 4..8
  # end
  #
  describe "class methods" do
    subject do
      Person
    end
    
    let(:bitfields) { {:birthday => 9} }
    
    it "implements a bitfield_size method" do
      subject.bitfield_size(:birthday).must_equal 9
    end
    
    it "implement reset_mask_for with single field" do
      subject.reset_mask_for(:birthday, :month).must_equal 31
    end
    
    it "implements reset_mask_for with multiple fields" do
      subject.reset_mask_for(:birthday, :month, :day).must_equal 0
    end
    
    it "implements increment_mask_for with single field" do
      subject.increment_mask_for(:birthday, :month).must_equal 32
    end
    
    it "implements increment_mask_for with multiple fields" do
      subject.increment_mask_for(:birthday, :month, :day).must_equal 33
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
  
  describe "oversized value for bitfield" do
    subject do
      lambda do
        Person.new :month => 31
      end
    end
    
    it "raises an ArgumentError" do
      subject.must_raise ArgumentError
    end
  end
  
  describe "resetting a single bitfield" do
    subject do
      Person.create :month => 12, :day => 25
    end
    
    after do
      Person.destroy_all
    end
    
    it "resets a single field to 0" do
      subject.reset_bitfield :birthday, :month
      subject.reload
      subject.month.must_equal 0
      subject.day.must_equal 25
    end
  end
  
  describe "resetting multiple bitfields" do
    subject do
      Person.create :month => 6, :day => 15
    end
    
    after do
      Person.destroy_all
    end
    
    it "resets both fields to 0" do
      subject.reset_bitfields :birthday, :month, :day
      subject.reload
      subject.month.must_equal 0
      subject.day.must_equal 0
    end
  end
  
  describe "resetting bitfields in batch" do
    before do
      Person.create :month => 6, :day => 15
      Person.create :month => 2, :day => 28
      Person.reset_bitfield :birthday, :month
    end

    after do
      Person.destroy_all
    end
    
    it "resets field in all models to 0" do
      Person.all.map(&:month).must_equal [0, 0]
    end
    
    it "keeps other field in all models at previous value" do
      Person.all.map(&:day).must_equal [15, 28]
    end
  end
  
  describe "incrementing bitfields" do
    subject do
      Person.create :month => 6, :day => 15
    end
    
    after do
      Person.destroy_all
    end
    
    it "increments both bitfields" do
      subject.increment_bitfields :birthday, :month, :day
      subject.reload
      subject.month.must_equal 7
      subject.day.must_equal 16
    end
  end
  
  describe "resetting bitfields in batch" do
    before do
      Person.create :month => 6, :day => 15
      Person.create :month => 2, :day => 28
      Person.increment_bitfield :birthday, :month
    end

    after do
      Person.destroy_all
    end
    
    it "resets field in all models to 0" do
      Person.all.map(&:month).must_equal [7, 3]
    end
    
    it "keeps other field in all models at previous value" do
      Person.all.map(&:day).must_equal [15, 28]
    end
  end
end