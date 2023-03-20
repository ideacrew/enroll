# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Operations::FinancialAssistance::ParseApplicant, type: :model, dbclean: :after_each do
  let!(:person) do
    per = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)
    addi_attrs = { active_vlp_document_id: per.consumer_role.vlp_documents.first.id,
                   is_applying_coverage: true, five_year_bar_applies: true, five_year_bar_met: true }
    per.consumer_role.update_attributes!(addi_attrs)
    per.consumer_role.lawful_presence_determination.update!(qualified_non_citizenship_result: 'Y')
    per
  end
  let!(:family)        { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:family_member) { family.family_members[0] }
  let!(:person2) do
    per = FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 30.years)
    person.ensure_relationship_with(per, 'spouse')
    per.addresses.delete_all
    person.save!
    per
  end
  let!(:dependent) { FactoryBot.create(:family_member, family: family, person: person2) }
  let!(:hbx_profile)   { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period) }
  let(:product)        { FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product) }

  before :each do
    bcp = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
    bcp.update_attributes!(slcsp_id: product.id)
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'invalid arguments' do
    it 'should return a failure' do
      result = subject.call({family_member: 'family_member'})
      expect(result.failure).to eq('Given family member is not a valid object')
    end
  end

  context 'with valid arguments' do

    let!(:result)  { subject.call({family_member: family_member}) }

    it 'should return applicant hash' do
      expect(result.success.is_a?(Hash)).to be_truthy
    end

    it 'should return hash with member hbx_id' do
      expect(result.success[:person_hbx_id]).to eq person.hbx_id
    end

    it 'should return consumer_role related attributes' do
      result_hash = result.success
      expect(result_hash[:is_applying_coverage]).to eq(true)
      expect(result_hash[:five_year_bar_applies]).to eq(true)
      expect(result_hash[:five_year_bar_met]).to eq(true)
    end

    it 'should return qualified_non_citizen status' do
      expect(result.success[:qualified_non_citizen]).to eq(true)
    end

    it 'should return hash with is_homeless' do
      expect(result.success[:is_homeless]).to eq person.is_homeless
    end

    it 'should return hash with is_temporarily_out_of_state' do
      expect(result.success[:is_temporarily_out_of_state]).to eq person.is_temporarily_out_of_state
    end

    it 'should return hash with relationship' do
      expect(result.success[:relationship]).to eq 'self'
    end

    it 'should return hash with member hbx_id' do
      expect(result.success[:ssn]).to eq person.ssn
    end

    it 'should return hash with member dob' do
      expect(result.success[:dob]).to eq person.dob.strftime('%d/%m/%Y')
    end

    it 'should return hash with vlp expiration date in string format' do
      expect(result.success[:expiration_date]).to eq(person.consumer_role.active_vlp_document.expiration_date.strftime('%d/%m/%Y'))
    end

    it 'should return hash with vlp subject' do
      expect(result.success[:vlp_subject]).to eq(person.consumer_role.active_vlp_document.subject)
    end

    it 'should return hash with key vlp_description' do
      expect(result.success.keys).to include(:vlp_description)
    end
  end

  context 'when passed dependent with valid arguments' do
    context "when there is no home address" do
      it 'should return same_with_primary as false' do
        result = subject.call({family_member: dependent})
        expect(result.success[:same_with_primary]).to be_falsey
      end
    end

    context "when there is same home address as primary" do
      it 'should return same_with_primary as true' do
        dependent.person.addresses << Address.new(family_member.person.home_address.attributes.slice("kind", "city", "county", "state", "zip", "address_1", "address_2"))
        dependent.person.save!
        result = subject.call({family_member: dependent})
        expect(result.success[:same_with_primary]).to be_truthy
      end
    end

    context "when there is same home address as primary, but is_temporarily_out_of_state is true" do
      it 'should return same_with_primary as false' do
        dependent.person.addresses << Address.new(family_member.person.home_address.attributes.slice("kind", "city", "county", "state", "zip", "address_1", "address_2"))
        dependent.person.save!
        dependent.person.update_attributes(is_temporarily_out_of_state: true)
        result = subject.call({family_member: dependent})
        expect(result.success[:same_with_primary]).to be_falsey
      end
    end
  end
end
