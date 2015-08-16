require 'rails_helper'

RSpec.describe "insured/families/_qle_detail.html.erb" do
  before :each do
    render "insured/families/qle_detail"
  end

  it 'should have a hidden area' do
    expect(rendered).to have_selector('#qle-details.hidden')
  end
end
