require 'rails_helper'

describe EmployerAttestation, dbclean: :after_each do

  context ".submit_review" do

    let(:start_on) { TimeKeeper.date_of_record.beginning_of_month }
    let(:plan_year) { FactoryGirl.create(:plan_year,aasm_state:'active') }
    let(:employer_profile) { FactoryGirl.create(:employer_profile,plan_years:[plan_year] )}
    let!(:employer_attestation) { FactoryGirl.create(:employer_attestation,employer_profile:employer_profile) }
  
    
    context '.deny' do
      it 'should reject document and terminate plan year' do
        employer_attestation.deny!
        expect(plan_year.aasm_state).to eq 'termination_pending'
        expect(plan_year.end_on).to eq TimeKeeper.date_of_record.end_of_month
        expect(plan_year.terminated_on).to eq TimeKeeper.date_of_record.end_of_month
      end
    end
  end
end