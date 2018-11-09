require 'rails_helper'

describe Household, "given a coverage household with a dependent", :dbclean => :after_each do
  let(:family_member) { FamilyMember.new }
  let(:coverage_household_member) { CoverageHouseholdMember.new(:family_member_id => family_member.id) }
  let(:coverage_household) { CoverageHousehold.new(:coverage_household_members => [coverage_household_member]) }

  subject { Household.new(:coverage_households => [coverage_household]) }

  it "should remove the dependent from the coverage households when removing them from the household" do
    expect(coverage_household).to receive(:remove_family_member).with(family_member)
    subject.remove_family_member(family_member)
  end

  it "should not have any enrolled hbx enrollments" do
    expect(subject.enrolled_hbx_enrollments).to eq []
  end

  it "ImmediateFamily should have domestic partner" do
    expect(Household::ImmediateFamily.include?('domestic_partner')).to eq true
  end

  context "new_hbx_enrollment_from" do
    let(:consumer_role) {FactoryGirl.create(:consumer_role)}
    let(:person) { double(primary_family: family)}
    let(:family) { double }
    let!(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let(:benefit_package) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first }
    let(:coverage_household) {CoverageHousehold.new}
    let(:household) {Household.new}

    before do
      allow(consumer_role).to receive(:person).and_return(person)
      allow(family).to receive(:is_under_special_enrollment_period?).and_return false
      allow(household).to receive(:family).and_return(family)
      allow(family).to receive(:is_under_ivl_open_enrollment?).and_return true
      allow(coverage_household).to receive(:household).and_return(household)
    end

    it "should build hbx enrollment" do
      subject.new_hbx_enrollment_from(
        consumer_role: consumer_role,
        coverage_household: coverage_household,
        benefit_package: benefit_package,
        qle: false
      )
    end
  end

  context "latest_active_tax_household_with_year" do
    let(:family) {FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:household) {FactoryGirl.create(:household, family: family)}
    let(:tax_household) {FactoryGirl.create(:tax_household, household: household, effective_ending_on: nil)}
    let(:tax_household2) {FactoryGirl.create(:tax_household, household: household)}
    let!(:hbx1) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_enrolled', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days))}

    it "return correct tax_household" do
      household.tax_households << tax_household
      expect(household.latest_active_tax_household_with_year(hbx1.effective_on.year)).to eq tax_household

    end

    it "return nil while current year is not empty" do
      household.tax_households << tax_household2
      expect(household.latest_active_tax_household_with_year(hbx1.effective_on.year)).to be_nil
    end

    it "return nil for not the same year" do
      household.tax_households << tax_household
      expect(household.latest_active_tax_household_with_year((hbx1.effective_on + 1.year).year)).to be_nil
    end

  end

  context "current_year_hbx_enrollments" do
    let(:family) {FactoryGirl.create(:family, :with_primary_family_member)}
    let(:household) {FactoryGirl.create(:household, family: family)}
    let!(:hbx1) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_enrolled', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}
    let!(:hbx2) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: false)}
    let!(:hbx3) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_terminated', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days))}
    let!(:hbx4) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_enrolled', changing: true)}

    it "should return right hbx_enrollments" do
      household.reload
      expect(household.hbx_enrollments.count).to eq 4
      expect(household.hbx_enrollments_with_aptc_by_year(TimeKeeper.date_of_record.year)).to eq [hbx1]
    end
  end

  context "enrolled_including_waived_hbx_enrollments" do
    let(:family) {FactoryGirl.create(:family, :with_primary_family_member)}
    let(:household) {FactoryGirl.create(:household, family: family)}
    let(:plan1){ FactoryGirl.create(:plan_template, :shop_health) }
    let(:plan2){ FactoryGirl.create(:plan_template, :shop_dental) }

    context "for shop health enrollment" do
      let!(:hbx1) {FactoryGirl.create(:hbx_enrollment, household: household, plan: plan1, is_active: true, aasm_state: 'coverage_selected', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}

      it "should return only health hbx enrollment" do
        expect(household.enrolled_including_waived_hbx_enrollments.size).to eq 1
        expect(household.enrolled_including_waived_hbx_enrollments.to_a).to eq [hbx1]
        expect(household.enrolled_including_waived_hbx_enrollments.map(&:plan).map(&:coverage_kind)).to eq ["health"]
      end
    end

    context "for shop dental enrollment" do
      let!(:hbx2) {FactoryGirl.create(:hbx_enrollment, household: household, plan: plan2, is_active: true, aasm_state: 'coverage_selected', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}

      it "should return only health hbx enrollment" do
        expect(household.enrolled_including_waived_hbx_enrollments.size).to eq 1
        expect(household.enrolled_including_waived_hbx_enrollments.to_a).to eq [hbx2]
        expect(household.enrolled_including_waived_hbx_enrollments.map(&:plan).map(&:coverage_kind)).to eq ["dental"]
      end
    end

    context "for both shop health and dental enrollment" do
      let!(:hbx1) {FactoryGirl.create(:hbx_enrollment, household: household, plan: plan1, is_active: true, aasm_state: 'coverage_selected', changing: false, coverage_kind: 'dental', effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}
      let!(:hbx3) {FactoryGirl.create(:hbx_enrollment, household: household, plan: plan1, is_active: true, aasm_state: 'coverage_selected', changing: false, coverage_kind: 'dental', effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}
      let!(:hbx2) {FactoryGirl.create(:hbx_enrollment, household: household, plan: plan2, is_active: true, aasm_state: 'inactive', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}
      let!(:hbx4) {FactoryGirl.create(:hbx_enrollment, household: household, plan: plan2, is_active: true, aasm_state: 'inactive', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}
      let!(:hbx5) {FactoryGirl.create(:hbx_enrollment, household: household, plan: plan2, is_active: true, aasm_state: 'coverage_enrolled', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 10)}

      it "should return the latest hbx enrollments for each shop and dental" do
        expect(household.enrolled_including_waived_hbx_enrollments.size).to eq 2
        expect(household.enrolled_including_waived_hbx_enrollments.to_a).to eq [hbx4, hbx3]
        expect(household.enrolled_including_waived_hbx_enrollments.map(&:plan).map(&:coverage_kind)).to eq ["dental", "health"]
      end
    end

  end

  it "ImmediateFamily should have stepchild" do
    expect(Family::IMMEDIATE_FAMILY.include?('stepchild')).to eq true
  end

  context "eligibility determinations for a household" do
    #let!(:tax_household1) {FactoryGirl.create(:tax_household }
    let(:year) { TimeKeeper.date_of_record.year }
    let(:family) {FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:household) {FactoryGirl.create(:household, family: family)}
    let(:tax_household1) {FactoryGirl.create(:tax_household, household: household)}
    let(:tax_household2) {FactoryGirl.create(:tax_household, household: household)}
    let(:tax_household3) {FactoryGirl.create(:tax_household, household: household)}
    let(:eligibility_determination1) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household1)}
    let(:eligibility_determination2) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household2)}
    let(:eligibility_determination3) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household3)}

    it "should return all the eligibility determinations across all tax households when there is one eligibility determination per tax household" do
      tax_household1.eligibility_determinations = [eligibility_determination1]
      tax_household2.eligibility_determinations = [eligibility_determination2]
      household.tax_households = [tax_household1, tax_household2]
      expect(household.eligibility_determinations_for_year(year).size).to eq 2
      household.eligibility_determinations_for_year(year).each do |ed|
        expect(household.eligibility_determinations_for_year(year)).to include(ed)
      end
    end

    it "should return all the eligibility determinations across all tax households when there is more than one eligibility determination in some tax household" do
      tax_household1.eligibility_determinations = [eligibility_determination1, eligibility_determination3]
      tax_household2.eligibility_determinations = [eligibility_determination2]
      household.tax_households = [tax_household1, tax_household2]
      expect(household.eligibility_determinations_for_year(year).size).to eq 3
      household.eligibility_determinations_for_year(year).each do |ed|
        expect(household.eligibility_determinations_for_year(year)).to include(ed)
      end
    end
  end


  # context "with an enrolled hbx enrollment" do
  #   let(:mock_hbx_enrollment) { instance_double(HbxEnrollment) }
  #   let(:hbx_enrollments) { [mock_hbx_enrollment] }
  #   before do
  #     allow(HbxEnrollment).to receive(:covered).with(hbx_enrollments).and_return(hbx_enrollments)
  #     allow(subject).to receive(:hbx_enrollments).and_return(hbx_enrollments)
  #   end

  #   it "should return the enrolled hbx enrollment in an array" do
  #     expect(subject.enrolled_hbx_enrollments).to eq hbx_enrollments
  #   end
  # end
