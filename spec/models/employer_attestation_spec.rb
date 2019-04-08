require 'rails_helper'

# This model always should be point to old model Please do not update this spec to new model

describe EmployerAttestation, dbclean: :after_each do

  context ".deny" do
    let!(:organization) { FactoryBot.create :employer }
    let(:employer_attestation) { organization.employer_profile.employer_attestation}

    describe "Happy Path" do

      it "should initialize as un-submitted" do
        expect(employer_attestation.aasm_state).to eq "unsubmitted"
      end

      context "and document is uploaded" do
        before do
          employer_attestation.submit!
        end

        it "should transition to :submitted state" do
          expect(employer_attestation.aasm_state).to eq "submitted"
        end

        context "and the document is approved" do
          before do
            employer_attestation.approve!
          end

          it "should transition to :accepted state" do
            expect(employer_attestation.aasm_state).to eq "approved"
          end
        end

        context "and the document is denied" do
          before do
            employer_attestation.deny!
          end

          it "should transition to :rejected state" do
            expect(employer_attestation.aasm_state).to eq "denied"
          end
        end
      end
    end


    context '.terminate_employer' do

      context 'employer with active plan year' do

        it 'should reject document and terminate plan year' do
          #TODO refactor according to benefit application
          # employer_attestation.deny!
          # expect(plan_year.aasm_state).to eq 'termination_pending'
          # expect(plan_year.end_on).to eq TimeKeeper.date_of_record.end_of_month
          # expect(plan_year.terminated_on).to eq TimeKeeper.date_of_record.end_of_month
        end
      end

      context 'employer with published plan year' do
        
        it 'should reject document and cancel plan year' do
          #TODO refactor according to benefit application
          # plan_year.update_attributes(start_on:TimeKeeper.date_of_record.beginning_of_month + 1.month, aasm_state:'enrolling')
          # employer_attestation.deny!
          # expect(plan_year.aasm_state).to eq 'canceled'
        end
      end
    end
  end

  context ".revert" do
    let(:employer_profile) { FactoryBot.create(:employer_profile)}
    let!(:employer_attestation) { FactoryBot.create(:employer_attestation,aasm_state:'denied',employer_profile:employer_profile) }
        
    it 'should revert employer_attestation from denied to unsubmitted state' do
      employer_attestation.revert!
      expect(employer_attestation.aasm_state).to eq 'unsubmitted'
    end

    it 'should revert employer_attestation from pending to unsubmitted state' do
      employer_attestation.update_attributes(aasm_state:'pending')
      employer_attestation.revert!
      expect(employer_attestation.aasm_state).to eq 'unsubmitted'
    end

    it 'should revert employer_attestation from submitted to unsubmitted state' do
      employer_attestation.update_attributes(aasm_state:'submitted')
      employer_attestation.revert!
      expect(employer_attestation.aasm_state).to eq 'unsubmitted'
    end
  end
end
