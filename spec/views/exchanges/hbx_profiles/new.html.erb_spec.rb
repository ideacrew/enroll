require 'rails_helper'

RSpec.describe "exchanges/hbx_profiles/new", :type => :view do
  before(:each) do
    assign(:hbx_profile, HbxProfile.new())
  end

  it "renders new hbx_profile form" do
    render

    assert_select "form[action=?][method=?]", exchanges_hbx_profiles_path, "post" do
    end
  end
end
