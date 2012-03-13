require 'minitest_helper'

describe Range do
  let(:range1) { 0..3 }
  let(:range2) { 3..5 }
  
  describe "adding ranges" do
    subject do
      [range1, range2]
    end

    it "is comparable with other ranges" do
      subject.max.must_equal range2
    end
  
    it "sums ranges" do
      subject.sum.must_equal (0..5)
    end
  
    it "sums out of order ranges" do
      subject.reverse.sum.must_equal (0..5)
    end
  end

  describe "inverting ranges" do
    subject do
      range1
    end
  
    it "inverts the range against a number" do
      subject.invert(9).must_equal (6..9)
    end
  end
end