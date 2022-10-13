require 'rails_helper'

RSpec.describe "insured/families/_insurance_fields.html.erb" do
    context 'default behaviour for insurance_fields partial' do

        it "should select yes by default" do
            EnrollRegistry[:default_is_your_health_coverage_ending_no].feature.stub(:is_enabled).and_call_original
            p EnrollRegistry[:default_is_your_health_coverage_ending_no]
            render partial: "insured/families/insurance_fields"
            p rendered
            expect(rendered).to have_selector('input#reason_accept[checked=checked]')
        end

        it "should select no if feature flag is enabled" do
            EnrollRegistry[:default_is_your_health_coverage_ending_no].feature.stub(:is_enabled).and_return(true)
            render partial: "insured/families/insurance_fields"

            expect(rendered).to have_selector('input#reason_accept1[checked=checked]')
        end



    end
end