# frozen_string_literal: true

require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_consumer_role_verification_status")

describe UpdateConsumerRoleVerificationStatus, dbclean: :after_each do
  let(:given_task_name) { "update_consumer_role_verification_status" }
  let(:person) { FactoryBot.create(:person, :with_active_consumer_role, :with_consumer_role)}
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:coverage_household) { family.households.first.coverage_households.first }
  let(:hbx_profile) {FactoryBot.create(:hbx_profile)}
  let(:verification_attr) { OpenStruct.new({ :determined_at => Time.zone.now, :vlp_authority => "hbx" })}
  let(:active_year) {TimeKeeper.date_of_record.year}
  let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}
  let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
  let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }
  let(:benefit_package) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first }
  let(:enrollment) do
    enrollment = family.latest_household.new_hbx_enrollment_from(
      consumer_role: person.consumer_role,
      coverage_household: coverage_household,
      benefit_package: benefit_package,
      qle: true
    )
    enrollment.save
    enrollment
  end
  let(:consumer_role) { enrollment.hbx_enrollment_members.flat_map(&:person).flat_map(&:consumer_role).first }


  before :each do
    allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
    allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
    allow(enrollment).to receive(:product).and_return product
    allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
    enrollment.select_coverage!
    consumer_role.update!(aasm_state: "verification_outstanding")
    enrollment.update!(is_any_enrollment_member_outstanding: true)
  end

  subject { UpdateConsumerRoleVerificationStatus.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update_open_enrollment_dates" do
    it "update consumer_role aasm state" do
      consumer_role.verification_types.each {|type| type.update!(validation_status: "verified")}
      expect(consumer_role.reload.aasm_state).to eq "verification_outstanding"

      subject.migrate
      expect(consumer_role.reload.aasm_state).to eq "fully_verified"
      expect(enrollment.reload.is_any_enrollment_member_outstanding).to eq false
    end

  end
end
