require 'rails_helper'

module BenefitSponsors
  RSpec.describe Concerns::EmployerProfileConcern, type: :model, dbclean: :after_each do
    describe "#billing_benefit_application" do
      let(:organization) { FactoryGirl.build(:benefit_sponsors_organizations_general_organization,
        :with_site,
        :with_aca_shop_cca_employer_profile_initial_application
      )}

      let(:profile) { organization.employer_profile }
      let(:benefit_sponsorship) { organization.active_benefit_sponsorship }
      let(:application) { benefit_sponsorship.current_benefit_application }

      context "when billing date is given" do
        it "should return application and given billing date if given date covers benefit_application effective period" do
          date = application.start_on
          expect(profile.billing_benefit_application(date)).to eq [application, date]
        end

        it "should return nil and given billing date if given date not covers benefit_application effective period" do
          date = application.start_on - 1.month
          expect(profile.billing_benefit_application(date)).to eq [nil, date]
        end
      end
      context "when billing date is blank" do
        context "For initial employer" do
          it "should return initial published application effective date & initial start on date" do
            application
            expect(profile.billing_benefit_application).to eq [application, application.start_on.to_date]
          end
        end

        context "For renewal employer" do

          let(:organization) { FactoryGirl.build(:benefit_sponsors_organizations_general_organization,
            :with_site,
            :with_aca_shop_cca_employer_profile_renewal_application
          )}

          let(:renewal_application) { application.successors.first }
          it "should return renewal published application effective date & renewal start on date" do
            renewal_application
            expect(profile.billing_benefit_application).to eq [renewal_application, renewal_application.start_on.to_date]
          end
        end
      end
    end
  end
end