end

describe "building tax household and tax household members" do
  let(:xml) { File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_4_member_family_sample.xml")) }
  let(:verified_family) { Parsers::Xml::Cv::VerifiedFamilyParser.new.parse(File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_4_member_family_sample.xml"))).first }
  let(:verified_primary_family_member) { verified_family.family_members.detect{ |fm| fm.id == verified_family.primary_family_member_id } }
  let(:person_params) do {
    addresses: [],
    phones: [],
    emails: [],
    person: {
      "first_name" => verified_primary_family_member.person.name_first.upcase,
      "last_name" => verified_primary_family_member.person.name_last.downcase,
      "middle_name" => verified_primary_family_member.person.name_middle,
      "name_pfx" => verified_primary_family_member.person.name_pfx,
      "name_sfx" => verified_primary_family_member.person.name_sfx,
      "dob" => verified_primary_family_member.person_demographics.birth_date,
      "ssn" => verified_primary_family_member.person_demographics.ssn,
      "no_ssn" => "1",
      "gender" => verified_primary_family_member.person_demographics.sex.split('#').last
    }
  }
  end
  let(:user) { FactoryGirl.create(:user) }
  let(:consumer_role) { Factories::EnrollmentFactory.construct_consumer_role(person_params, user) }
  let(:primary_person) { consumer_role.person }
  let(:active_verified_household) { verified_family.households.select{|h| h.integrated_case_id == verified_family.integrated_case_id}.first }
  let(:verified_tax_household) { active_verified_household.tax_households.select{|th| th.id == th.primary_applicant_id && th.primary_applicant_id == verified_primary_family_member.id.split('#').last }.first }
  let(:verified_primary_tax_household_member) { verified_tax_household.tax_household_members.select{|thm| thm.id == verified_primary_family_member.id }.first }
  let(:household) {primary_person.primary_family.active_household}
  let(:hbx_profile) {double}
  let(:benefit_sponsorship) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, current_benefit_coverage_period: bcp) }
  let(:bcp) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, slcsp: slcsp_plan, slcsp_id: slcsp_plan.id) }
  let(:slcsp_plan) { FactoryGirl.build(:plan) }


  context "build_or_update_tax_household_from_primary - Tests the creation of Tax Houshold and the Primary Tax Houshold Member" do
    before :each do
      allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
      allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
      allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(bcp)
      allow(bcp).to receive(:slcsp).and_return(slcsp_plan.id)
      allow(bcp).to receive(:slcsp_id).and_return(slcsp_plan.id)
    end

    it "should create a new tax_household" do
      expect(primary_person.primary_family.active_household.tax_households.size).to eq 0
      household.build_or_update_tax_household_from_primary(verified_primary_family_member, primary_person, active_verified_household)
      expect(primary_person.primary_family.active_household.tax_households.size).to eq 1
    end

    it "should create tax_household_members with a primary (subscriber) family member" do
      household.build_or_update_tax_household_from_primary(verified_primary_family_member, primary_person, active_verified_household)
      expect(primary_person.primary_family.active_household.latest_active_tax_household.tax_household_members.size).to eq 1
      expect(primary_person.primary_family.active_household.latest_active_tax_household.tax_household_members.first.person).to eq primary_person
    end

    it "should populate the is_ia_eligible as read from the active_verified_houshold" do
      household.build_or_update_tax_household_from_primary(verified_primary_family_member, primary_person, active_verified_household)
      expect(primary_person.primary_family.active_household.latest_active_tax_household.tax_household_members.first.is_ia_eligible).to eq verified_primary_tax_household_member.is_insurance_assistance_eligible
    end

    it "should populate the is_medicaid_chip_eligible as read from the active_verified_houshold" do
      household.build_or_update_tax_household_from_primary(verified_primary_family_member, primary_person, active_verified_household)
      expect(primary_person.primary_family.active_household.latest_active_tax_household.tax_household_members.first.is_medicaid_chip_eligible).to eq verified_primary_tax_household_member.is_medicaid_chip_eligible
    end
  end

  context "add_tax_household_family_member - Tests the creation of Tax Household Members for the dependents." do
    let(:verified_non_primary_tax_household_member) { verified_tax_household.tax_household_members.select{|thm| thm.id != verified_primary_family_member.id }.first }
    let(:person) { Person.new }
    let(:family_member) { FamilyMember.new(is_primary_applicant: false, person: person) }
    before :each do
      allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
      allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
      allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(bcp)
      allow(bcp).to receive(:slcsp).and_return(slcsp_plan.id)
      allow(bcp).to receive(:slcsp_id).and_return(slcsp_plan.id)
      household.build_or_update_tax_household_from_primary(verified_primary_family_member, primary_person, active_verified_household) # this has to happen before!
    end
    it "should create tax_household_members with a non primary (non subscriber) family member" do
      expect(primary_person.primary_family.active_household.latest_active_tax_household.tax_household_members.size).to eq 1
      household.add_tax_household_family_member(family_member, verified_non_primary_tax_household_member)
      expect(primary_person.primary_family.active_household.latest_active_tax_household.tax_household_members.size).to eq 2
      expect(primary_person.primary_family.active_household.latest_active_tax_household.tax_household_members.last.is_subscriber).to eq false
    end

    it "should populate the is_ia_eligible as read from the active_verified_houshold" do
      household.add_tax_household_family_member(family_member, verified_non_primary_tax_household_member)
      expect(primary_person.primary_family.active_household.latest_active_tax_household.tax_household_members.last.is_ia_eligible).to eq verified_primary_tax_household_member.is_insurance_assistance_eligible
    end

    it "should populate the is_medicaid_chip_eligible as read from the active_verified_houshold" do
      household.add_tax_household_family_member(family_member, verified_non_primary_tax_household_member)
      expect(primary_person.primary_family.active_household.latest_active_tax_household.tax_household_members.last.is_medicaid_chip_eligible).to eq verified_primary_tax_household_member.is_medicaid_chip_eligible
    end
  end
