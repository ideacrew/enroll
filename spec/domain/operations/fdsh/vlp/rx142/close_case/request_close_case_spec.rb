# frozen_string_literal: true

require "rails_helper"

module Operations
  RSpec.describe Fdsh::Vlp::Rx142::CloseCase::RequestCloseCase do

    let(:fdsh_response) do
      {
        ResponseMetadata: {
          ResponseCode: "HS000000",
          ResponseDescriptionText: "Successful."
        },
        InitialVerificationResponseSet: {
          InitialVerificationIndividualResponses: [
            {
              ResponseMetadata: {
                ResponseCode: "HS000000",
                ResponseDescriptionText: "Successful."
              },
              ArrayOfErrorResponseMetadata: nil,
              LawfulPresenceVerifiedCode: "Y",
              InitialVerificationIndividualResponseSet: {
                CaseNumber: "6000060033064OC",
                NonCitLastName: "Benstce",
                NonCitFirstName: "Jamison",
                NonCitMiddleName: nil,
                NonCitBirthDate: Date.new(1993, 10, 21),
                NonCitEntryDate: nil,
                AdmittedToDate: nil,
                AdmittedToText: nil,
                NonCitCountryBirthCd: "IND",
                NonCitCountryCitCd: nil,
                NonCitCoaCode: nil,
                NonCitProvOfLaw: "A02",
                NonCitEadsExpireDate: Date.new(2025, 10, 21),
                EligStatementCd: 10,
                EligStatementTxt: "TEMPORARY EMPLOYMENT AUTHORIZED",
                IAVTypeCode: nil,
                IAVTypeTxt: nil,
                WebServSftwrVer: "37",
                GrantDate: nil,
                GrantDateReasonCd: "Not Applicable",
                SponsorDataFoundIndicator: false,
                ArrayOfSponsorshipData: nil,
                SponsorshipReasonCd: nil,
                AgencyAction: "Invoke CloseCase Web method to close the case.",
                FiveYearBarApplyCode: "X",
                QualifiedNonCitizenCode: "N",
                FiveYearBarMetCode: "X",
                USCitizenCode: "X"
              }
            }
          ]
        }
      }
    end

    let(:payload) do
      AcaEntities::Fdsh::Vlp::H92::InitialVerificationResponse.new(fdsh_response).to_h
    end

    context 'when valid CMS response received' do
      let(:person) { FactoryBot.create(:person, :with_consumer_role) }

      subject do
        described_class.new.call(payload, person.hbx_id)
      end

      it "should pass" do
        expect(subject).to be_success
      end
    end

    context 'when negative CMS response received' do
      context 'without an invalid hbx_id' do
        let(:hbx_id) { 0 }

        subject do
          described_class.new.call(payload, hbx_id)
        end

        it "should fail" do
          expect(subject).to be_failure
          expect(subject.failure).to eq("No person could be found with this hbx_id: #{hbx_id}")
        end
      end

      context 'without a valid case number' do
        let(:person) { FactoryBot.create(:person, :with_consumer_role) }

        before do
          individual_response = payload[:InitialVerificationResponseSet][:InitialVerificationIndividualResponses].first
          individual_response[:InitialVerificationIndividualResponseSet][:CaseNumber] = nil
        end

        subject do
          described_class.new.call(payload, person.hbx_id)
        end

        it "should fail" do
          expect(subject).to be_failure
          expect(subject.failure).to eq('No case number')
        end
      end
    end
  end
end