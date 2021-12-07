# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Transformers::FamilyTo::Cv3Family, dbclean: :after_each do
  let(:primary_applicant) { FactoryBot.create(:person, hbx_id: "732020") }
  let(:dependent1) { FactoryBot.create(:person, hbx_id: "732021") }
  let(:dependent2) { FactoryBot.create(:person, hbx_id: "732022") }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: primary_applicant) }
  let(:family_member2) { FactoryBot.create(:family_member, family: family, person: dependent1) }
  let(:family_member3) { FactoryBot.create(:family_member, family: family, person: dependent2) }
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: 'submitted', hbx_id: "830293", effective_date: DateTime.new(2021,1,1,4,5,6)) }
  let!(:applicant1) { FactoryBot.create(:financial_assistance_applicant, application: application, family_member_id: primary_applicant.id, is_primary_applicant: true, person_hbx_id: primary_applicant.hbx_id) }
  let!(:applicant2) { FactoryBot.create(:financial_assistance_applicant, application: application, family_member_id: family_member2.id, person_hbx_id: dependent1.hbx_id) }
  let!(:applicant3) { FactoryBot.create(:financial_assistance_applicant, application: application, family_member_id: family_member3.id, person_hbx_id: dependent2.hbx_id) }
  let(:create_instate_addresses) do
    application.applicants.each do |appl|
      appl.addresses = [FactoryBot.build(:financial_assistance_address,
                                         :address_1 => '1111 Awesome Street NE',
                                         :address_2 => '#111',
                                         :address_3 => '',
                                         :city => 'Washington',
                                         :country_name => '',
                                         :kind => 'home',
                                         :state => FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
                                         :zip => '20001',
                                         county: '')]
      appl.save!
    end
    application.save!
  end
  let(:create_relationships) do
    application.applicants.first.update_attributes!(is_primary_applicant: true) unless application.primary_applicant.present?
    application.ensure_relationship_with_primary(applicant2, 'child')
    application.ensure_relationship_with_primary(applicant3, 'child')
    application.build_relationship_matrix
    application.save!
  end

  describe '#transform_applications' do

    subject { FinancialAssistance::Operations::Transformers::FamilyTo::Cv3Family.new.transform_applications(family) }
    before do
      create_instate_addresses
      create_relationships
      application.save!
      allow(::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application).to receive_message_chain('new.call').with(application).and_return(::Dry::Monads::Result::Success.new(application))
    end

    context "when all applicants are valid" do

      it "should successfully submit a cv3 application and get a response back" do
        expect(subject).to include(application)
      end
    end

    context "when a family member is deleted" do
      before do
        family.family_members.last.delete
        family.reload
      end

      it "should ignore the application and return an empty array" do
        expect(subject).to be_empty
      end
    end
  end
end