# frozen_string_literal: true

require "rails_helper"

# module Operations for class CreateDocumentAndNotifyRecipient
# rubocop:disable Metrics/ModuleLength
module Operations
  RSpec.describe Fdsh::Vlp::H92::InitialResponseProcessor do

    let(:person) {FactoryBot.create(:person, :with_consumer_role)}

    let(:response_payload) do
      {
        :ResponseMetadata => {:ResponseCode => "HS000000", :ResponseDescriptionText => "Successful."},
        :InitialVerificationResponseSet => {
          :InitialVerificationIndividualResponses => [
            { :ResponseMetadata => {:ResponseCode => "HS000000", :ResponseDescriptionText => "Successful."},
              :ArrayOfErrorResponseMetadata => nil,
              :LawfulPresenceVerifiedCode => "Y",
              :InitialVerificationIndividualResponseSet => {
                :CaseNumber => "6000060033064OC", :NonCitLastName => "Benstce",
                :NonCitFirstName => "Jamison", :NonCitMiddleName => nil,
                :NonCitBirthDate => Date.new(1993, 10, 21), :NonCitEntryDate => nil,
                :AdmittedToDate => nil, :AdmittedToText => nil, :NonCitCountryBirthCd => "IND",
                :NonCitCountryCitCd => nil, :NonCitCoaCode => nil, :NonCitProvOfLaw => "A02",
                :NonCitEadsExpireDate => Date.new(2025, 10, 21), :EligStatementCd => 10,
                :EligStatementTxt => "TEMPORARY EMPLOYMENT AUTHORIZED", :IAVTypeCode => nil,
                :IAVTypeTxt => nil, :WebServSftwrVer => "37", :GrantDate => nil,
                :GrantDateReasonCd => "Not Applicable", :SponsorDataFoundIndicator => false,
                :ArrayOfSponsorshipData => nil, :SponsorshipReasonCd => nil,
                :AgencyAction => "Invoke CloseCase Web method to close the case.",
                :FiveYearBarApplyCode => "X", :QualifiedNonCitizenCode => "N",
                :FiveYearBarMetCode => "X", :USCitizenCode => "X"
              }}
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
      described_class.new.call({person_hbx_id: person.hbx_id, response: response.to_h})
    end

    it "should pass" do
      expect(subject).to be_success
    end

    it "consumer_role should be valid" do
      subject
      expect(person.reload.consumer_role.vlp_authority).to eq 'dhs'
      expect(person.consumer_role.valid?).to be_truthy
    end

    context 'for five_year_bar' do
      let(:response_payload) do
        {
          :ResponseMetadata => { :ResponseCode => "HS000000",:ResponseDescriptionText => "Successful." },
          :InitialVerificationResponseSet => {
            :InitialVerificationIndividualResponses => [{
              :ResponseMetadata => { :ResponseCode => "HS000000",:ResponseDescriptionText => "Successful." },
              :ArrayOfErrorResponseMetadata => nil,
              :LawfulPresenceVerifiedCode => "Y",
              :InitialVerificationIndividualResponseSet => {
                :CaseNumber => "0022131163250PV", :NonCitLastName => "LastName", :NonCitFirstName => "FirstName",
                :NonCitMiddleName => nil, :NonCitBirthDate => TimeKeeper.date_of_record, :NonCitEntryDate => TimeKeeper.date_of_record,
                :AdmittedToDate => TimeKeeper.date_of_record, :AdmittedToText => nil, :NonCitCountryBirthCd => nil,
                :NonCitCountryCitCd => nil, :NonCitCoaCode => "H2B", :NonCitProvOfLaw => nil,
                :NonCitEadsExpireDate => nil, :EligStatementCd => 128, :EligStatementTxt => "NON IMMIGRANT - TEMPORARY EMPLOYMENT  AUTHORIZED",
                :IAVTypeCode => nil, :IAVTypeTxt => nil, :WebServSftwrVer => "37", :GrantDate => nil, :GrantDateReasonCd => "Not Applicable",
                :SponsorDataFoundIndicator => nil, :ArrayOfSponsorshipData => nil, :SponsorshipReasonCd => nil, :AgencyAction => "Invoke CloseCase Web method to close the case.",
                :FiveYearBarApplyCode => five_year_bar_code, :QualifiedNonCitizenCode => "N", :FiveYearBarMetCode => five_year_bar_code, :USCitizenCode => "X"
              }
            }]
          }
        }
      end

      context 'for values to be X' do
        let(:five_year_bar_code) { 'X' }

        it 'should set values to false' do
          expect(subject.success.five_year_bar_applies).to eq(false)
          expect(subject.success.five_year_bar_met).to eq(false)
        end
      end

      context 'with five_year_bar data as N' do
        let(:five_year_bar_code) { 'N' }

        it 'should set values to true' do
          expect(subject.success.five_year_bar_applies).to eq(false)
          expect(subject.success.five_year_bar_met).to eq(false)
        end
      end

      context 'with five_year_bar data as P' do
        let(:five_year_bar_code) { 'P' }

        it 'should set values to true' do
          expect(subject.success.five_year_bar_applies).to eq(true)
          expect(subject.success.five_year_bar_met).to eq(true)
        end
      end

      context 'with five_year_bar data as nil' do
        let(:five_year_bar_code) { nil }

        it 'should set values to true' do
          expect(subject.success.five_year_bar_applies).to eq(true)
          expect(subject.success.five_year_bar_met).to eq(true)
        end
      end

      context 'with five_year_bar data as Y' do
        let(:five_year_bar_code) { 'Y' }

        it 'should set values to true' do
          expect(subject.success.five_year_bar_applies).to eq(true)
          expect(subject.success.five_year_bar_met).to eq(true)
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
