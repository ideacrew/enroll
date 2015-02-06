require 'rails_helper'

describe HbxEnrollment do

  before(:all) do
    @employer = Employer.new
    @hbx_enrollment = HbxEnrollment.new
  end

  it 'sets employer_id' do
    @hbx_enrollment.employer=@employer
    expect(@hbx_enrollment.employer_id).to eq(@employer.id)
  end
end