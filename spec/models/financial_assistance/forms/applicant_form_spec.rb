# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ::FinancialAssistance::Forms::ApplicantForm, dbclean: :after_each do

  describe 'applicant_form' do
    let(:date) { TimeKeeper.date_of_record }
    let(:end_date) { date + 10.months }

    let(:deduction_params) do
      [{:id => 'deduction1',
        :kind => 'alimony_paid',
        :frequency_kind => 'quarterly',
        :amount => '100.00',
        :start_on => date,
        :end_on => end_date}]
    end

    let(:benefit_params) do
      [
       {:id => 'benefit1',
        :employer_name => 'bhhjjbhb',
        :kind => 'is_enrolled',
        :start_on => date,
        :end_on => end_date,
        :insurance_kind => 'employer_sponsored_insurance',
        :is_esi_waiting_period => true,
        :is_esi_mec_met => false,
        :esi_covered => 'self_and_spouse',
        :employee_cost => '789.00',
        :employee_cost_frequency => 'biweekly',
        :employer_id => '89-7987987',
        :employer_address =>
         {:id => 'address1',
          :kind => 'work',
          :address_1 => 'bjhbhbbhb',
          :address_2 => '',
          :city => 'jknjknjk',
          :county => nil,
          :state => 'CA',
          :zip => '87898'},
        :employer_phone => {:id => 'phone1', :full_phone_number => '8789989879'}}
      ]
    end

    let(:incomes_params) do
      [
        {
          :id => 'income1',
          :employer_name => 'dshvcghs',
          :kind => 'wages_and_salaries',
          :frequency_kind => 'half_yearly',
          :amount =>  100.00,
          :start_on => date,
          :end_on => '',
          :employer_address => {
            :id => 'address1',
            :kind => 'work',
            :address_1 => '100 d st',
            :address_2 => 'dwcs',
            :city => 'hgvghh',
            :county => nil,
            :state => 'CA',
            :zip => '72367'
          },
          :employer_phone => {:id => 'phone1', :full_phone_number => '1276312631'}
        }
      ]
    end

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
       :incomes => incomes_params,
       :benefits => benefit_params,
       :deductions => deduction_params}
    end

    before :each do
      @applicant_form = described_class.new(applicant_params)
    end

    context '.attributes' do
      it 'should respond to the attributes that are defined in the class' do
        [:id, :full_name, :age_of_the_applicant, :is_applying_coverage, :has_spouse].each do |attribute|
          expect(@applicant_form).to respond_to(attribute)
        end
      end
    end

    context '.associations' do
      it 'should match Array class for the associations' do
        [:incomes, :benefits, :deductions].each do |association|
          expect(@applicant_form.send(association).class).to eq Array
        end
      end
    end

    context '.methods' do
      it 'should return job_incomes' do
        expect(@applicant_form.job_incomes.map(&:kind)).to eq ['wages_and_salaries']
      end

      it 'should return enrolled benefits' do
        expect(@applicant_form.enrolled_benefits.map(&:kind)).to eq ['is_enrolled']
        expect(@applicant_form.eligible_benefits.map(&:kind)).to eq []
      end

      it 'should return eligible benefits' do
        applicant_params[:benefits].first[:kind] = 'is_eligible'
        @applicant_form = described_class.new(applicant_params)
        expect(@applicant_form.enrolled_benefits.map(&:kind)).to eq []
        expect(@applicant_form.eligible_benefits.map(&:kind)).to eq ['is_eligible']
      end
    end
  end
end
