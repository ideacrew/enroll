require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitPackages::BenefitPackage, type: :model, :dbclean => :after_each do
    pending "add some examples to (or delete) #{__FILE__}"

    describe ".renew" do
      context "when a valid new benefit package passed to an existing benefit package for renewal" do

        let(:renewal_effective_date)  { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
        let(:current_effective_date)  { renewal_effective_date.prev_year }
        let(:effective_period)        { current_effective_date..current_effective_date.next_year.prev_day }

        let(:benefit_market)          { create(:benefit_markets_benefit_market, site_urn: 'mhc', kind: :aca_shop, title: "MA Health Connector SHOP Market") }

        let!(:current_benefit_market_catalog) { build(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                                      benefit_market: benefit_market,
                                                      title: "SHOP Benefits for #{current_effective_date.year}",
                                                      application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year)
                                                    )}

        let!(:renewal_benefit_market_catalog) { build(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                                        benefit_market: benefit_market,
                                                        title: "SHOP Benefits for #{renewal_effective_date.year}",
                                                        application_period: (renewal_effective_date.beginning_of_year..renewal_effective_date.end_of_year)
                                                      )}

        let(:benefit_sponsorship)             { create(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                                                        benefit_market: benefit_market) }

        let(:initial_application)             { create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog,
                                                        benefit_sponsorship: benefit_sponsorship, effective_period: effective_period) }

        let(:renewal_benefit_sponsor_catalog) { benefit_sponsorship.benefit_sponsor_catalog_for(renewal_effective_date) }
        let(:renewal_application)             { initial_application.renew(renewal_benefit_sponsor_catalog) }
        let(:single_issuer_product_package)   { initial_application.benefit_sponsor_catalog.product_packages.detect { |package| package.package_kind == :single_issuer } }
        
        let(:current_benefit_package)         { create(:benefit_sponsors_benefit_packages_benefit_package, product_package: single_issuer_product_package) }
        let(:renewal_benefit_package)         { renewal_application.benefit_packages.build }

        before do
          map_products
          current_benefit_package.renew(renewal_benefit_package)
        end

        def map_products
          current_benefit_market_catalog.product_packages.each do |product_package|
            if renewal_product_package = renewal_benefit_market_catalog.product_packages.detect{ |p|
              p.package_kind == product_package.package_kind && p.product_kind == product_package.product_kind }

              renewal_product_package.products.each_with_index do |renewal_product, i|
                current_product = product_package.products[i]
                current_product.update(renewal_product_id: renewal_product.id)
              end
            end
          end
        end

        it "applications should be valid" do
          initial_application.validate
          renewal_application.validate
          expect(initial_application).to be_valid
          expect(renewal_application).to be_valid
        end

        it "should renew benefit package" do
          expect(renewal_benefit_package).to be_present
          expect(renewal_benefit_package.title).to eq current_benefit_package.title
          expect(renewal_benefit_package.description).to eq current_benefit_package.description
          expect(renewal_benefit_package.probation_period_kind).to eq current_benefit_package.probation_period_kind
          expect(renewal_benefit_package.is_default).to eq  current_benefit_package.is_default
        end

        it "should renew sponsored benefits" do
          expect(renewal_benefit_package.sponsored_benefits.size).to eq current_benefit_package.sponsored_benefits.size
        end

        it "should reference to renewal product package" do
          renewal_benefit_package.sponsored_benefits.each_with_index do |sponsored_benefit, i|
            current_sponsored_benefit = current_benefit_package.sponsored_benefits[i]
            expect(sponsored_benefit.product_package).to eq renewal_benefit_sponsor_catalog.product_packages.by_package_kind(current_sponsored_benefit.product_package_kind).by_product_kind(current_sponsored_benefit.product_kind)[0]
          end
        end

        it "should attach renewal reference product" do
          renewal_benefit_package.sponsored_benefits.each_with_index do |sponsored_benefit, i|
            current_sponsored_benefit = current_benefit_package.sponsored_benefits[i]
            expect(sponsored_benefit.reference_product).to eq current_sponsored_benefit.reference_product.renewal_product
          end
        end

        it "should renew sponsor contributions" do
          renewal_benefit_package.sponsored_benefits.each_with_index do |sponsored_benefit, i|
            expect(sponsored_benefit.sponsor_contribution).to be_present

            current_sponsored_benefit = current_benefit_package.sponsored_benefits[i]
            current_sponsored_benefit.sponsor_contribution.contribution_levels.each_with_index do |current_contribution_level, i|
              new_contribution_level = sponsored_benefit.sponsor_contribution.contribution_levels[i]
              expect(new_contribution_level.is_offered).to eq current_contribution_level.is_offered
              expect(new_contribution_level.contribution_factor).to eq current_contribution_level.contribution_factor
            end
          end
        end

        it "should renew pricing determinations" do
        end
      end
    end
  end
end
