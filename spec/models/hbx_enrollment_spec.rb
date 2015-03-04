require 'rails_helper'

describe HbxEnrollment do

  before(:all) do
    @employer = EmployerProfile.new
    @hbx_enrollment = HbxEnrollment.new
  end

  it 'sets employer_id' do
    @hbx_enrollment.employer_profile=@employer
    expect(@hbx_enrollment.employer_id).to eq(@employer.id)
  end
end