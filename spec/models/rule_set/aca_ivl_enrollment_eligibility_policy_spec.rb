# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/enrollment')

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  describe RuleSet::AcaIvlEnrollmentEligibilityPolicy, dbclean: :after_each do
    subject { RuleSet::AcaIvlEnrollmentEligibilityPolicy.new }

    context 'apply_aptc' do
      include_context 'setup families enrollments'

      context 'for success case' do
        before :each do
          tax_household.update_attributes!(effective_starting_on: enrollment_assisted.effective_on)
          @business_policy = subject.business_policies_for(enrollment_assisted, :apply_aptc)
        end

        it 'should return true when validated' do
          expect(@business_policy.is_satisfied?(enrollment_assisted)).to be_truthy
        end

        it 'should not return any fail results' do
          expect(@business_policy.fail_results).to be_empty
        end

        it 'should return all rules in success_results' do
          expect(@business_policy.success_results.keys).to eq @business_policy.rules.map(&:name)
          expect(@business_policy.success_results.values.uniq).to eq ['validated successfully']
        end
      end

      context 'for failure cases' do
        before :each do
          @business_policy = subject.business_policies_for(enrollment_unassisted, :apply_aptc)
        end

        it 'should return true when validated' do
          expect(@business_policy.is_satisfied?(enrollment_unassisted)).to be_falsy
        end

        it 'should return fail results' do
          expect(@business_policy.fail_results.keys).to eq [:any_member_aptc_eligible]
          expect(@business_policy.fail_results.values).to eq ['None of the shopping members are eligible for APTC']
        end

        it 'should not return all keys in the success results' do
          expect(@business_policy.success_results.keys).not_to eq @business_policy.rules.map(&:name)
        end
      end

      context 'for invalid inputs' do
        it 'should return not return any business_policy when invalid data is sent' do
          @business_policy = subject.business_policies_for('bad object', :apply_aptc)
          expect(@business_policy).to be_nil
        end

        it 'should return not return any business_policy when invalid data is sent' do
          @business_policy = subject.business_policies_for(enrollment_unassisted, 'invalid_case')
          expect(@business_policy).to be_nil
        end
      end
    end

    context 'apply_csr' do
      include_context 'setup families enrollments'

      context 'for success case' do
        before :each do
          tax_household.update_attributes!(effective_starting_on: enrollment_assisted.effective_on)
          @business_policy = subject.business_policies_for(enrollment_assisted, :apply_csr)
        end

        it 'should return true when validated' do
          expect(@business_policy.is_satisfied?(enrollment_assisted)).to be_truthy
        end

        it 'should not return any fail results' do
          expect(@business_policy.fail_results).to be_empty
        end

        it 'should return all rules in success_results' do
          expect(@business_policy.success_results.keys).to eq @business_policy.rules.map(&:name)
          expect(@business_policy.success_results.values.uniq).to eq ['validated successfully']
        end
      end

      context 'for failure cases' do
        context 'tax households exists' do
          before :each do
            tax_household.update_attributes!(effective_starting_on: enrollment_assisted.effective_on)
            tax_household_member1.update_attributes!(is_ia_eligible: false, is_medicaid_chip_eligible: true)
            @business_policy = subject.business_policies_for(enrollment_assisted, :apply_csr)
          end

          it 'should return true when validated' do
            expect(@business_policy.is_satisfied?(enrollment_assisted)).to be_falsy
          end

          it 'should return fail results' do
            expect(@business_policy.fail_results.keys).to eq [:any_member_csr_ineligible]
            expect(@business_policy.fail_results.values).to eq ['One of the shopping members are ineligible for CSR']
          end

          it 'should not return all keys in the success results' do
            expect(@business_policy.success_results.keys).not_to eq @business_policy.rules.map(&:name)
          end
        end

        context 'tax households does not exists' do
          before :each do
            @business_policy = subject.business_policies_for(enrollment_unassisted, :apply_csr)
          end

          it 'should return true when validated' do
            expect(@business_policy.is_satisfied?(enrollment_unassisted)).to be_falsy
          end

          it 'should return fail results' do
            expect(@business_policy.fail_results.keys).to eq [:any_member_csr_ineligible]
            expect(@business_policy.fail_results.values).to eq ['One of the shopping members are ineligible for CSR']
          end

          it 'should not return all keys in the success results' do
            expect(@business_policy.success_results.keys).not_to eq @business_policy.rules.map(&:name)
          end
        end
      end

      context 'for invalid inputs' do
        it 'should return not return any business_policy when invalid data is sent' do
          @business_policy = subject.business_policies_for('bad object', :apply_csr)
          expect(@business_policy).to be_nil
        end

        it 'should return not return any business_policy when invalid data is sent' do
          @business_policy = subject.business_policies_for(enrollment_unassisted, 'invalid_case')
          expect(@business_policy).to be_nil
        end
      end
    end
  end
end
