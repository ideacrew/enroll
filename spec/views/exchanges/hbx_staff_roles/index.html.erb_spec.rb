require 'rails_helper'

RSpec.describe "exchanges/hbx_staff_roles/index", :type => :view do
  before(:each) do
    assign(:exchanges_hbx_staff_roles, [
      Exchanges::HbxStaffRole.create!(),
      Exchanges::HbxStaffRole.create!()
    ])
  end

  it "renders a list of exchanges/hbx_staff_roles" do
    render
  end
end
