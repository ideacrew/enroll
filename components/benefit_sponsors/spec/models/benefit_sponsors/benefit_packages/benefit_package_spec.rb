require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe BenefitPackages::BenefitPackage, type: :model, :dbclean => :after_each do

    let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:title)                 { "Generous BenefitPackage - 2018"}
    let(:probation_period_kind) { :first_of_month_after_30_days }

    let(:params) do
      {
        title: title,
        probation_period_kind: probation_period_kind,
      }
    end

    context "A new model instance" do
      it { is_expected.to be_mongoid_document }
      it { is_expected.to have_field(:title).of_type(String).with_default_value_of("")}
      it { is_expected.to have_field(:description).of_type(String).with_default_value_of("")}
      it { is_expected.to have_field(:probation_period_kind).of_type(Symbol)}
      it { is_expected.to have_field(:is_default).of_type(Mongoid::Boolean).with_default_value_of(false)}
      it { is_expected.to have_field(:is_active).of_type(Mongoid::Boolean).with_default_value_of(true)}
      it { is_expected.to have_field(:predecessor_id).of_type(BSON::ObjectId)}
      it { is_expected.to embed_many(:sponsored_benefits)}
      it { is_expected.to be_embedded_in(:benefit_application)}


      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no title" do
        subject { described_class.new(params.except(:title)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no probation_period_kind" do
        subject { described_class.new(params.except(:probation_period_kind)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with all required arguments" do
        subject { described_class.new(params) }


        context "and all arguments are valid" do
          it "should be valid" do
            subject.validate
            expect(subject).to be_valid
          end
        end
      end
    end

    describe ".renew" do
      context "when passed renewal benefit package to current benefit package for renewal" do

        let(:renewal_benefit_sponsor_catalog) { benefit_sponsorship.benefit_sponsor_catalog_for(benefit_sponsorship.service_areas_on(renewal_effective_date), renewal_effective_date) }
        let(:renewal_application)             { initial_application.renew(renewal_benefit_sponsor_catalog) }
        let!(:renewal_benefit_package)        { renewal_application.benefit_packages.build }

        before do
          current_benefit_package.renew(renewal_benefit_package)
        end

        it "should have valid applications" do
          initial_application.validate
          renewal_application.validate
          expect(initial_application).to be_valid
          expect(renewal_application).to be_valid
        end

        it "should renew benefit package" do
          expect(renewal_benefit_package).to be_present
          expect(renewal_benefit_package.title).to eq current_benefit_package.title + "(#{renewal_benefit_package.start_on.year})"
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

      context "when employer offering both health and dental coverages" do
        let(:product_kinds)  { [:health, :dental] }
        let(:dental_sponsored_benefit) { true }

        let(:renewal_benefit_sponsor_catalog) { benefit_sponsorship.benefit_sponsor_catalog_for(benefit_sponsorship.service_areas_on(renewal_effective_date), renewal_effective_date) }
        let(:renewal_application)             { initial_application.renew(renewal_benefit_sponsor_catalog) }
        let(:renewal_bp)        { renewal_application.benefit_packages.build }

        let(:current_app) { benefit_sponsorship.benefit_applications[0] }
        let(:current_bp)  { current_app.benefit_packages[0] }

        subject do
          current_bp.renew(renewal_bp)
        end

        context "when renewal product available for both health and dental" do 

          let(:health_sb) { current_bp.sponsored_benefit_for(:health) }
          let(:dental_sb) { current_bp.sponsored_benefit_for(:dental) }
  
          it "does build valid renewal benefit package" do
            expect(subject.valid?).to be_truthy
          end

          it "does renew health sponsored benefit" do
            expect(subject.sponsored_benefit_for(:health)).to be_present 
          end

          it "does renew health reference product" do
            expect(subject.sponsored_benefit_for(:health).reference_product).to eq health_sb.reference_product.renewal_product
          end

          it "does renew health sponsor contributions" do
            sponsor_contribution = subject.sponsored_benefit_for(:health).sponsor_contribution
            expect(sponsor_contribution).to be_present
            expect(sponsor_contribution.contribution_levels.size).to eq health_sb.sponsor_contribution.contribution_levels.size
          end

          it "does renew dental sponsored benefit" do
            expect(subject.sponsored_benefit_for(:dental)).to be_present 
          end

          it "does renew dental reference product" do
            expect(subject.sponsored_benefit_for(:dental).reference_product).to eq dental_sb.reference_product.renewal_product
          end

          it "does renew dental sponsor contributions" do
            sponsor_contribution = subject.sponsored_benefit_for(:dental).sponsor_contribution
            expect(sponsor_contribution).to be_present
            expect(sponsor_contribution.contribution_levels.size).to eq dental_sb.sponsor_contribution.contribution_levels.size
          end
        end

        context "when renewal product available for health only" do
          let!(:dental_products) { create_list(:benefit_markets_products_dental_products_dental_product, 5,
            application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year),
            product_package_kinds: [:single_product],
            service_area: service_area,
            metal_level_kind: :dental)
          }

          let(:health_sb) { current_bp.sponsored_benefit_for(:health) }
          let(:dental_sb) { current_bp.sponsored_benefit_for(:dental) }
  
          it "does build valid renewal benefit package" do
            expect(subject.valid?).to be_truthy
          end

          it "does renew health sponsored benefit" do
            expect(subject.sponsored_benefit_for(:health)).to be_present 
          end

          it "does renew health reference product" do
            expect(subject.sponsored_benefit_for(:health).reference_product).to eq health_sb.reference_product.renewal_product
          end

          it "does renew health sponsor contributions" do
            sponsor_contribution = subject.sponsored_benefit_for(:health).sponsor_contribution
            expect(sponsor_contribution).to be_present
            expect(sponsor_contribution.contribution_levels.size).to eq health_sb.sponsor_contribution.contribution_levels.size
          end

          it "does not renew dental sponsored benefit" do
            expect(subject.sponsored_benefit_for(:dental)).to be_blank 
          end
        end

        context "when renewal product available for dental only" do
          let!(:health_products) { create_list(:benefit_markets_products_health_products_health_product, 5,
            application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year),
            product_package_kinds: [:single_issuer, :metal_level, :single_product],
            service_area: service_area,
            metal_level_kind: :gold)
          }

          let(:health_sb) { current_bp.sponsored_benefit_for(:health) }
          let(:dental_sb) { current_bp.sponsored_benefit_for(:dental) }
  
          it "does build valid renewal benefit package" do
            expect(subject.valid?).to be_truthy
          end

          it "does not renew health sponsored benefit" do
            expect(subject.sponsored_benefit_for(:health)).to be_blank 
          end

          it "does renew dental sponsored benefit" do
            expect(subject.sponsored_benefit_for(:dental)).to be_present 
          end

          it "does renew dental reference product" do
            expect(subject.sponsored_benefit_for(:dental).reference_product).to eq dental_sb.reference_product.renewal_product
          end

          it "does renew dental sponsor contributions" do
            sponsor_contribution = subject.sponsored_benefit_for(:dental).sponsor_contribution
            expect(sponsor_contribution).to be_present
            expect(sponsor_contribution.contribution_levels.size).to eq dental_sb.sponsor_contribution.contribution_levels.size
          end
        end

        context "when renewal product not available for both health and dental" do 
          let!(:health_products) { create_list(:benefit_markets_products_health_products_health_product, 5,
            application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year),
            product_package_kinds: [:single_issuer, :metal_level, :single_product],
            service_area: service_area,
            metal_level_kind: :gold)
          }

          let!(:dental_products) { create_list(:benefit_markets_products_dental_products_dental_product, 5,
            application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year),
            product_package_kinds: [:single_product],
            service_area: service_area,
            metal_level_kind: :dental)
          }

          let(:health_sb) { current_bp.sponsored_benefit_for(:health) }
          let(:dental_sb) { current_bp.sponsored_benefit_for(:dental) }
  
          it "does build valid renewal benefit package" do
            expect(subject.valid?).to be_truthy
          end

          it "does not renew health sponsored benefit" do
            expect(subject.sponsored_benefit_for(:health)).to be_blank 
          end

          it "does not renew dental sponsored benefit" do
            expect(subject.sponsored_benefit_for(:dental)).to be_blank 
          end
        end

        context "when employer has conversion dental sponsored benefit" do 

          let(:health_sb) { current_bp.sponsored_benefit_for(:health) }
          let(:dental_sb) { current_bp.sponsored_benefits.unscoped.detect{|sb| sb.product_kind == :dental } }

          before do
            dental_sb.update(source_kind: :conversion)
            current_bp.reload
          end

          it "does build valid renewal benefit package" do
            expect(subject.valid?).to be_truthy
          end

          it "does renew health sponsored benefit" do
            expect(subject.sponsored_benefit_for(:health)).to be_present 
          end

          it "does renew health reference product" do
            expect(subject.sponsored_benefit_for(:health).reference_product).to eq health_sb.reference_product.renewal_product
          end

          it "does renew health sponsor contributions" do
            sponsor_contribution = subject.sponsored_benefit_for(:health).sponsor_contribution
            expect(sponsor_contribution).to be_present
            expect(sponsor_contribution.contribution_levels.size).to eq health_sb.sponsor_contribution.contribution_levels.size
          end

          it "does renew dental sponsored benefit" do
            expect(dental_sb.source_kind).to eq :conversion
            expect(subject.sponsored_benefit_for(:dental)).to be_present
            expect(subject.sponsored_benefit_for(:dental).source_kind).to eq :benefit_sponsor_catalog 
          end

          it "does renew dental reference product" do
            expect(subject.sponsored_benefit_for(:dental).reference_product).to eq dental_sb.reference_product.renewal_product
          end

          it "does renew dental sponsor contributions" do
            sponsor_contribution = subject.sponsored_benefit_for(:dental).sponsor_contribution
            expect(sponsor_contribution).to be_present
            expect(sponsor_contribution.contribution_levels.size).to eq dental_sb.sponsor_contribution.contribution_levels.size
          end
        end
      end
    end

    describe '.renew_member_benefit' do
      include_context "setup renewal application"

      let(:renewed_enrollment) { double("hbx_enrollment")}
      let(:ra) {renewal_application}
      let(:ia) {predecessor_application}
      let(:bs) { ra.predecessor.benefit_sponsorship}
      let(:cbp){ra.predecessor.benefit_packages.first}
      let(:rbp){ra.benefit_packages.first}
      let(:roster_size) { 5 }
      let(:enrollment_kinds) { ['health'] }
      let!(:census_employees) { create_list(:census_employee, roster_size, :with_active_assignment, benefit_sponsorship: bs, employer_profile: bs.profile, benefit_group: cbp) }
      let!(:person) { FactoryGirl.create(:person) }
      let!(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}
      let!(:employee_role) { FactoryGirl.create(:benefit_sponsors_employee_role, person: person)}
      let!(:census_employee) { census_employees.first }
      let(:hbx_enrollment) { FactoryGirl.build(:hbx_enrollment, :shop,
                                                household: family.active_household,
                                                product: cbp.sponsored_benefits.first.reference_product,
                                                coverage_kind: :health,
                                                employee_role_id: census_employee.employee_role.id,
                                                sponsored_benefit_package_id: cbp.id,
                                                benefit_group_assignment_id: census_employee.benefit_group_assignments.last.id
                                                ) }

      let(:renewal_product_package)    { renewal_benefit_market_catalog.product_packages.detect { |package| package.package_kind == package_kind } }
      let(:product) { renewal_product_package.products[0] }

      let!(:update_product){
        reference_product = current_benefit_package.sponsored_benefits.first.reference_product
        reference_product.renewal_product = product
        reference_product.save!
      }

      before do
        census_employee.update_attributes(employee_role_id: employee_role.id)
        census_employee.employee_role.primary_family.active_household.hbx_enrollments << hbx_enrollment
        census_employee.employee_role.primary_family.save
        predecessor_application.update_attributes({:aasm_state => "active"})
        ra.update_attributes({:aasm_state => "enrollment_eligible"})
        hbx_enrollment.benefit_group_assignment_id = census_employee.benefit_group_assignments[0].id
        rbp.renew_member_benefit(census_employee)
        allow(rbp).to receive(:is_renewal_benefit_available?).and_return(true)
        allow(rbp).to receive(:trigger_renewal_model_event).and_return nil
        allow(hbx_enrollment).to receive(:renew_benefit).with(rbp).and_return(renewed_enrollment)
      end

      it "should have renewing enrollment" do
        hbx_enrollment.update_attributes(benefit_sponsorship: bs, aasm_state: 'coverage_enrolled')
        hbx_enrollment.save
        expect(benefit_sponsorship).not_to eq nil
        expect(family.active_household.hbx_enrollments.enrolled_and_waived.by_benefit_sponsorship(benefit_sponsorship)
          .by_effective_period(predecessor_application.effective_period).count).to eq 1
        expect(census_employee.benefit_group_assignments[0].hbx_enrollments.first.aasm_state).to eq "coverage_enrolled"
      end

      it "when active enrollment terminated for initial application" do
        hbx_enrollment.update_attributes(benefit_sponsorship: bs, aasm_state: 'coverage_terminated')
        hbx_enrollment.save
        expect(family.active_household.hbx_enrollments.enrolled_and_waived.by_benefit_sponsorship(benefit_sponsorship)
          .by_effective_period(predecessor_application.effective_period).count).to eq 0
        expect(census_employee.benefit_group_assignments[0].hbx_enrollments.first.aasm_state).to eq "coverage_terminated"
      end
    end

    describe '.is_renewal_benefit_available?' do

      let(:renewal_product_package)    { renewal_benefit_market_catalog.product_packages.detect { |package| package.package_kind == package_kind } }
      let(:product) { renewal_product_package.products[0] }
      let(:reference_product) { current_benefit_package.sponsored_benefits[0].reference_product }
      let(:current_enrolled_product) { product_package.products[2] }

      let!(:update_product){
        reference_product.renewal_product = product
        reference_product.save!
      }
      
      let(:renewal_benefit_sponsor_catalog) { benefit_sponsorship.benefit_sponsor_catalog_for(benefit_sponsorship.service_areas_on(renewal_effective_date), renewal_effective_date) }
      let(:renewal_application)             { initial_application.renew(renewal_benefit_sponsor_catalog) }
      let(:renewal_benefit_package)         { renewal_application.benefit_packages.build }

      context "when renewal product missing" do
        let(:hbx_enrollment) { double(product: current_enrolled_product, is_coverage_waived?: false, coverage_kind: :health) }
        let(:renewal_sponsored_benefit) do
          renewal_benefit_package.sponsored_benefits.build(
            product_package_kind: :single_issuer
          )
        end

        before do
          allow(current_enrolled_product).to receive(:renewal_product).and_return(nil)
          allow(renewal_benefit_package).to receive(:sponsored_benefit_for).and_return(renewal_sponsored_benefit)
        end

        it 'should return false' do
          expect(renewal_benefit_package.is_renewal_benefit_available?(hbx_enrollment)).to be_falsey
        end
      end

      context "when renewal product offered by employer" do
        let(:hbx_enrollment) { double(product: current_benefit_package.sponsored_benefits.first.reference_product, coverage_kind: :health, is_coverage_waived?: false) }
        let(:sponsored_benefit) { renewal_benefit_package.sponsored_benefits.build(             
            product_package_kind: :single_issuer
          ) 
        }

        before do
          allow(sponsored_benefit).to receive(:products).and_return(renewal_product_package.products)
          allow(renewal_benefit_package).to receive(:sponsored_benefit_for).and_return(sponsored_benefit) 
        end

        it 'should return true' do
          expect(renewal_benefit_package.is_renewal_benefit_available?(hbx_enrollment)).to be_truthy
        end
      end

      context "when renewal product not offered by employer" do
        let(:product) {FactoryGirl.create(:benefit_markets_products_health_products_health_product)}
        let(:hbx_enrollment) { double(product: current_benefit_package.sponsored_benefits.first.reference_product, coverage_kind: :health, is_coverage_waived?: false) }
        let(:sponsored_benefit) { renewal_benefit_package.sponsored_benefits.build(             
            product_package_kind: :single_issuer
          ) 
        }

        before do
          allow(sponsored_benefit).to receive(:products).and_return(renewal_product_package.products)
          allow(renewal_benefit_package).to receive(:sponsored_benefit_for).and_return(sponsored_benefit) 
        end

        it "should return false" do
          expect(renewal_benefit_package.is_renewal_benefit_available?(hbx_enrollment)).to be_falsey
        end
      end
    end

    describe '.sponsored_benefit_for' do
    end

    describe '.assigned_census_employees_on' do
    end

    describe '.renew_employee_benefits' do
      include_context "setup employees with benefits"

    end

    describe 'changing reference product' do
      context 'changing reference product' do
        include_context "setup benefit market with market catalogs and product packages"
        include_context "setup initial benefit application"

        let(:sponsored_benefit) { initial_application.benefit_packages.first.sponsored_benefits.first }
        let(:new_reference_product) { product_package.products[2] }

        before do
          @benefit_application_id = sponsored_benefit.benefit_package.benefit_application.id
          sponsored_benefit.reference_product_id = new_reference_product._id
          sponsored_benefit.save!
        end

        it 'changes to the correct product' do
          bs = ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.benefit_application_find([@benefit_application_id]).first
          benefit_application_from_db = bs.benefit_applications.detect { |ba| ba.id == @benefit_application_id }
          expect(sponsored_benefit.reference_product).to eq(new_reference_product)
          sponsored_benefit_from_db = benefit_application_from_db.benefit_packages.first.sponsored_benefits.first
          expect(sponsored_benefit_from_db.id).to eq(sponsored_benefit.id)
          expect(sponsored_benefit_from_db.reference_product).to eq(new_reference_product)
        end
      end
    end

    describe '.reinstate_canceled_member_benefits' do

      context 'when application got canceled due to ineligble state' do


        context 'given employee coverages got canceled after application cancellation' do 

          it 'should reinstate their canceled coverages' do 
          end
        end

        context 'given employee coverages got canceled before application cancellation' do

          it 'should not reinstate their canceled coverages' do 
          end 
        end
      end

      context 'when application not canceled due to ineligble state' do 

        it 'should not process any reinstatements on enrollments' do 
        end
      end
    end
  end
end
