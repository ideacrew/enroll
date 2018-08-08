require 'rails_helper'

module BenefitSponsors
  RSpec.describe Forms::BenefitForm, type: :model, dbclean: :after_each do

    subject { BenefitSponsors::Forms::BenefitForm.new }
    let(:site)                  { build(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:benefit_sponsor)        { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile_initial_application, site: site) }
    let(:benefit_sponsorship)    { benefit_sponsor.active_benefit_sponsorship }
    let(:benefit_application)    { benefit_sponsorship.benefit_applications.first }
    let(:benefit_package)    { benefit_application.benefit_packages.first }
    describe "model attributes" do
      it {
        [:benefit_package_id, :benefit_sponsorship_id, :sponsored_benefit_id, :kind, :sponsored_benefit].each do |key|
          expect(subject.attributes.has_key?(key)).to be_truthy
        end
      }
    end

    describe "#for_new" do
      let(:benefit_form) { FactoryGirl.build(:benefit_sponsors_forms_benefit_form)}

      it "should assign benefit sponsorship" do
        form = BenefitSponsors::Forms::BenefitForm.for_new({benefit_sponsorship_id: benefit_sponsorship.id, benefit_package_id: benefit_package.id, kind: "dental"})
        expect(form.service).to be_instance_of(BenefitSponsors::Services::SponsoredBenefitService)
        expect(form.benefit_sponsorship_id).to eq  benefit_sponsorship.id.to_s
      end
    end

    describe "#for_create" do
      let(:params) {
        {
            :benefit_package_id => benefit_package.id,
            :benefit_sponsorship_id => benefit_sponsorship.id,
            :kind => 'test'
        }
      }

      it "should create the form assign the params for forms" do
        form = BenefitSponsors::Forms::BenefitForm.for_create(params)
        expect(form.benefit_package_id).to eq params[:benefit_package_id].to_s
        expect(form.benefit_sponsorship_id).to eq params[:benefit_sponsorship_id].to_s
        expect(form.kind).not_to be 'test'
      end
    end


  end
end
