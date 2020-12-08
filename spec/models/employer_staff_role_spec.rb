require 'rails_helper'
require_relative '../../components/benefit_sponsors/spec/concerns/observable_spec.rb'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe EmployerStaffRole, dbclean: :after_each do
  include_context 'setup benefit market with market catalogs and product packages'
  include_context 'setup initial benefit application'

  it_behaves_like 'observable'

  let(:person) { FactoryBot.create(:person) }
  let(:employer_profile) { double(id: "valid_id") }

  describe ".new" do
    let(:valid_params) do
      {
        person: person,
        employer_profile_id: employer_profile.id
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(EmployerStaffRole.new(**params).save).to be_falsey
      end
    end

     context "with valid params" do
      let(:params) { valid_params}

      it "should be valid" do
        expect(EmployerStaffRole.new(**params).valid?).to be_truthy
      end
     end

  end

  describe 'create_census_employee' do

    let!(:staff_role) {person.employer_staff_roles.create(benefit_sponsor_employer_profile_id: benefit_sponsorship.profile.id, aasm_state: "is_applicant")}

    context 'without coverage record' do
      it 'should approve poc' do
        expect(staff_role.approve!).to be_truthy
      end
    end

    context 'with coverage record' do
      it 'should approve poc' do
      end

      it 'should create census employee' do
      end
    end
  end
end
