require 'rails_helper'

RSpec.describe "exchanges/hbx_profiles/index", :type => :view do
  before(:each) do
    assign(:hbx_profiles, [
      HbxProfile.create!(),
      HbxProfile.create!()
    ])
  end

  it "renders a list of exchanges/hbx_profiles" do
    render
  end
end
