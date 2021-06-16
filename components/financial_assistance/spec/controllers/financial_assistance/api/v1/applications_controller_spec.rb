# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::API::V1::ApplicationsController, dbclean: :after_each, type: :controller do
  routes { FinancialAssistance::Engine.routes }

  let(:person) { FactoryBot.create(:person, :with_consumer_role)}
  let!(:user) { FactoryBot.create(:user, :person => person) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:family_id) { family.id}

  before(:each) do
    sign_in user
  end

  describe '#create' do
    context 'with valid params' do
      before do
        post :create, params: {
          application: {
            applicants_attributes: [{
              "is_ssn_applied" => "false",
              "non_ssn_apply_reason" => "we",
              "is_pregnant" => "false",
              "pregnancy_due_on" => "",
              "children_expected_count" => "",
              "is_post_partum_period" => "false",
              "pregnancy_end_on" => "09/21/2017",
              "is_former_foster_care" => "false",
              "foster_care_us_state" => "",
              "age_left_foster_care" => "",
              "is_student" => "false",
              "student_kind" => "",
              "student_status_end_on" => "",
              "student_school_kind" => "",
              "is_self_attested_blind" => "false",
              "has_daily_living_help" => "false",
              "need_help_paying_bills" => "false",
              addresses_attributes: [
                {
                  kind: 'home',
                  address_1: '55 fake st',
                  city: 'Washington',
                  state: 'DC',
                  zip: '20002'
                }
              ],
              phones_attributes: [
                {
                  kind: 'home',
                  number: '111-3333',
                  area_code: '123'
                }
              ],
              emails_attributes: [
                {
                  kind: "home",
                  address: "test@test.com",
                }
              ],
              deductions_attributes: [
                {
                  amount: "$200.00",
                  frequency_kind: "biweekly",
                  start_on: "1/1/#{TimeKeeper.datetime_of_record.year}",
                  end_on: "12/31/#{TimeKeeper.datetime_of_record.year}",
                  kind: "student_loan_interest"
                }
              ],
              incomes_attributes: [
                {
                  kind: "wages_and_salaries",
                  employer_name: "sfd",
                  amount: "50001",
                  frequency_kind: "quarterly",
                  start_on: "11/08/2017",
                  end_on: "11/08/2018",
                  employer_address: [
                    kind: "work",
                    address_1: "2nd Main St",
                    address_2: "sfdsf",
                    city: "Washington",
                    state: "DC",
                    zip: "35467"
                  ],
                  employer_phone: [
                    kind: "work", 
                    full_phone_number: "(301)-848-8053"
                  ]
                }
              ],
              benefits_attributes: [
                {
                  kind: 'is_eligible',
                  start_on: '09/04/2017',
                  end_on: '09/20/2017',
                  insurance_kind: 'child_health_insurance_plan',
                  esi_covered: 'self',
                  employer_name: '',
                  employer_id: '',
                  employee_cost: '',
                  employee_cost_frequency: ''
                }
              ]
            }],
            #format: :json
          }
        }
      end

      let(:json) { JSON.parse(response.body) }

      it 'creates the applicant' do
        expect(assigns(:application).applicants.count).to be_positive
      end

      it "creates the applicant's address" do
        expect(assigns(:application).applicants.first.addresses.count).to be_positive
      end
    end
  end
end