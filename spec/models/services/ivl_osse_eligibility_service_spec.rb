# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Services::IvlOsseEligibilityService, type: :model, :dbclean => :after_each do
  let!(:hbx_profile) {FactoryBot.create(:hbx_profile)}
  let!(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
  let!(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }
  let(:catalog_eligibility) do
    Operations::Eligible::CreateCatalogEligibility.new.call(
      {
        subject: benefit_coverage_period.to_global_id,
        eligibility_feature: "aca_ivl_osse_eligibility",
        effective_date: benefit_coverage_period.start_on.to_date,
        domain_model: "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
      }
    )
  end
  let(:person) { FactoryBot.create(:person, :with_consumer_role)}
  let(:role) { person.consumer_role }
  let(:current_date) { TimeKeeper.date_of_record }
  let!(:system_user) { FactoryBot.create(:user, email: "admin@dc.gov") }
  let(:params) { { person_id: person.id, osse: { current_date.year.to_s => "true", current_date.last_year.year.to_s => "false" } } }
  let(:trackable_event_instance) { Operations::EventLogs::TrackableEvent.new}

  subject { described_class.new(params) }

  before do
    allow(EnrollRegistry).to receive(:feature_enabled?).and_return(true)
    allow(trackable_event_instance).to receive(:publish).and_return(Dry::Monads::Success(true))
    allow(Operations::EventLogs::TrackableEvent).to receive(:new).and_return(trackable_event_instance)
    catalog_eligibility
  end

  describe "#osse_eligibility_years_for_display" do
    it "returns sorted and reversed osse eligibility years" do
      expect(subject.osse_eligibility_years_for_display).to eq(
        ::BenefitCoveragePeriod.osse_eligibility_years_for_display.sort.reverse
      )
    end
  end

  describe "#osse_status_by_year" do
    before do
      osse_eligibility_years = [current_date.year, current_date.last_year.year, current_date.next_year.year]
      allow(BenefitCoveragePeriod).to receive(:osse_eligibility_years_for_display).and_return osse_eligibility_years
      ::Operations::IvlOsseEligibilities::CreateIvlOsseEligibility.new.call(
        {
          subject: role.to_global_id,
          evidence_key: :ivl_osse_evidence,
          evidence_value: "true",
          effective_date: TimeKeeper.date_of_record.beginning_of_year
        }
      )
    end

    it "returns osse status by year" do
      result = subject.osse_status_by_year
      expect(result[current_date.last_year.year][:is_eligible]).to eq(false)
      expect(result[current_date.next_year.year][:is_eligible]).to eq(false)
      expect(result[current_date.year][:is_eligible]).to eq(true)
      expect(result[current_date.year][:start_on]).to eq(current_date.beginning_of_year)
      expect(result[current_date.year][:end_on]).to eq(current_date.end_of_year)
    end
  end

  describe "#update_osse_eligibilities_by_year" do
    it "updates osse eligibilities by year" do
      allow(subject).to receive(:store_osse_eligibility).and_return(double("eligibility", success?: true))

      result = subject.update_osse_eligibilities_by_year

      expect(result).to eq({ "Success" => [current_date.year.to_s]})
    end

    context "when the year is more than 1 year old" do
      let(:old_year) { TimeKeeper.date_of_record.year - 2 }
      let(:params_1) { {person_id: person.id, osse: { old_year.to_s => "true" } } }
      let(:subject_1) { described_class.new(params_1) }

      it "should not update osse eligibility" do
        result = subject_1.update_osse_eligibilities_by_year
        expect(result).to eq({ "Failure" => [old_year.to_s]})
      end
    end
  end

  describe "#store_osse_eligibility" do
    it "persist osse eligibility" do
      result = subject.store_osse_eligibility(role, "true", TimeKeeper.date_of_record)

      expect(result.success?).to be_truthy
      expect(result.success.effective_on).to eq TimeKeeper.date_of_record.beginning_of_year
    end

    it "returns Failure if operation fails" do
      result = subject.store_osse_eligibility(role, "", TimeKeeper.date_of_record)

      expect(result.success?).to be_falsy
    end
  end
end
