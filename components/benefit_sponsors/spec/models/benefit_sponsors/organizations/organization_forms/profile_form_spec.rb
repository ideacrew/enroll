require 'rails_helper'

module BenefitSponsors

  RSpec.describe Organizations::OrganizationForms::ProfileForm, type: :model, dbclean: :after_each do

    subject { BenefitSponsors::Organizations::OrganizationForms::ProfileForm }
    let(:model_attributes) { [:id, :market_kind, :is_benefit_sponsorship_eligible,:corporate_npn,:languages_spoken,:working_hours,:accept_new_clients,:home_page,:contact_method,:market_kind_options,:grouped_sic_code_options,:language_options,:contact_method_options,:profile_type,:sic_code,:inbox,:parent,:office_locations] }

    describe "profile form" do

      context "model attributes" do
        it "should have all the attributes" do
          model_attributes.each do |key|
            expect(subject.new.attributes.has_key?(key)).to be_truthy
          end
        end

        it 'instantiates a new Profile Form' do
          expect(subject.new).to be_an_instance_of(BenefitSponsors::Organizations::OrganizationForms::ProfileForm)
        end
      end

      context "profile_type == benefit_sponsor" do

        let!(:params) {
          {
              profile_type: 'benefit_sponsor',
              market_kind: "shop"
          }
        }
        
        it "new form should be valid" do
          new_form = subject.new params
          new_form.validate
          expect(new_form).to be_valid
        end

        it ".is_employer_profile?" do
          new_form = subject.new params
          expect(new_form.is_employer_profile?).to eq true
        end

        it ".is_broker_profile??" do
          new_form = subject.new params
          expect(new_form.is_broker_profile?).to eq false
        end
      end

      context "profile_type == broker_agency" do

        let!(:params) {
          {
              profile_type: 'broker_agency',
              market_kind: "shop"
          }
        }

        it "new form should be valid" do
          new_form = subject.new params
          new_form.validate
          expect(new_form).to be_valid
        end

        it "new form should not be valid with out market_kind" do
          new_form = subject.new params.except!(:market_kind)
          new_form.validate
          expect(new_form).to_not be_valid
        end

        it ".is_employer_profile?" do
          new_form = subject.new params
          expect(new_form.is_employer_profile?).to eq false
        end

        it ".is_broker_profile??" do
          new_form = subject.new params
          expect(new_form.is_broker_profile?).to eq true
        end
      end
    end
  end
end