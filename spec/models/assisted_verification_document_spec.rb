require 'rails_helper'

RSpec.describe AssistedVerificationDocument, :type => :model do

  before :each do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
    allow_any_instance_of(Family).to receive(:application_applicable_year).and_return(TimeKeeper.date_of_record.year)
    assisted_verification.assisted_verification_documents << [ FactoryGirl.build(:assisted_verification_document) ]
  end

  let(:person1) {FactoryGirl.create(:person, :with_consumer_role)}
  let(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: person1) }
  let(:application) { FactoryGirl.create(:application, family: family) }
  let(:applicant) { FactoryGirl.create(:applicant, application: application) }
  let(:assisted_verification) { FactoryGirl.create(:assisted_verification, applicant: applicant) }
  let(:assisted_verification_document) { assisted_verification.assisted_verification_documents.first }

  describe "creates person with assisted_verification_documents" do
    it "creates scope for uploaded docs" do
      expect(assisted_verification.assisted_verification_documents).to exist
    end

    it "returns number of uploaded documents" do
      assisted_verification_document.identifier = "url"
      expect(assisted_verification.assisted_verification_documents.uploaded.count).to eq(1)
    end

    it "returns number of uploaded documents as Zero as we don't have any identifier" do
      assisted_verification_document.identifier = nil
      expect(assisted_verification.assisted_verification_documents.uploaded.count).to eq(0)
    end
  end
end
