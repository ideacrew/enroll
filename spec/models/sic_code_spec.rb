require 'rails_helper'

RSpec.describe SicCode, type: :model do
  subject { SicCode.new }

  it "has a valid factory" do 
    expect(create(:sic_code)).to be_valid
  end  

  it { is_expected.to validate_presence_of :code }
  it { is_expected.to validate_presence_of :industry_group }
  it { is_expected.to validate_presence_of :major_group }
  it { is_expected.to validate_presence_of :division }

end  
