require 'rails_helper'

RSpec.describe "insured/plan_shoppings/_individual_agreement.html.erb" do
  include TranslationSpecHelper
  let(:person) { double(first_name: 'jack', last_name: 'white') }
  let(:hbx_enrollment) do
    instance_double(
      "HbxEnrollment", id: "hbx enrollment id"
    )
  end
  context "normal message" do
    before :each do
      EnrollRegistry[:aca_individual_market].feature.stub(:is_enabled).and_return(true)
      assign(:person, person)
      assign(:hbx_enrollment, hbx_enrollment)
      render "insured/plan_shoppings/individual_agreement", locals: {aptc_present: false, coverage_year: TimeKeeper.date_of_record.year.to_s}
    end

    it "should display the title" do
      expect(rendered).to have_selector('h3', text: "Terms and Conditions")
    end

    it "should have required fields" do
      expect(rendered).to have_selector("input[placeholder='First Name *']")
      expect(rendered).to have_selector("input[placeholder='Last Name *']")
    end

    it "should have two hidden fields for first and last name" do
      expect(rendered).to have_selector("input[value='jack']", :visible => false)
      expect(rendered).to have_selector("input[value='white']", :visible => false)
    end
  end

  context "extended message" do
    before :each do
      EnrollRegistry[:aca_individual_market].feature.stub(:is_enabled).and_return(true)
      assign(:person, person)
      assign(:hbx_enrollment, hbx_enrollment)
      EnrollRegistry[:extended_aptc_individual_agreement_message].feature.stub(:is_enabled).and_return(true)
      change_target_translation_text("en.insured.individual_agreement_non_aptc", "me", "insured")
      render "insured/plan_shoppings/individual_agreement", locals: {aptc_present: true, coverage_year: TimeKeeper.date_of_record.year.to_s}
    end

    it 'should show the proper translation' do
      expect(rendered).to match("I must file a federal income tax return")
    end
  end
end
