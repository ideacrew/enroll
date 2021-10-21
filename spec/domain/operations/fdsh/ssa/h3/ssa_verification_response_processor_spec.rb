# frozen_string_literal: true

require "rails_helper"

# module Operations for class CreateDocumentAndNotifyRecipient
# rubocop:disable Metrics/ModuleLength
module Operations
  RSpec.describe Fdsh::Ssa::H3::SsaVerificationResponseProcessor do

    let(:person) {FactoryBot.create(:person, :with_consumer_role)}

    context "with maximum payload" do
      let(:response_payload) do
        {
          :SSACompositeIndividualResponses => [
            {
              :ResponseMetadata => {
                :ResponseCode => "HS000000",
                :ResponseDescriptionText => "ResponseDescriptionText0",
                :TDSResponseDescriptionText => "TDSResponseDescriptionText0"
              },
              :PersonSSNIdentification => "100101000",
              :SSAResponse => {
                :SSNVerificationIndicator => false,
                :DeathConfirmationCode => "Confirmed",
                :PersonUSCitizenIndicator => false,
                :PersonIncarcerationInformationIndicator => false,
                :SSATitleIIMonthlyIncomeInformationIndicator => false,
                :SSATitleIIAnnualIncomeInformationIndicator => false,
                :SSAQuartersOfCoverageInformationIndicator => false,
                :SSAIncarcerationInformation => {:PrisonerIdentification => "PrisonerId",
                                                 :PrisonerConfinementDate => "2006-05-04",
                                                 :ReportingPersonText => "ReportingPersonText0",
                                                 :SupervisionFacility => {
                                                   :FacilityName => "FacilityName0",
                                                   :FacilityLocation => {
                                                     :LocationStreet => "LocationStreet0",
                                                     :LocationCityName => "LocationCityName0",
                                                     :LocationStateUSPostalServiceCode => "AA",
                                                     :LocationPostalCode => "00000",
                                                     :LocationPostalExtensionCode => "0000"
                                                   },
                                                   :FacilityContactInformation => {
                                                     :PersonFullName => "PersonFullName0",
                                                     :ContactTelephoneNumber => "00000000000",
                                                     :ContactFaxNumber => "00000000000"
                                                   }, :FacilityCategoryCode => "01"
                                                 },
                                                 :InmateStatusIndicator => false},
                :SSATitleIIMonthlyIncome => {
                  :PersonDisabledIndicator => false,
                  :OngoingMonthlyBenefitCreditedAmount => 0.0,
                  :OngoingMonthlyOverpaymentDeductionAmount => 0.0,
                  :OngoingPaymentInSuspenseIndicator => false,
                  :RequestedMonthInformation => {
                    :IncomeMonthYear => "200001",
                    :BenefitCreditedAmount => 0.0,
                    :OverpaymentDeductionAmount => 0.0,
                    :PriorMonthAccrualAmount => 0.0,
                    :ReturnedCheckAmount => 0.0,
                    :PaymentInSuspenseIndicator => false
                  },
                  :RequestedMonthMinusOneInformation => {
                    :IncomeMonthYear => "200001",
                    :BenefitCreditedAmount => 0.0,
                    :OverpaymentDeductionAmount => 0.0,
                    :PriorMonthAccrualAmount => 0.0,
                    :ReturnedCheckAmount => 0.0,
                    :PaymentInSuspenseIndicator => false
                  },
                  :RequestedMonthMinusTwoInformation => {
                    :IncomeMonthYear => "200001",
                    :BenefitCreditedAmount => 0.0,
                    :OverpaymentDeductionAmount => 0.0,
                    :PriorMonthAccrualAmount => 0.0,
                    :ReturnedCheckAmount => 0.0,
                    :PaymentInSuspenseIndicator => false
                  },
                  :RequestedMonthMinusThreeInformation => {:IncomeMonthYear => "200001",
                                                           :BenefitCreditedAmount => 0.0,
                                                           :OverpaymentDeductionAmount => 0.0,
                                                           :PriorMonthAccrualAmount => 0.0,
                                                           :ReturnedCheckAmount => 0.0,
                                                           :PaymentInSuspenseIndicator => false}
                },
                :SSATitleIIYearlyIncome => {
                  :TitleIIRequestedYearInformation => {
                    :IncomeDate => "2000",
                    :YearlyIncomeAmount => 0.0
                  }
                },
                :SSAQuartersOfCoverage => {
                  :LifeTimeQuarterQuantity => 0,
                  :QualifyingYearAndQuarter => {
                    :QualifyingYear => "2006",
                    :QualifyingQuarter => 2
                  }
                }
              }
            }
          ],
          :ResponseMetadata => {
            :ResponseCode => "Response",
            :ResponseDescriptionText => "ResponseDescriptionText0",
            :TDSResponseDescriptionText => "TDSResponseDescriptionText0"
          }
        }
      end

      let(:response) do
        AcaEntities::Fdsh::Ssa::H3::SSACompositeResponse.new(response_payload)
      end

      before do
        person.consumer_role.update!(aasm_state: "ssa_pending")
        person.consumer_role.vlp_documents << FactoryBot.build(:vlp_document, :identifier => 'identifier', :verification_type => 'Immigration type')
      end

      subject do
        described_class.new.call({person_hbx_id: person.hbx_id, response: response.to_h})
      end

      it "should pass" do
        expect(subject).to be_success
      end
    end

    context "with minimum payload" do
      let(:response_payload) do
        {
          :SSACompositeIndividualResponses => [
            {
              :ResponseMetadata => {
                :ResponseCode => "HS000000",
                :ResponseDescriptionText => "ResponseDescriptionText0",
                :TDSResponseDescriptionText => nil
              },
              :PersonSSNIdentification => "100101000",
              :SSAResponse => nil
            }
          ],
          :ResponseMetadata => {
            :ResponseCode => "HS000000",
            :ResponseDescriptionText => "ResponseDescriptionText0",
            :TDSResponseDescriptionText => nil
          }
        }
      end

      let(:response) do
        AcaEntities::Fdsh::Ssa::H3::SSACompositeResponse.new(response_payload)
      end

      before do
        person.consumer_role.update!(aasm_state: "ssa_pending")
        person.consumer_role.vlp_documents << FactoryBot.build(:vlp_document, :identifier => 'identifier', :verification_type => 'Immigration type')
      end

      subject do
        described_class.new.call({person_hbx_id: person.hbx_id, response: response.to_h})
      end

      it "should pass" do
        expect(subject).to be_success
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
