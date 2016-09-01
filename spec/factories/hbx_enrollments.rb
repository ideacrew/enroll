FactoryGirl.define do
  factory :hbx_enrollment do
    household
    kind "employer_sponsored"
    elected_premium_credit 0
    applied_premium_credit 0
    effective_on {1.month.ago.to_date}
    terminated_on nil
    waiver_reason "this is the reason"
    # broker_agency_id nil
    # writing_agent_id nil
    submitted_at {2.months.ago}
    aasm_state "coverage_selected"
    aasm_state_date {effective_on}
    updated_by "factory"
    is_active true
    enrollment_kind "open_enrollment"
    # hbx_enrollment_members
    # comments

    transient do
      enrollment_members []
      active_year TimeKeeper.date_of_record.year
    end

    plan { create(:plan, :with_premium_tables, active_year: active_year) }

    trait :with_enrollment_members do 
      hbx_enrollment_members { enrollment_members.map{|member| FactoryGirl.build(:hbx_enrollment_member, applicant_id: member.id, hbx_enrollment: self, is_subscriber: member.is_primary_applicant, coverage_start_on: self.effective_on, eligibility_date: self.effective_on) }}
    end
  end
end
