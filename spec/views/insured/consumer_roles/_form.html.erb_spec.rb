require "rails_helper"
include ActionView::Context
RSpec.describe "insured/consumer_roles/_form.html.erb" do
  let(:person) { Person.new }
  let(:consumer_role) { double("ConsumerRole", id: "test")}
  let(:current_user) {FactoryGirl.create(:user)}
  before :each do
    helper = Object.new.extend ActionView::Helpers::FormHelper
    helper.extend ActionDispatch::Routing::PolymorphicRoutes
    helper.extend ActionView::Helpers::FormOptionsHelper
    mock_form = ActionView::Helpers::FormBuilder.new(:person, person, helper, {})
    stub_template "shared/_consumer_fields.html.erb" => ''
    sign_in current_user
    render partial: "insured/consumer_roles/form", locals: {f: mock_form}

  end

  it "should have title" do
    expect(rendered).to match /Enroll - let's get you signed up for healthcare/
  end

  it "should display hint for asterisks" do
    expect(rendered).to have_selector('p.memo', text: '* = required field')
  end
end