end

describe Household, "for dependent with domestic partner relationship", type: :model, dbclean: :after_each do
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
  let(:person) do
    p = FactoryGirl.build(:person)
    p.person_relationships.build(relative: person_two, kind: "domestic_partner")
    p.save
    p
  end
  let(:person_two)  { FactoryGirl.create(:person)}
  let(:family_member) { FactoryGirl.create(:family_member, family: family, person: person_two)}
  before(:each) do
    family.relate_new_member(person_two, "domestic_partner")
    family.save!
  end
  it "should have the extended family member in the extended coverage household" do
     immediate_coverage_members = family.active_household.immediate_family_coverage_household.coverage_household_members
     expect(immediate_coverage_members.length).to eq 2
  end
end

describe "multiple taxhouseholds for a family", type: :model, dbclean: :after_each do
  let!(:person) { FactoryGirl.create(:person, :with_family) }
  let!(:household) { person.primary_family.households.first }
  let!(:tax_household1) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-2, 1, 1), is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household2) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-2, 11, 1), is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household3) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-2, 6, 1), is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household4) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-1, 7, 1), created_at: "2018-01-15 21:53:54 UTC", is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household5) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-1, 4, 1), is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household6) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-1, 8, 1), created_at: "2018-01-15 21:53:50 UTC", is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household7) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-1, 1, 1), is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household8) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year, 1, 1), is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household9) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year, 1, 15), created_at: "2018-01-15 21:53:54 UTC", submitted_at: "2018-01-16 21:53:52 UTC", is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household10) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year, 1, 15), created_at: "2018-01-15 21:53:55 UTC", submitted_at: "2018-01-15 21:53:52 UTC", is_eligibility_determined: true, effective_ending_on: nil) }
  let!(:tax_household11) { FactoryGirl.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year, 1, 5), is_eligibility_determined: true, effective_ending_on: nil) }


  it "should have only one active tax household for year 2018" do
    household.end_multiple_thh
    expect(household.tax_households.tax_household_with_year(TimeKeeper.date_of_record.year).active_tax_household.count).to be 1
  end

  it "should have only one active tax household for year 2017" do
    household.end_multiple_thh
    expect(household.tax_households.tax_household_with_year(TimeKeeper.date_of_record.year-1).active_tax_household.count).to be 1
  end

  it "should have only one active tax household for year 2016" do
    household.end_multiple_thh
    expect(household.tax_households.tax_household_with_year(TimeKeeper.date_of_record.year-2).active_tax_household.count).to be 1
  end

  it "should be the latest one in the year 2018" do
    latest_active_thh = household.latest_active_thh_with_year(TimeKeeper.date_of_record.year)
    expect(latest_active_thh).to be tax_household11
    household.end_multiple_thh
    latest_active_thh = household.latest_active_thh_with_year(TimeKeeper.date_of_record.year)
    expect(latest_active_thh).to be tax_household11
  end

  it "should be the latest one in the year 2017" do
    latest_active_thh = household.latest_active_thh_with_year(TimeKeeper.date_of_record.year-1)
    expect(latest_active_thh).to be tax_household7
    household.end_multiple_thh
    latest_active_thh = household.latest_active_thh_with_year(TimeKeeper.date_of_record.year-1)
    expect(latest_active_thh).to be tax_household7
  end
