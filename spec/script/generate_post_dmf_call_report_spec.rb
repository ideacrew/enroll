# frozen_string_literal: true

require 'rails_helper'

describe 'generate post dmf call report' do
  include Dry::Monads[:result, :do]

  before do
    allow(EnrollRegistry[:alive_status].feature).to receive(:is_enabled).and_return(true)
    DatabaseCleaner.clean
  end

  context 'for a valid job with families' do
    let(:person) do
      p = FactoryBot.create(:person, :with_consumer_role, hbx_id: cv3_family_payload[:family_members][0][:person][:hbx_id])
      p.update_attributes(ssn: cv3_family_payload[:family_members][0][:person][:person_demographics][:ssn])
      p
    end
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, hbx_assigned_id: cv3_family_payload[:hbx_id], person: person) }
    let(:person2) do
      p2 = FactoryBot.create(:person, :with_consumer_role, hbx_id: cv3_family_payload[:family_members][1][:person][:hbx_id])
      p2.update_attributes(ssn: cv3_family_payload[:family_members][1][:person][:person_demographics][:ssn])
      FactoryBot.create(:family_member, person: p2, family: family)
      p2
    end

    let(:person3) do
      p3 = FactoryBot.create(:person, :with_consumer_role, hbx_id: cv3_family2_payload[:family_members][0][:person][:hbx_id])
      p3.update_attributes(ssn: cv3_family2_payload[:family_members][0][:person][:person_demographics][:ssn])
      p3
    end
    let(:family2) { FactoryBot.create(:family, :with_primary_family_member, hbx_assigned_id: cv3_family2_payload[:hbx_id], person: person3) }
    let(:person4) do
      p4 = FactoryBot.create(:person, :with_consumer_role, hbx_id: cv3_family2_payload[:family_members][1][:person][:hbx_id])
      p4.update_attributes(ssn: cv3_family2_payload[:family_members][1][:person][:person_demographics][:ssn])
      FactoryBot.create(:family_member, person: p4, family: family2)
      p4
    end

    let(:job) { FactoryBot.create(:transmittable_job, :dmf_determination) }
    let(:date) { TimeKeeper.date_of_record }
    let(:file_name)  { "#{Rails.root}/post_dmf_call_report_for_job_#{job.job_id}.csv" }
    let(:file_data) { File.read("spec/test_data/dmf_response_cv_payload.json") }
    let(:cv3_family_payload) { JSON.parse(JSON.parse(file_data),symbolize_names: true)  }
    let!(:cv3_family2_payload) do
      payload2 = JSON.parse(JSON.parse(file_data),symbolize_names: true)
      payload2[:hbx_id] = '786139'
      payload2[:family_members][0][:person][:hbx_id] = '1000396'
      payload2[:family_members][1][:person][:hbx_id] = '1000498'
      payload2[:family_members][0][:person][:person_demographics][:ssn] = "345769237"
      payload2[:family_members][1][:person][:person_demographics][:ssn] = "345769234"
      payload2[:family_members][1][:person][:verification_types][0][:validation_status] = "attested"
      payload2
    end

    let(:encrypted_family_payload) { AcaEntities::Operations::Encryption::Encrypt.new.call(value: JSON.parse(file_data)).value! }
    let(:encrypted_family2_payload) { AcaEntities::Operations::Encryption::Encrypt.new.call(value: cv3_family2_payload.to_json).value! }

    let(:hbx_enrollment_member) do
      FactoryBot.build(:hbx_enrollment_member,
                       is_subscriber: true,
                       applicant_id: family.family_members.first.id,
                       coverage_start_on: TimeKeeper.date_of_record.beginning_of_month,
                       eligibility_date: TimeKeeper.date_of_record.beginning_of_month)
    end

    let(:hbx_enrollment_member2) do
      person2
      FactoryBot.build(:hbx_enrollment_member,
                       is_subscriber: true,
                       applicant_id: family.family_members[1].id,
                       coverage_start_on: TimeKeeper.date_of_record.beginning_of_month,
                       eligibility_date: TimeKeeper.date_of_record.beginning_of_month)
    end

    let(:hbx_enrollment_member3) do
      FactoryBot.build(:hbx_enrollment_member,
                       is_subscriber: true,
                       applicant_id: family2.family_members[0].id,
                       coverage_start_on: TimeKeeper.date_of_record.beginning_of_month,
                       eligibility_date: TimeKeeper.date_of_record.beginning_of_month)
    end
    let(:hbx_enrollment_member4) do
      person4
      FactoryBot.build(:hbx_enrollment_member,
                       is_subscriber: true,
                       applicant_id: family2.family_members[1].id,
                       coverage_start_on: TimeKeeper.date_of_record.beginning_of_month,
                       eligibility_date: TimeKeeper.date_of_record.beginning_of_month)
    end

    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, metal_level_kind: :silver, benefit_market_kind: :aca_individual) }
    let!(:enrollment) do
      hbx_enrollment = FactoryBot.create(:hbx_enrollment,
                                         product: product,
                                         family: family,
                                         household: family.active_household,
                                         hbx_enrollment_members: [hbx_enrollment_member, hbx_enrollment_member2],
                                         aasm_state: "coverage_selected",
                                         kind: "individual",
                                         effective_on: TimeKeeper.date_of_record,
                                         rating_area_id: person.consumer_role.rating_address.id,
                                         consumer_role_id: person.consumer_role.id)
      hbx_enrollment.save!
      hbx_enrollment
    end

    let!(:enrollment2) do
      hbx_enrollment = FactoryBot.create(:hbx_enrollment,
                                         product: product,
                                         family: family2,
                                         household: family2.active_household,
                                         hbx_enrollment_members: [hbx_enrollment_member3, hbx_enrollment_member4],
                                         aasm_state: "coverage_selected",
                                         kind: "individual",
                                         effective_on: TimeKeeper.date_of_record,
                                         rating_area_id: person3.consumer_role.rating_address.id,
                                         consumer_role_id: person3.consumer_role.id)
      hbx_enrollment.save!
      hbx_enrollment
    end

    let!(:eligibility_determination_current) do
      determination = family.create_eligibility_determination(effective_date: date.beginning_of_year)

      family.family_members.each do |family_member|
        subject = determination.subjects.create(
          gid: "gid://enroll/FamilyMember/#{family_member.id}",
          is_primary: family_member.is_primary_applicant,
          person_id: family_member.person.id
        )

        subject.eligibility_states.create(eligibility_item_key: 'health_product_enrollment_status', is_eligible: true)
      end

      determination.subjects[0].update(hbx_id: person.hbx_id, encrypted_ssn: "Ih3m7vvmvWg7qcf1N6B6Hw==\n")
      determination.subjects[1].update(hbx_id: person2.hbx_id, encrypted_ssn: "Ih3m7vvmvWg7qcf1N6B6Hq==\n")
      determination
    end

    let!(:eligibility_determination2_current) do
      determination = family2.create_eligibility_determination(effective_date: date.beginning_of_year)

      family2.family_members.each do |family_member|
        subject = determination.subjects.create(
          gid: "gid://enroll/FamilyMember/#{family_member.id}",
          is_primary: family_member.is_primary_applicant,
          person_id: family_member.person.id
        )

        subject.eligibility_states.create(eligibility_item_key: 'health_product_enrollment_status', is_eligible: true)
      end

      determination.subjects[0].update(hbx_id: person3.hbx_id, encrypted_ssn: "Ih3m7vvmvWg7qcf1N6B6Hm==\n")
      determination.subjects[1].update(hbx_id: person4.hbx_id, encrypted_ssn: "Ih3m7vvmvWg7qcf1N6B6Hn==\n")
      determination
    end

    let(:response_payload) do
      {
        encrypted_family_payload: encrypted_family_payload,
        job_id: job.job_id,
        family_hbx_id: family.hbx_assigned_id
      }
    end

    let(:response_payload2) do
      {
        encrypted_family_payload: encrypted_family2_payload,
        job_id: job.job_id,
        family_hbx_id: family2.hbx_assigned_id
      }
    end

    let(:field_names) do
      [
        "Family Hbx ID",
        "Person Hbx ID",
        "Enrollment Status",
        "Before DMF call deceased verification state",
        "After DMF call deceased verification state"
      ]
    end

    let(:encrypted_ssn_validator) { double(AcaEntities::Operations::EncryptedSsnValidator) }

    before do
      allow(AcaEntities::Operations::EncryptedSsnValidator).to receive(:new).and_return(encrypted_ssn_validator)
      allow(encrypted_ssn_validator).to receive(:call).and_return(Success('success'))

      persons = [person, person2, person3, person4]
      persons.each do |demo_person|
        demo_person.build_demographics_group
        demo_person.save!
      end

      Operations::Fdsh::Dmf::Pvc::AddFamilyDetermination.new.call(response_payload)
      Operations::Fdsh::Dmf::Pvc::AddFamilyDetermination.new.call(response_payload2)
      persons.each(&:reload)
      family.reload
      family2.reload
      job.reload

      invoke_generate_post_dmf_call_report(job.job_id)
      @file_content = CSV.read(file_name)
    end

    it 'should add data to the file' do
      expect(@file_content.size).to be > 1
    end

    it 'should contain the requested fields' do
      expect(@file_content[0]).to eq(field_names)
    end

    it 'should contain dmf call results for individual consumers' do
      consumer_content = [
        family.hbx_assigned_id.to_s,
        person.hbx_id,
        enrollment.aasm_state,
        'unverified',
        'outstanding'
      ]

      expect(@file_content[1]).to eq(consumer_content)
    end

    after do
      FileUtils.rm_rf(file_name)
    end
  end

  context 'when no job exists' do
    let(:job_id) { '12345' }

    before do
      invoke_generate_post_dmf_call_report(job_id)
    end

    it 'does not generate a file' do
      file_name = "#{Rails.root}/post_dmf_call_report_for_job_#{job_id}.csv"
      expect(File).to_not exist(file_name)
    end
  end

  context 'when a job has no relevant transactions' do
    let(:job) { FactoryBot.create(:transmittable_job, :dmf_determination) }

    before do
      invoke_generate_post_dmf_call_report(job.job_id)
    end

    it 'does not generate a file' do
      file_name = "#{Rails.root}/post_dmf_call_report_for_job_#{job.job_id}.csv"
      expect(File).to_not exist(file_name)
    end
  end
end

def invoke_generate_post_dmf_call_report(job_id)
  ARGV[0] = job_id
  post_dmf_call_report = File.join(Rails.root, "script/generate_post_dmf_call_report.rb")
  load post_dmf_call_report
end
