require 'rails_helper'

RSpec.describe Enrollments::IndividualMarket::OpenEnrollmentBegin, type: :model do
  before do
    DatabaseCleaner.clean
  end

  let!(:hbx_profile) { FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period) }

  let!(:family_unassisted)              { FactoryGirl.create(:individual_market_family)}
  let!(:enrollment_unassisted)          { FactoryGirl.create(:hbx_enrollment, :individual_unassisted, :with_enrollment_members,
                                                             household: family_unassisted.active_household,
                                                             enrollment_members: [family_unassisted.family_members.first],
                                                             plan: active_individual_health_plan)}

  let!(:family_assisted)                { FactoryGirl.create(:individual_market_family)}
  let!(:tax_household1)                 { FactoryGirl.create(:tax_household, household: family_assisted.active_household)}
  let!(:eligibility_determination1)     { FactoryGirl.create(:eligibility_determination, tax_household: tax_household1)}
  let!(:tax_household_member1)          { tax_household1.tax_household_members.create(applicant_id: family_assisted.family_members.first.id, is_ia_eligible: true)}
  let!(:enrollment_assisted)            { FactoryGirl.create(:hbx_enrollment, :individual_assisted, :with_enrollment_members,
                                                             applied_aptc_amount: 110,
                                                             household: family_assisted.active_household,
                                                             enrollment_members: [family_assisted.family_members.first],
                                                             plan: active_csr_87_plan)}

  let!(:families)                       { FactoryGirl.create_list(:individual_market_family, 10)}

  let!(:active_individual_health_plan)  { FactoryGirl.create(:active_individual_health_plan, renewal_plan: renewal_individual_health_plan) }
  let(:active_shop_health_plan)               { FactoryGirl.create(:active_shop_health_plan) }
  let(:active_individual_dental_plan)         { FactoryGirl.create(:active_individual_dental_plan) }
  let(:active_individual_catastophic_plan)    { FactoryGirl.create(:active_individual_catastophic_plan) }
  let(:active_csr_87_plan)                    { FactoryGirl.create(:active_csr_87_plan, renewal_plan: renewal_csr_87_plan) }
  let(:active_csr_00_plan)                    { FactoryGirl.create(:active_csr_00_plan) }

  let!(:renewal_individual_health_plan)        { FactoryGirl.build(:renewal_individual_health_plan ) }
  let!(:update_renewal_individual_health_plan)        { renewal_individual_health_plan.update_attributes!( hios_id: active_individual_health_plan.hios_id , hios_base_id: active_individual_health_plan.hios_base_id )
  }

  let(:renewal_shop_health_plan)              { FactoryGirl.create(:renewal_shop_health_plan) }
  let(:renewal_individual_dental_plan)        { FactoryGirl.create(:renewal_individual_dental_plan) }
  let(:renewal_individual_catastophic_plan)   { FactoryGirl.create(:renewal_individual_catastophic_plan) }
  let(:renewal_csr_87_plan)                   { FactoryGirl.create(:renewal_csr_87_plan) }
  let!(:update_renewal_csr_87_plan)        { renewal_csr_87_plan.update_attributes!( hios_id: active_csr_87_plan.hios_id , hios_base_id: active_csr_87_plan.hios_base_id )
  }
  let(:renewal_csr_00_plan)                   { FactoryGirl.create(:renewal_csr_00_plan) }

  context "Given a database of Families" do
    before :each do
      field_names =
          ["Icnumber", "Ssn", "Subscriber", "Member", "Firstname", "Lastname", "Dob",
           "2018 Applied", "2018 Max", "Unadjustedapplied", "Applied Pct",
           "2019 Aptc", "2019 Applied", "2019 Csr", "Error Msg"]
      Dir.mkdir("pids") unless File.exists?("pids")
      file_name = "#{Rails.root}/pids/2018_FA_Renewals.csv"

      CSV.open(file_name, "w") do |csv|
        csv << field_names
        Family.all.each do |f|
          person = f.primary_family_member.person
          csv << ["",person.ssn,person.hbx_id, person.hbx_id, person.first_name, person.last_name, person.dob, 100,200,"",0,400,150,73]
        end
      end
    end
    it "the collection should include ten or more Families" do
      expect(Family.all.size).to be >= 10
    end

    it "at least one Family with both active Individual Market Health and Dental plan Enrollments"
    it "at least one Family with an active 'Individual Market Health plan Enrollment only'" do
      expect(family_unassisted.active_household.hbx_enrollments.first.kind).to eq "individual"
    end

    it "at least one Family with an active 'Assisted Individual Market Health plan Enrollment only'" do
      expect(family_assisted.active_household.hbx_enrollments.first.applied_aptc_amount).not_to eq 0
    end

    context "when OE script is executed" do
      before do
        renewal_individual_health_plan.reload
        active_individual_health_plan.reload
      end
      it "should generate renewal enrollment for assisted family" do
        invoke_oe_script
        family_assisted.active_household.reload
        expect(family_assisted.active_household.hbx_enrollments.count).to eq 2
      end

      it "should generate renewal enrollment for unassisted family" do
        invoke_oe_script
        family_unassisted.active_household.reload
        expect(family_unassisted.active_household.hbx_enrollments.count).to eq 2
      end
    end

    it "at least one Family with an active 'Individual Market Catastrophic plan Enrollment only'"
    it "at least one Family with two active Individual Market Health plan Enrollments, one which is responsible person"
    it "at least one Family with active Individual and SHOP Market Health plan Enrollments"
    it "at least one Family with active Individual Market Dental and SHOP Market Health plan Enrollments"
    it "at least one Family with a terminated 'Individual Market Health plan Enrollment only'"
    it "at least one Family with a terminated 'Individual Market Dental plan Enrollment only'"
    it "at least one Family with a future terminated 'Individual Market Health plan Enrollment only'"
    it "at least one Family with a future terminated 'Individual Market Dental-only plan Enrollment'"


    context "and only Families eligible for enrollment auto renewal processing are selected from database" do

      it "the set should include Families with both active Individual Market Health and Dental plan Enrollments"
      it "the set should include Families with an active 'Individual Market Health plan Enrollment only'"
      it "the set should include Families with active Individual and SHOP Market Health plan Enrollments"
      it "the set should include Families with active Individual Market Dental and SHOP Market Health plan Enrollments"

      it "the set should not include Families with a terminated 'Individual Market Health plan Enrollment only'"
      it "the set should not include Families with a terminated 'Individual Market Dental plan Enrollment only'"
      it "the set should not include Families a future terminated 'Individual Market Health plan Enrollment only'"
      it "the set should not include Families a future terminated Individual Market Dental-only plan Enrollment"


      context "and the Family with both active Individual Market Health and Dental plan Enrollments is renewed" do
        it "should create a new Health enrollment"
        it "the new enrollment's health plan should be valid for the upcoming calendar year"
        it "the new enrollment's effective date should be Jan 1 of next calendar year"
        it "the new enrollment should include all the enrollees from the current plan year"
        it "the new enrollment should successfully calculate premium"

        it "should create a new Dental plan enrollment"
        it "the new enrollment's dental plan should be valid for the upcoming calendar year"
        it "the new enrollment's effective date should be Jan 1 of next calendar year"
        it "the new enrollment should include all the enrollees from the current plan year"
        it "the new enrollment should have a calculatable premium"

        context "and one child dependent is over age 26 on Jan 1" do
          it "the child should be member of the extended_family_coverage_household"
          it "the child should not be member of the immediate_family_coverage_household"
          it "the child should not be included in the new health enrollment group"
          it "the child should not be included in the new dental enrollment group"
        end

        context "and one child dependent is over age 26 Jan 1 and disabled" do
          it "the child should not be member of the extended_family_coverage_household"
          it "the child should be member of the immediate_family_coverage_household"
          it "the child should be included in the new health enrollment group"
          it "the child should be included in the new dental enrollment group"
        end
      end

      context "and the Family with an active 'Assisted Individual Market Health plan Enrollment only' is renewed" do

        context "and a financial eligibility determination is found" do
          context "and the determination end date is earlier than Jan 1 of the next calendar year" do
            it "the renewed enrollment should have $0 APTC for the new plan year"

            context "and the renewed enrollment is a silver plan" do
              it "the renewed plan should not have a CSR variant"
            end
          end

          context "and the financial assistance redetermination has no end date" do
            it "the renewed enrollment should have the same APTC percentage as the current enrollment"

            context "and the renewed enrollment is a silver plan" do
              it "the renewed plan should not have the CSR variant from the financial redetermination"
            end
          end
        end
      end

      context "and the Family with an active 'Individual Market Catastrophic plan Enrollment only' is renewed" do

        context "and none of the enrollment members are over age 30 on Jan 1" do
          it "the new enrollment should have a comparable Catastrophic plan"
        end

        context "and at least one of the enrollment members are over age 30 on Jan 1" do
          it "should renew enrollment into a mapped Bronze plan??"
        end
      end

      context "and the Family with two active Individual Market Health plan Enrollments, one which is responsible person is renewed" do
        it "should produce a new standard enrollment"
        it "should produce a new responsible person enrollment"
      end

      context "and the Family with active Individual and SHOP Market Health plan Enrollments" do
        it "should produce a new Individual health enrollment"
        it "should not produce a new SHOP health enrollment"
      end

      context "and the Family with active Individual Market Dental and SHOP Market Health plan Enrollments" do
        it "should produce a new Individual dental enrollment"
        it "should not produce a new SHOP health enrollment"
      end

    end
  end

  context "Today is 30 days prior to the first day of the Annual Open Enrollment period for the HBX Individual Market" do
    it "should generate and transmit renewal notices"
  end

  context "Today is the first day of the Annual Open Enrollment period for the HBX Individual Market" do
    context "and health and dental plans and rates for the new calendar year are loaded" do
      context "and comparable plan mapping from this calendar year to the next calendar year is present" do
        context "and Assisted QHP Families have finanancial eligibility redetermined for the next calendar year" do
        end
      end
    end
  end


end

private

def invoke_oe_script
  oe_begin = Enrollments::IndividualMarket::OpenEnrollmentBegin.new
  oe_begin.process_renewals
end
