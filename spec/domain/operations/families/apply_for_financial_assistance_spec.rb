# frozen_string_literal: true

RSpec.describe Operations::Families::ApplyForFinancialAssistance, type: :model, dbclean: :after_each do
  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'bad argument' do
    it 'should return failure' do
      expect(subject.call(family_id: 'family_id')).to be_a Dry::Monads::Result::Failure
    end
  end

  context 'with a family' do
    let!(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, :with_ssn) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

    before do
      @result = subject.call(family_id: family.id)
    end

    it 'should return success' do
      expect(@result).to be_a Dry::Monads::Result::Success
    end

    it 'should match with person hbx_id' do
      expect(@result.success.first[:person_hbx_id]).to eq(person.hbx_id)
    end

    it 'should include relationship' do
      expect(@result.success.first[:relationship]).to eq('self')
    end

    it 'should have all the matching keys' do
      [:person_hbx_id, :is_applying_coverage, :citizen_status, :is_consumer_role,
       :five_year_bar_applies, :five_year_bar_met, :qualified_non_citizen,
       :indian_tribe_member, :is_incarcerated, :addresses, :phones, :emails,
       :family_member_id, :is_primary_applicant].each do |key|
        expect(@result.success.first.keys).to include(key)
      end
    end
  end

  describe 'with address populated with location_state_code' do
    let!(:person10) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, :with_ssn) }
    let!(:family10) { FactoryBot.create(:family, :with_primary_family_member, person: person10) }
    let!(:address10) do
      person10.addresses.destroy_all
      addr = FactoryBot.create(:address, person: person10)
      addr.update_attributes!({ location_state_code: addr.state, full_text: 'full_text' })
      addr
    end

    before do
      @result = subject.call(family_id: family10.id)
      @address = @result.success.first[:addresses].first
    end

    it 'should return success' do
      expect(@result).to be_success
    end

    it 'persisted address should have location_state_code populated' do
      expect(address10.location_state_code).to eq(address10.state)
    end

    it 'persisted address should have full_text populated' do
      expect(address10.full_text).to eq('full_text')
    end

    it 'should not return location_state_code' do
      expect(@address.keys).not_to include(:location_state_code)
    end

    it 'should not return full_text' do
      expect(@address.keys).not_to include(:full_text)
    end

    it 'should include :kind with value' do
      expect(@address[:kind]).not_to be_blank
    end

    it 'should include :address_1 with value' do
      expect(@address[:address_1]).not_to be_blank
    end

    it 'should include :city with value' do
      expect(@address[:city]).not_to be_blank
    end

    it 'should include :county with value' do
      expect(@address[:county]).not_to be_blank
    end

    it 'should include :state with value' do
      expect(@address[:state]).not_to be_blank
    end

    it 'should include :zip with value' do
      expect(@address[:zip]).not_to be_blank
    end
  end

  describe 'with inactive family members' do
    let!(:person11) do
      FactoryBot.create(:person,
                        :with_consumer_role,
                        :with_active_consumer_role,
                        :with_ssn,
                        first_name: 'Person11')
    end
    let!(:family11) { FactoryBot.create(:family, :with_primary_family_member, person: person11) }
    let!(:person12) do
      per = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, first_name: 'Person12')
      person11.ensure_relationship_with(per, 'spouse')
      per
    end
    let!(:family_member12) do
      FactoryBot.create(:family_member, is_active: false, person: person12, family: family11)
    end

    before do
      @result = subject.call(family_id: family11.id)
    end

    it 'should return success' do
      expect(@result).to be_success
    end

    it 'response should match the number of active_family_members' do
      expect(@result.success.count).to eq(family11.active_family_members.count)
    end

    it 'should return attributes of active family members only' do
      expect(@result.success.first[:first_name]).to eq(person11.first_name)
    end
  end

  describe 'with inactive family members' do
    let!(:person11) do
      FactoryBot.create(:person,
                        :with_consumer_role,
                        :with_active_consumer_role,
                        :with_ssn,
                        first_name: 'Person11')
    end
    let!(:family11) { FactoryBot.create(:family, :with_primary_family_member, person: person11) }
    let!(:person12) do
      per = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, first_name: 'Person12')
      person11.ensure_relationship_with(per, 'spouse')
      per
    end
    let!(:family_member12) do
      FactoryBot.create(:family_member, person: person12, family: family11)
    end

    before do
      @result = subject.call(family_id: family11.id)
      @member_hashes = @result.success
    end

    it 'should return success' do
      expect(@result).to be_success
    end

    it 'should include relationship key with value' do
      @member_hashes.each do |member_hash|
        expect(member_hash.keys).to include(:relationship)
        expect(member_hash[:relationship]).to be_truthy
      end
    end
  end

  describe 'five year bar information' do
    let!(:person) do
      consumer = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, :with_ssn)
      consumer.consumer_role.five_year_bar_applies = true
      consumer.consumer_role.five_year_bar_met = true
      consumer.save!
      consumer.consumer_role.lawful_presence_determination.update!(qualified_non_citizenship_result: 'N')
      consumer
    end
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

    before do
      @result = subject.call(family_id: family.id)
    end

    it 'should match with person hbx_id' do
      expect(@result.success.first[:five_year_bar_applies]).to eq(person.consumer_role.five_year_bar_applies)
      expect(@result.success.first[:five_year_bar_met]).to eq(person.consumer_role.five_year_bar_met)
      expect(@result.success.first[:qualified_non_citizen]).to eq(false)
    end
  end
end
