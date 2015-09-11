require 'rails_helper'

RSpec.describe "insured/families/_qle_detail.html.erb" do
  before :each do
    render "insured/families/qle_detail"
  end

  it 'should have a hidden area' do
    expect(rendered).to have_selector('#qle-details.hidden')
  end

  it "should have error message" do
    expect(rendered).to have_content "The date you submitted does not qualify for special enrollment."
    expect(rendered).to have_content "Please double check the date or contact DC Health Link's Customer Care Center: 1-855-532-5465."
  end

  it "should have csr alert message" do
    expect(rendered).to have_content "Based on the information you entered, you may be eligible for a special enrollment period. Please call us at 1-855-532-5465 to give us more information so we can see if you qualify."
  end

  it "should have csr-form" do
    expect(rendered).to have_selector('.csr-form.hidden')
  end
end
