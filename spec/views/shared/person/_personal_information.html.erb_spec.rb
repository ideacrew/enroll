require 'rails_helper'

describe "shared/person/_personal_information.html.erb" do
  let(:person) { FactoryBot.build(:person) }

  before :each do
    helper = Object.new.extend ActionView::Helpers::FormHelper
    helper.extend ActionDispatch::Routing::PolymorphicRoutes
    helper.extend ActionView::Helpers::FormOptionsHelper
    mock_form = ActionView::Helpers::FormBuilder.new(:person, person, helper, {})
    render "shared/person/personal_information", :f => mock_form
  end

  it "should have a hidden input field" do
    expect(rendered).to have_selector('input[type="hidden"]', visible: false)
  end

  it "should have a required input field" do
    expect(rendered).to have_selector('input[required="required"]', count: 6)
  end

  it "should have required input fields with asterisk" do
    expect(rendered).to have_selector('input[placeholder="FIRST NAME *"]')
    expect(rendered).to have_selector('input[placeholder="LAST NAME *"]')
    expect(rendered).to have_selector('input[placeholder="DATE OF BIRTH *"]')
    expect(rendered).to have_selector('input[placeholder="SOCIAL SECURITY *"]')
  end
end
