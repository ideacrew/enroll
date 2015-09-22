require 'rails_helper'
require Rails.root.join("lib", "sbc", "sbc_processor")

describe SbcProcessor do

  let(:subject) {SbcProcessor.new("/Users/CitadelFirm/Downloads/MASTER 2016 QHP_QDP IVAL & SHOP Plan and Rate Matrix v.9.xlsx",
                                  "/Users/CitadelFirm/Downloads/v.2 SBCs 9.22.2015")}

  it 'should read_matrix' do
    subject.read_matrix
  end

  it 'should upload files' do
    subject.run
  end
end