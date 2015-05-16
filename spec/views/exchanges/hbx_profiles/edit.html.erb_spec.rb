require 'rails_helper'

RSpec.describe "exchanges/hbx_profiles/edit", :type => :view do
  before(:each) do
    @hbx_profile = assign(:hbx_profile, HbxProfile.create!())
  end

  it "renders the edit hbx_profile form" do
    render

    assert_select "form[action=?][method=?]", hbx_profile_path(@hbx_profile), "post" do
    end
  end
end
