# frozen_string_literal: true

require "rails_helper"

# module Operations for class CreateDocumentAndNotifyRecipient
module Operations
  RSpec.describe Fdsh::Vlp::H92::InitialResponseProcesser do

    let(:person) {FactoryBot.create(:person, :with_consumer_role)}

    let(:response_payload) do
      {
        :ResponseMetadata => {:ResponseCode=>"HS000000", :ResponseDescriptionText=>"Successful."},
        :InitialVerificationResponseSet => {
          :InitialVerificationIndividualResponses=>[
            { :ResponseMetadata=>{:ResponseCode=>"HS000000", :ResponseDescriptionText=>"Successful."},
              :ArrayOfErrorResponseMetadata=>nil,
              :LawfulPresenceVerifiedCode=>"Y",
              :InitialVerificationIndividualResponseSet=> {
                :CaseNumber=>"6000060033064OC", :NonCitLastName=>"Benstce",
                :NonCitFirstName=>"Jamison", :NonCitMiddleName=>nil,
                :NonCitBirthDate=>Date.new(1993, 10, 21), :NonCitEntryDate=>nil,
                :AdmittedToDate=>nil, :AdmittedToText=>nil, :NonCitCountryBirthCd=>"IND",
                :NonCitCountryCitCd=>nil, :NonCitCoaCode=>nil, :NonCitProvOfLaw=>"A02",
                :NonCitEadsExpireDate=>Date.new(2025, 10, 21), :EligStatementCd=>10,
                :EligStatementTxt=>"TEMPORARY EMPLOYMENT AUTHORIZED", :IAVTypeCode=>nil,
                :IAVTypeTxt=>nil, :WebServSftwrVer=>"37", :GrantDate=>nil,
                :GrantDateReasonCd=>"Not Applicable", :SponsorDataFoundIndicator=>false,
                :ArrayOfSponsorshipData=>nil, :SponsorshipReasonCd=>nil,
                :AgencyAction=>"Invoke CloseCase Web method to close the case.",
                :FiveYearBarApplyCode=>"X", :QualifiedNonCitizenCode=>"N",
                :FiveYearBarMetCode=>"X", :USCitizenCode=>"X"
              }
            }
          ]
        }
      }
    end

    let(:response) do
      AcaEntities::Fdsh::Vlp::H92::InitialVerificationResponse.new(response_payload)
    end

    before do
      person.consumer_role.update!(aasm_state: "dhs_pending")
      person.consumer_role.lawful_presence_determination.update!(citizen_status: "not_lawfully_present_in_us")
      person.consumer_role.vlp_documents << FactoryBot.build(:vlp_document, :identifier => 'identifier', :verification_type => 'Immigration type')
    end

    subject do
      described_class.new.call({person_hbx_id: person.hbx_id, response: response})
    end

    it "should pass" do
      expect(subject).to be_success
    end
  end
end
