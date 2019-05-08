require 'rails_helper'

RSpec.describe "::FinancialAssistance::Factories::ConditionalFieldsLookupFactory" do
  subject do
    ::FinancialAssistance::Factories::ConditionalFieldsLookupFactory
  end

  include_examples 'submitted application with one member and one applicant'

  describe 'conditionally_displayable?' do

    describe 'is_joint_tax_filing' do
      context 'when the current person is not filing jointly' do
        before do
          @instance = subject.new('applicant', applicant1.id, :is_joint_tax_filing)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'when the current person is not filing jointly with their spouse' do
        before do
          applicant1.update_attributes!(is_required_to_file_taxes: true)
          dep_person = FactoryGirl.create(:person)
          primary_person.person_relationships.create(predecessor_id: primary_person.id, successor_id: dep_person.id, family_id: family.id, kind: 'spouse')
          @instance = subject.new('applicant', applicant1.id, :is_joint_tax_filing)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end
    end

    describe 'claimed_as_tax_dependent_by' do
      context 'where the current applicant is not claimed as tax dependent' do
        before do
          @instance = subject.new('applicant', applicant1.id, :claimed_as_tax_dependent_by)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'where the current applicant is claimed as tax dependent' do
        before do
          applicant1.update_attributes!(is_claimed_as_tax_dependent: true)
          @instance = subject.new('applicant', applicant1.id, :claimed_as_tax_dependent_by)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end
    end

    describe 'is_ssn_applied' do
      context 'where the current applicant has not applied for SSN' do
        before do
          @instance = subject.new('applicant', applicant1.id, :is_ssn_applied)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'where the current applicant has applied for SSN' do
        before do
          applicant1.update_attributes!(is_ssn_applied: true)
          @instance = subject.new('applicant', applicant1.id, :is_ssn_applied)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end
    end

    describe 'non_ssn_apply_reason' do
      context 'where the current applicant has not applied for SSN' do
        before do
          @instance = subject.new('applicant', applicant1.id, :non_ssn_apply_reason)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'where the current applicant has applied for SSN' do
        before do
          applicant1.update_attributes!(is_ssn_applied: true, non_ssn_apply_reason: 'not eligible')
          @instance = subject.new('applicant', applicant1.id, :non_ssn_apply_reason)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end
    end

    [:pregnancy_due_on, :children_expected_count].each do |attribute|
      describe attribute.to_s do
        context 'where the current applicant is not pregnant' do
          before do
            @instance = subject.new('applicant', applicant1.id, attribute)
          end

          it 'should not return true' do
            expect(@instance.conditionally_displayable?).to be_falsey
          end
        end

        context 'where the current applicant is pregnant' do
          before do
            applicant1.update_attributes!(is_pregnant: true)
            @instance = subject.new('applicant', applicant1.id, attribute)
          end

          it 'should return true' do
            expect(@instance.conditionally_displayable?).to be_truthy
          end
        end
      end
    end

    [:is_post_partum_period, :pregnancy_end_on].each do |attribute|
      describe attribute.to_s do
        context 'where the current applicant is pregnant' do
          before do
            @instance = subject.new('applicant', applicant1.id, attribute)
          end

          it 'should not return true' do
            expect(@instance.conditionally_displayable?).to be_falsey
          end
        end

        context 'where the current applicant is not pregnant' do
          before do
            applicant1.update_attributes!(is_pregnant: false)
            @instance = subject.new('applicant', applicant1.id, attribute)
          end

          it 'should return true' do
            expect(@instance.conditionally_displayable?).to be_truthy
          end
        end
      end
    end

    describe 'is_enrolled_on_medicaid' do
      context 'where the current applicant has enrolled in Medicaid' do
        before do
          @instance = subject.new('applicant', applicant1.id, :is_enrolled_on_medicaid)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'where the current applicant has not enrolled in Medicaid' do
        before do
          applicant1.update_attributes!(is_post_partum_period: true)
          @instance = subject.new('applicant', applicant1.id, :is_enrolled_on_medicaid)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end
    end

    describe 'is_former_foster_care' do
      context 'where the current applicant has enrolled in Medicaid' do
        before do
          @instance = subject.new('applicant', applicant1.id, :is_former_foster_care)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'where the current applicant has not enrolled in Medicaid' do
        before do
          primary_person.update_attributes(dob: (TimeKeeper.date_of_record - 21.years))
          @instance = subject.new('applicant', applicant1.id, :is_former_foster_care)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end
    end

    [:foster_care_us_state, :age_left_foster_care, :had_medicaid_during_foster_care].each do |attribute|
      describe attribute.to_s do
        context 'where the current applicant was in foster care' do
          before do
            @instance = subject.new('applicant', applicant1.id, attribute)
          end

          it 'should not return true' do
            expect(@instance.conditionally_displayable?).to be_falsey
          end
        end

        context 'where the current applicant has not enrolled in Medicaid' do
          before do
            applicant1.update_attributes!(is_former_foster_care: true)
            @instance = subject.new('applicant', applicant1.id, attribute)
          end

          it 'should return true' do
            expect(@instance.conditionally_displayable?).to be_truthy
          end
        end
      end
    end

    describe 'is_student' do
      context 'where the current applicant has enrolled in Medicaid' do
        before do
          @instance = subject.new('applicant', applicant1.id, :is_student)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'where the current applicant has not enrolled in Medicaid' do
        before do
          primary_person.update_attributes(dob: (TimeKeeper.date_of_record - 18.years))
          @instance = subject.new('applicant', applicant1.id, :is_student)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end
    end

    [:student_kind, :student_status_end_on, :student_school_kind].each do |attribute|
      describe attribute.to_s do
        context 'where the current applicant was in foster care' do
          before do
            @instance = subject.new('applicant', applicant1.id, attribute)
          end

          it 'should not return true' do
            expect(@instance.conditionally_displayable?).to be_falsey
          end
        end

        context 'where the current applicant has not enrolled in Medicaid' do
          before do
            applicant1.update_attributes!(is_student: true)
            @instance = subject.new('applicant', applicant1.id, attribute)
          end

          it 'should return true' do
            expect(@instance.conditionally_displayable?).to be_truthy
          end
        end
      end
    end
  end
end
