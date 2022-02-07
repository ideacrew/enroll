# frozen_string_literal: true

require 'rails_helper'
Rake.application.rake_require "tasks/fix_atp_address_issues"
Rake::Task.define_task(:environment)

RSpec.describe 'migrations:fix_atp_address_issues', :type => :task, dbclean: :after_each do
  let(:person) { FactoryBot.create(:person, :with_consumer_role, hbx_id: "12345", addresses: [address1]) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:address1) do
    FactoryBot.build(
      :address,
      :address_1 => '1111 Awesome Street NE',
      :address_2 => '#111',
      :address_3 => '',
      :city => "Houlton",
      :country_name => '',
      :kind => 'home',
      :state => "ME",
      :zip => "04730",
      county: "Aroostook"
    )
  end
  let(:address2) do
    FactoryBot.build(
      :address,
      :address_1 => '1111 Awesome Street NE',
      :address_2 => '#111',
      :address_3 => '',
      :city => "Houlton",
      :country_name => '',
      :kind => 'mailing',
      :state => "ME",
      :zip => "04730",
      county: "Aroostook"
    )
  end
  let(:address3) do
    FactoryBot.build(
      :financial_assistance_address,
      :address_1 => '1111 Excellent Ave NW',
      :address_2 => '#111',
      :address_3 => '',
      :city => "Houlton",
      :country_name => '',
      :kind => 'mailing',
      :state => "ME",
      :zip => "04730",
      county: "Aroostook"
    )
  end
  let(:dup_addresses) {[address1, address2]}
  let(:dependent_person) { FactoryBot.create(:person, :with_consumer_role, is_homeless: true, addresses: dup_addresses) }
  let(:family_id) { family.id.to_s }
  let(:compare_keys) { ["address_1", "address_2", "city", "state", "zip"]}
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: "draft", transfer_id: "123278346237") }
  let!(:applicant1) { FactoryBot.create(:financial_assistance_applicant, application: application, person_hbx_id: person.hbx_id, is_primary_applicant: true, addresses: dup_addresses) }
  let!(:applicant2) { FactoryBot.create(:financial_assistance_applicant, application: application, person_hbx_id: dependent_person.hbx_id, is_primary_applicant: false, addresses: dup_addresses, is_homeless: true) }
  let(:create_dup_addresses) do
    person.addresses = [address1]
    person.save!
    dependent_person.addresses = [address1, address2]
    dependent_person.save!
    applicant1.addresses = [address1]
    applicant1.save!
    application.save!
    applicant2.addresses = dup_addresses
    applicant2.save!
    application.save!
  end
  let(:create_non_dup_addresses) do
    # Applicant addresses are updated via callbacks
    person.addresses = [address1, address3]
    person.save!    
  end
  let(:rake) {Rake::Task["migrations:fix_atp_address_issues"]}

  context "Rake task" do
    before do
      rake.reenable
      create_dup_addresses
      expect(applicant2.addresses.first.attributes.select {|k, _v| compare_keys.include? k}).to eq(applicant2.addresses.last.attributes.select {|k, _v| compare_keys.include? k})
      expect(applicant2.same_with_primary).to eq(false)
      expect(applicant2.is_homeless).to eq(true)
    end

    it "update the person and applicants with homeless true but with a home address" do
      rake.invoke
      @applicant2 = applicant2.reload
      @dperson = dependent_person.reload
      expect(@dperson.is_homeless).to eq(false)
      expect(@applicant2.is_homeless).to eq(false)
    end

    it "update the person and applicants with duplicate home and mailing addresses" do
      rake.invoke
      dependent_person.reload
      applicant2.reload
      expect(dependent_person.addresses.select{|a| a[:kind] == "mailing"}.count).to eq(0)
      expect(applicant2.addresses.select{|a| a[:kind] == "mailing"}.count).to eq(0)
    end

    it "update the applicants same as primary indicator" do
      rake.invoke
      dependent_person.reload
      applicant2.reload
      expect(applicant2.same_with_primary).to eq(true)
    end

    context "non-duplicate addresses" do
      it "should not update the person addresses" do
        create_non_dup_addresses
        person.reload
        original_addresses = person.addresses
        rake.invoke
        person.reload        
        expect(person.addresses).to eq(original_addresses)
      end
      
      it "should not update the applicant addresses" do
        create_non_dup_addresses
        applicant1.reload
        original_addresses = applicant1.addresses
        rake.invoke
        applicant1.reload
        expect(applicant1.addresses).to eq(original_addresses)
      end
    end
  end
end