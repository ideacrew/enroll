require 'rails_helper'

RSpec.describe CensusRoster, type: :model do
  it { should validate_presence_of :employer_profile_id }

  let(:employer_profile)  { FactoryGirl.create(:employer_profile) }
  let(:valid_params) do
    {
      employer_profile_id: employer_profile.id
    }
  end

  context ".new" do
    context "with no arguments" do
      let(:params)  { {} } 
      it "should not save" do
        expect(CensusRoster.new(**params).save).to be_falsey
      end
    end

    context "with no employer profile id" do
      let(:params)  { valid_params.except(:employer_profile_id) } 

      it "should fail validation " do
        expect(CensusRoster.create(**params).errors[:employer_profile_id].any?).to be_truthy
      end
    end

    context "with all valid arguments" do
      let(:params)  { valid_params } 
      let(:census_roster)  { CensusRoster.new(**params) } 

      it "should save" do
        expect(census_roster.save).to be_truthy
      end

      context "and it is saved" do
        let!(:saved_census_roster) do
          cr = census_roster
          cr.save
          cr
        end

        it "should be findable" do
          expect(CensusRoster.find(saved_census_roster.id)).to eq saved_census_roster
        end
      end
    end
  end

  context "employees are present on the census roster" do
    let(:owner_employee_count)      { 2 }
    let(:non_owner_employee_count)  { 5 }
    let(:total_employee_count)      { owner_employee_count + non_owner_employee_count }

    let(:owner_census_families)     { FactoryGirl.create_list(:census_families, owner_employee_count) }
    let(:non_owner_census_families) { FactoryGirl.create_list(:census_families, non_owner_employee_count) }
    let(:census_roster)   { FactoryGirl.create(:census_roster, employer_profile: employer_profile) }

    let(:valid_owner_participation_minimum)      { ShopEnrollmentNonOwnerParticipationMinimum }
    let(:invalid_owner_participation_minimum)    { ShopEnrollmentNonOwnerParticipationMinimum - 1 }
    let(:valid_participation_ratio_minimum)      { ShopEnrollmentParticipationRatioMinimum }
    let(:invalid_participation_ratio_minimum)    { ShopEnrollmentParticipationRatioMinimum - 0.01}

    before do
    end

    it "should calculate the number of employees eligible to enroll" do
      # expect(census_roster.eligible_to_enroll_count).to eq total_employee_count
    end

    it "and the number of employees who have enrolled" do
      # expect(census_roster.enrolled_count).to eq total_employee_count
    end

    it "and the enrollment ratio" do
      # expect(census_roster.enrollment_ratio).to eq enrollment_ratio
    end

    context "and employer non-owner participation is below minimum" do
      before do
      end

      it "enrollment should not be valid" do
        # expect(plan_year.is_enrollment_valid?).to be_falsey
      end

      it "and should provide relevent warning message" do
        # expect(plan_year.application_warnings[:non_owner_enrollment_count].present?).to be_truthy
        # expect(plan_year.application_warnings[:non_owner_enrollment_count]).to match(/non-owner employee must enroll/)
      end
    end

    context "and enrollment participation is below minimum" do
      before do
      end

      it "enrollment should not be valid" do
        # expect(plan_year.is_enrollment_valid?).to be_falsey
      end

      it "and should provide relevent warning message" do
        # expect(plan_year.application_warnings[:enrollment_ratio].present?).to be_truthy
        # expect(plan_year.application_warnings[:enrollment_ratio]).to match(/number of eligible participants enrolling/)
      end
    end

    context "and enrollment is in full compliance" do

      it "enrollment should be valid" do
        # expect(plan_year.is_enrollment_valid?).to be_falsey
      end
    end

  end
end
