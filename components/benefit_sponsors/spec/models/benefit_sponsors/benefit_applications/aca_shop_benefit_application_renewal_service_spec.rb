require 'rails_helper'

module BenefitSponsors

  RSpec.describe BenefitApplications::AcaShopBenefitApplicationRenewalService, type: :model do

    describe 'constructor' do
      let(:employer_profile) { double("AcaShopCcaEmployerProfile") }
      let(:sponsorship) { double("BenefitSponsorship", :profile => employer_profile) }
      let(:benefit_application) { double("BenefitApplication", :benefit_sponsorship => sponsorship) }

      it 'should initialize and use the attributes' do
        service_object = BenefitSponsors::BenefitApplications::AcaShopBenefitApplicationRenewalService.new(benefit_application)
        expect(service_object.employer_profile).to eq employer_profile
        expect(service_object.benefit_sponsorship).to eq sponsorship
        expect(service_object.benefit_application).to eq benefit_application
      end
    end

    describe '.generate_renewal' do
      let!(:benefit_application) {FactoryGirl.create(:benefit_sponsors_benefit_application)}
      let(:profile) {benefit_application.benefit_sponsorship.profile}

      context 'created renewal for benefit application' do
        it 'should generated successfully' do
          # very bad to allow too many things but for time being since we do not have benefit groups we are just mocking
          service_object = BenefitSponsors::BenefitApplications::AcaShopBenefitApplicationRenewalService.new(benefit_application)
          allow(profile).to receive(:may_enroll_employer?).and_return(true)
          allow(profile).to receive(:enroll_employer!).and_return(true)
          expect(service_object.generate_renewal).to eq true
        end
      end
    end
  end
end