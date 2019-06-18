# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Forms::ApplicationForm, dbclean: :after_each do

  describe 'application form' do
    let(:applicant_params) do
      {:full_name => 'ivl one',
       :age_of_the_applicant => 23,
       :gender => 'male',
       :format_citizen => 'US citizen',
       :relationship => 'self',
       :citizen_status => 'us_citizen',
       :id => 'applicant_id',
       :is_required_to_file_taxes => false,
       :is_joint_tax_filing => nil,
       :is_claimed_as_tax_dependent => false,
       :claimed_as_tax_dependent_by => nil,
       :has_job_income => true,
       :has_self_employment_income => true,
       :has_other_income => true,
       :is_active => true}
    end

    let(:application_params) do
      {:id => 'application1',
       :is_requesting_voter_registration_application_in_mail => true,
       :years_to_renew => 4,
       :parent_living_out_of_home_terms => nil,
       :application_applicable_year => 2019,
       :applicants => [applicant_params]}
    end

    before :each do
      @application_form = described_class.new(application_params)
    end

    context '.attributes' do
      it 'should respond to the attributes that are defined in the class' do
        [:is_requesting_voter_registration_application_in_mail, :years_to_renew, :application_applicable_year].each do |attribute|
          expect(@application_form).to respond_to(attribute)
        end
      end
    end

    context '.associations' do
      it 'should match Array class for the associations' do
        expect(@application_form.send(:applicants).class).to eq Array
      end
    end

    context '.methods' do
      it 'should return active_applicants' do
        expect(@application_form.active_applicants.map(&:id)).to eq ['applicant_id']
      end
    end
  end
end
