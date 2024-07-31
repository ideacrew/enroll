# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Fdsh::Dmf::Pvc::AddFamilyDetermination, dbclean: :after_each do
  let(:person) do
    p = FactoryBot.create(:person, :with_consumer_role, hbx_id: cv3_family_payload[:family_members][0][:person][:hbx_id])
    p.update_attributes(ssn: cv3_family_payload[:family_members][0][:person][:person_demographics][:ssn])
    p
  end
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, hbx_assigned_id: cv3_family_payload[:hbx_id], person: person) }
  let(:job) { FactoryBot.create(:transmittable_job, :dmf_determination) }
  let(:file_data) { File.read("spec/test_data/dmf_payloads/dmf_response_cv_payload.json") }
  let(:cv3_family_payload) { JSON.parse(JSON.parse(file_data),symbolize_names: true)  }
  let(:encrypted_family_payload) { AcaEntities::Operations::Encryption::Encrypt.new.call(value: JSON.parse(file_data)).value! }

  before do
    allow(EnrollRegistry[:alive_status].feature).to receive(:is_enabled).and_return(true)
    person.build_demographics_group
  end

  context "when member is not enrolled" do
    before do
      @result = described_class.new.call({encrypted_family_payload: encrypted_family_payload, job_id: job.job_id, family_hbx_id: family.hbx_assigned_id})
      person.reload
      family.reload
    end

    it "should set the verification status to NRR" do
      alive_status = person.demographics_group.alive_status
      alive_status_type = person.verification_types.last
      expect(@result).to be_success
      expect(alive_status_type.validation_status).to eq("negative_response_received")
      expect(alive_status.is_deceased).to be_truthy
      expect(alive_status.date_of_death.present?).to be_truthy
    end

    it "should set the family eligibility determination objects" do
      expect(family.eligibility_determination.outstanding_verification_status).to eq("not_enrolled")
      expect(family.eligibility_determination.subjects[0].eligibility_states[1].evidence_states.last.status).to eq(:negative_response_received)
    end
  end

  context "when member is enrolled" do
    let(:hbx_enrollment_member) do
      FactoryBot.build(:hbx_enrollment_member,
                       is_subscriber: true,
                       applicant_id: family.family_members.first.id,
                       coverage_start_on: TimeKeeper.date_of_record.beginning_of_month,
                       eligibility_date: TimeKeeper.date_of_record.beginning_of_month)
    end

    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, metal_level_kind: :silver, benefit_market_kind: :aca_individual) }
    let!(:enrollment) do
      hbx_enrollment = FactoryBot.create(:hbx_enrollment,
                                         product: product,
                                         family: family,
                                         household: family.active_household,
                                         hbx_enrollment_members: [hbx_enrollment_member],
                                         aasm_state: "coverage_selected",
                                         kind: "individual",
                                         effective_on: TimeKeeper.date_of_record,
                                         rating_area_id: person.consumer_role.rating_address.id,
                                         consumer_role_id: person.consumer_role.id)
      hbx_enrollment.save!
      hbx_enrollment
    end

    before do
      @result = described_class.new.call({encrypted_family_payload: encrypted_family_payload, job_id: job.job_id, family_hbx_id: family.hbx_assigned_id})
      person.reload
      family.reload
      @alive_status = person.demographics_group.alive_status
      @alive_status_type = person.verification_types.alive_status_type.last
      @type_history_element = @alive_status_type.type_history_elements.first
    end

    it "should set the verification status to outstanding" do
      expect(@result).to be_success
      expect(@alive_status_type.validation_status).to eq("outstanding")
      expect(@alive_status.is_deceased).to be_truthy
      expect(@alive_status.date_of_death.present?).to be_truthy
    end

    it "should set verification history" do
      expect(@alive_status_type.type_history_elements.count).to eq(1)
      expect(@type_history_element.action).to eq("DMF Hub Response")
      expect(@type_history_element.from_validation_status).to eq("unverified")
      expect(@type_history_element.to_validation_status).to eq("outstanding")
      expect(person.consumer_role.alive_status_responses.count).to eq(1)
      expect(JSON.parse(person.consumer_role.alive_status_responses.first.body)).to eq({"job_id" => job.job_id, "family_hbx_id" => family.hbx_assigned_id.to_s, "death_confirmation_code" => "Confirmed", "date_of_death" => "2024-07-03"})
      expect(person.consumer_role.alive_status_responses.first.id.to_s).to eq(@type_history_element.event_response_record_id)
    end

    it "should set the family eligibility determination objects" do
      expect(family.eligibility_determination.outstanding_verification_status).to eq("outstanding")
      expect(family.eligibility_determination.subjects[0].eligibility_states[1].evidence_states.last.status).to eq(:outstanding)
    end
  end
end