# frozen_string_literal: true

RSpec.shared_context 'valid cv3 application setup', :shared_context => :metadata do
  let(:person) { FactoryBot.create(:person, :with_consumer_role, hbx_id: '100095') }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:has_enrolled_health_coverage) { true }
  let(:is_primary_applicant) { true }

  let(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: 'submitted', hbx_id: "830293", effective_date: TimeKeeper.date_of_record.beginning_of_year) }
  let(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application, max_aptc: 0) }
  let!(:applicant) do
    applicant = FactoryBot.create(:financial_assistance_applicant,
                                  :with_student_information,
                                  :with_home_address,
                                  application: application,
                                  is_primary_applicant: is_primary_applicant,
                                  ssn: '889984400',
                                  dob: Date.new(1994,11,17),
                                  first_name: person.first_name,
                                  last_name: person.last_name,
                                  gender: person.gender,
                                  person_hbx_id: person.hbx_id,
                                  eligibility_determination_id: eligibility_determination.id,
                                  has_enrolled_health_coverage: has_enrolled_health_coverage)
    applicant
  end

  let(:premiums_hash) do
    { [person.hbx_id] => {:health_only => {person.hbx_id => [{:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}]}} }
  end

  let(:slcsp_info) do
    { person.hbx_id => {:health_only_slcsp_premiums => {:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}} }
  end

  let(:lcsp_info) do
    { person.hbx_id => {:health_only_lcsp_premiums => {:cost => 100.0, :member_identifier => person.hbx_id, :monthly_premium => 100.0}} }
  end

  let(:premiums_double) { double(:success => premiums_hash) }
  let(:slcsp_double) { double(:success => slcsp_info) }
  let(:lcsp_double) { double(:success => lcsp_info) }

  let(:fetch_double) { double(:new => double(call: premiums_double)) }
  let(:fetch_slcsp_double) { double(:new => double(call: slcsp_double)) }
  let(:fetch_lcsp_double) { double(:new => double(call: lcsp_double)) }

  let(:hbx_profile) { FactoryBot.create(:hbx_profile) }
  let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
  let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }

  before do
    allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_application_errors).and_return(true)

    allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
    allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
    allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
    stub_const('::Operations::Products::Fetch', fetch_double)
    stub_const('::Operations::Products::FetchSlcsp', fetch_slcsp_double)
    stub_const('::Operations::Products::FetchLcsp', fetch_lcsp_double)
    allow(premiums_double).to receive(:failure?).and_return(false)
    allow(slcsp_double).to receive(:failure?).and_return(false)
    allow(lcsp_double).to receive(:failure?).and_return(false)

    # More types of applicant evidences can be added here for future tests
    applicant.create_income_evidence(
      key: :income,
      title: 'Income',
      aasm_state: :pending,
      due_on: TimeKeeper.date_of_record,
      verification_outstanding: true,
      is_satisfied: false
    )
  end
end