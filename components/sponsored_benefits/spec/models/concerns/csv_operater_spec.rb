require 'rails_helper'

class CsvOperaterTest
  include CsvOperater
end

describe CsvOperater do 
  it "convert two demension array from mxn to nxm" do 
    arry = [[1, 2, 3], [4, 5, 6]]
    expect(CsvOperaterTest.convert_csv(arry)).to eq [[1, 4], [2, 5], [3, 6]]
  end 
end
