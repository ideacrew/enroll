require 'rails_helper'

RSpec.describe "exchanges/hbx_profiles/show", :type => :view do
  before(:each) do
    @hbx_profile = assign(:hbx_profile, HbxProfile.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
