# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe EmployerProfilePolicy, dbclean: :after_each do
    include_context 'setup benefit market with market catalogs and product packages'
    include_context 'setup initial benefit application'
    let(:policy) { BenefitSponsors::EmployerProfilePolicy.new(user, benefit_sponsorship.organization.profiles.first) }
    let(:person) { FactoryGirl.create(:person) }

    context 'for a user with no role' do
      let(:user) { FactoryGirl.create(:user, person: person) }

      shared_examples_for 'should not permit for person without employer staff role' do |policy_type|
        it 'should not permit' do
          expect(policy.send(policy_type)).not_to be true
        end
      end

      it_behaves_like 'should not permit for person without employer staff role', :show?
      it_behaves_like 'should not permit for person without employer staff role', :coverage_reports?
      it_behaves_like 'should not permit for person without employer staff role', :updateable?
    end

    context 'for a user without ER staff role' do
      let(:user) { FactoryGirl.create(:user, person: person) }
      let(:er_staff_role) { FactoryGirl.create(:benefit_sponsor_employer_staff_role, benefit_sponsor_employer_profile_id: benefit_sponsorship.organization.employer_profile.id) }

      shared_examples_for 'should not permit for person without active employer staff role' do |policy_type|
        it 'should not permit for inactive ER staff role' do
          er_staff_role.update_attributes(aasm_state: 'is_closed')
          person.employer_staff_roles << er_staff_role
          expect(policy.send(policy_type)).not_to be true
        end
      end

      it_behaves_like 'should not permit for person without active employer staff role', :show?
      it_behaves_like 'should not permit for person without active employer staff role', :coverage_reports?
      it_behaves_like 'should not permit for person without active employer staff role', :updateable?
    end

    context 'for a user with ER staff role' do
      let(:user) { FactoryGirl.create(:user, person: person) }
      let(:er_staff_role) { FactoryGirl.create(:benefit_sponsor_employer_staff_role, benefit_sponsor_employer_profile_id: benefit_sponsorship.organization.employer_profile.id) }

      shared_examples_for 'should not permit for person with active employer staff role' do |policy_type|
        it 'should permit for active ER staff role' do
          person.employer_staff_roles << er_staff_role
          expect(policy.send(policy_type)).to be true
        end
      end

      it_behaves_like 'should not permit for person with active employer staff role', :show?
      it_behaves_like 'should not permit for person with active employer staff role', :coverage_reports?
      it_behaves_like 'should not permit for person with active employer staff role', :updateable?
    end
  end
end