end

describe "financial assistance eligibiltiy for a family", type: :model, dbclean: :after_each do
  let!(:person) { FactoryGirl.create(:person, :with_family) }
  let!(:active_household) { person.primary_family.active_household }
  let!(:date) { Date.new(TimeKeeper.date_of_record.year, 1, 1) }
  let!(:hbx_profile) { FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period) }
  let!(:slcsp) { HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.slcsp_id }

  it "should create one active tax household for the specified year" do
    expect(active_household.tax_households.count).to be 0
    active_household.build_thh_and_eligibility(60, 94, date, slcsp)
    expect(active_household.tax_households.count).to be 1
  end

  it "should create one eligibility determination for respective tax household" do
    active_household.build_thh_and_eligibility(200, 73, date, slcsp)
    expect(active_household.latest_active_thh.eligibility_determinations.count).to be 1
  end

  it "end dates all prior THH for the given year" do
    2.times {active_household.build_thh_and_eligibility(200, 73, date, slcsp)}
    expect(active_household.active_thh_with_year(TimeKeeper.date_of_record.year).count).to be 1
  end
end

describe Household, "for creating a new taxhousehold using create eligibility", type: :model, dbclean: :after_each do
  let!(:person100)      { FactoryGirl.create(:person) }
  let!(:family100)      { FactoryGirl.create(:family, :with_primary_family_member, person: person100) }
  let(:household100)    { family100.active_household }
  let!(:hbx_profile100) { FactoryGirl.create(:hbx_profile) }
  let(:current_date)    { TimeKeeper.date_of_record }
  let(:params)        {
                        {"person_id"=> person100.id.to_s,
                          "family_actions_id"=>"family_actions_#{family100.id.to_s}",
                          "max_aptc"=>"100.00",
                          "csr"=>"94",
                          "effective_date"=> "#{current_date.year}-#{current_date.month}-#{current_date.day}",
                          "family_members"=>
                            { family100.primary_applicant.person.hbx_id => {"pdc_type"=>"is_ia_eligible", "reason"=>"7hvgds"} }
                        }
                      }

  context "create_new_tax_household" do
    before :each do
      household100.create_new_tax_household(params)
    end

    it "should create new tax_household instance" do
      expect(household100.tax_households).not_to be []
    end

    it "should create new tax_household_member instance" do
      expect(household100.tax_households[0].tax_household_members).not_to be []
    end

    it "should create new eligibility_determination instance" do
      expect(household100.tax_households[0].eligibility_determinations).not_to be []
    end
  end
end

describe "build_or_update_tax_household_from_primary" do

  before do
    DatabaseCleaner.clean
  end

  let!(:hbx_profile) {FactoryGirl.create(:hbx_profile, :open_enrollment_coverage_period)}
  let!(:slcsp) {HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.slcsp_id}

  let(:message) {{"body" => xml}}
  let(:xml) {File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_4_member_family_sample2.xml"))}
  let(:user) {FactoryGirl.create(:user)}

  let(:parser) {Parsers::Xml::Cv::VerifiedFamilyParser.new.parse(xml).first}
  let(:primary) {parser.family_members.detect {|fm| fm.id == parser.primary_family_member_id}}
  let(:dependent) {parser.family_members.last}
  let!(:existing_dep) {Person.create(
      first_name: dependent.person.name_first,
      last_name: dependent.person.name_last,
      middle_name: dependent.person.name_middle,
      name_pfx: dependent.person.name_pfx,
      name_sfx: dependent.person.name_sfx,
      dob: dependent.person_demographics.birth_date,
      ssn: dependent.person_demographics.ssn == "999999999" ? "" : dependent.person_demographics.ssn,
      gender: dependent.person_demographics.sex.split('#').last
  )}
  let(:person) {consumer_role.person}
  let(:ua_params) do
    {
        addresses: [],
        phones: [],
        emails: [],
        person: {
            "first_name" => primary.person.name_first,
            "last_name" => primary.person.name_last,
            "middle_name" => primary.person.name_middle,
            "name_pfx" => primary.person.name_pfx,
            "name_sfx" => primary.person.name_sfx,
            "dob" => primary.person_demographics.birth_date,
            "ssn" => primary.person_demographics.ssn,
            "no_ssn" => "",
            "gender" => primary.person_demographics.sex.split('#').last
        }
    }
  end

  let!(:consumer_role) {Factories::EnrollmentFactory.construct_consumer_role(ua_params, user)}
  let!(:family_update) {consumer_role.person.primary_family.update_attributes(e_case_id: parser.integrated_case_id)}

  let!(:family_db) {consumer_role.person.primary_family}
  let!(:tax_household_db) {family_db.active_household.tax_households.first}

  let!(:tax_household2) {FactoryGirl.create(:tax_household, household: family_db.active_household, effective_starting_on: Date.new(2014, 9, 30), effective_ending_on: nil)}
  let!(:eligibility_determination2) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household2, max_aptc: {"cents" => 283.00, "currency_iso" => "USD"})}

  let!(:tax_household3) {FactoryGirl.create(:tax_household, household: family_db.active_household, effective_starting_on: Date.new(2014, 1, 30), effective_ending_on: nil)}
  let!(:eligibility_determination3) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household3, max_aptc: {"cents" => 283.00, "currency_iso" => "USD"})}

  let!(:person_db) {family_db.primary_applicant.person}
  let!(:consumer_role_db) {person_db.consumer_role}

  it "should have only one active tax household for year 2015" do
    active_household = family_db.active_household
    active_household.build_or_update_tax_household_from_primary(parser.family_members.first, person_db, parser.households.first)
    expect(active_household.tax_households.tax_household_with_year(2015).active_tax_household.count).to be 1
  end

  it "should not end 2014 active tax household when loading tax_household for 2015" do
    active_household = family_db.active_household
    active_household.build_or_update_tax_household_from_primary(parser.family_members.first, person_db, parser.households.first)
    expect(active_household.tax_households.tax_household_with_year(2014).active_tax_household.count).to be 2
  end
end
