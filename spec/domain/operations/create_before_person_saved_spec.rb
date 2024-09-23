# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::CreateBeforePersonSaved, dbclean: :after_each do

  let(:person) { FactoryBot.create(:person, :with_ssn) }
  let(:dependent) { FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 30.years) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:family_member) { FactoryBot.create(:family_member, family: family, person: dependent) }
  let(:cv3_family) { ::Operations::Transformers::FamilyTo::Cv3Family.new.call(family).success }
  let(:cv3_family_member) { cv3_family[:family_members].first }


  describe 'Success' do
    let(:changed_attributes) do
      {changed_person_attributes: {first_name: 'John', last_name: "Fitz", encrypted_ssn: 'New Encrypted SSN', dob: TimeKeeper.date_of_record - 20.years},
       changed_address_attributes: [{kind: 'home', address_1: '123 Main St', city: 'Portland', state: 'ME', zip: '20001'}],
       changed_phone_attributes: [{:kind => 'home',:full_phone_number => "5555555557", :number => "5555557", :updated_at => TimeKeeper.date_of_record}],
       changed_email_attributes: [{:kind => "home", :address => "test@test.com", :updated_at => TimeKeeper.date_of_record}],
       changed_relationship_attributes: [{:kind => 'child', :relative_id => dependent.id, :updated_at => nil}] }
    end

    let(:params) { {changed_attributes: changed_attributes, after_save_version: person.to_hash} }


    before do
      person.ensure_relationship_with(dependent, "spouse")
      family.reload
      @result = described_class.new.call(changed_attributes, cv3_family_member)
    end

    context "with valid Person attributes" do
      it 'returns Success' do
        expect(@result.success?).to be_truthy
      end

      it 'updates cv3 family member person attributes' do
        expect(@result.success[:person][:person_name][:first_name]).to eql(changed_attributes[:changed_person_attributes][:first_name])
        expect(@result.success[:person][:person_name][:last_name]).to eql(changed_attributes[:changed_person_attributes][:last_name])
        expect(@result.success[:person][:person_demographics][:encrypted_ssn]).to eql(changed_attributes[:changed_person_attributes][:encrypted_ssn])
        expect(@result.success[:person][:person_demographics][:dob]).to eql(changed_attributes[:changed_person_attributes][:dob])
      end
    end

    context "with valid Address attributes" do
      it 'returns Success' do
        expect(@result.success?).to be_truthy
      end

      it 'updates cv3 family address attributes' do
        kind = changed_attributes[:changed_address_attributes].first[:kind]
        home_address = @result.success[:person][:addresses].detect {|address| address[:kind] == kind }
        expect(home_address[:address_1]).to eql(changed_attributes[:changed_address_attributes].first[:address_1])
        expect(home_address[:city]).to eql(changed_attributes[:changed_address_attributes].first[:city])
        expect(home_address[:state]).to eql(changed_attributes[:changed_address_attributes].first[:state])
        expect(home_address[:zip]).to eql(changed_attributes[:changed_address_attributes].first[:zip])
      end
    end

    context "with valid Phone attributes" do
      it 'returns Success' do
        expect(@result.success?).to be_truthy
      end

      it 'updates cv3 family phone attributes' do
        kind = changed_attributes[:changed_phone_attributes].first[:kind]
        home_phone = @result.success[:person][:phones].detect {|phone| phone[:kind] == kind }
        expect(home_phone[:full_phone_number]).to eql(changed_attributes[:changed_phone_attributes].first[:full_phone_number])
        expect(home_phone[:number]).to eql(changed_attributes[:changed_phone_attributes].first[:number])
      end
    end

    context "with valid Email attributes" do
      it 'returns Success' do
        expect(@result.success?).to be_truthy
      end

      it 'updates cv3 family email attributes' do
        kind = changed_attributes[:changed_email_attributes].first[:kind]
        home_email = @result.success[:person][:emails].detect {|email| email[:kind] == kind }
        expect(home_email[:address]).to eql(changed_attributes[:changed_email_attributes].first[:address])
      end
    end

    context "with valid Relationship attributes" do

      it 'updates cv3 family person relationship attributes' do
        cv3_family = ::Operations::Transformers::FamilyTo::Cv3Family.new.call(family).success
        family_member = cv3_family[:family_members].first
        result = described_class.new.call(changed_attributes, family_member)
        expect(result.success[:person][:person_relationships].first[:kind]).to eql(changed_attributes[:changed_relationship_attributes].first[:kind])
      end
    end
  end

  describe "Failure" do

    context "missing changed attributes" do
      let(:changed_attributes) { {} }
      before do
        @result = described_class.new.call(changed_attributes, cv3_family_member)
      end

      it "returns failure message" do
        expect(@result.failure).to eql("changed attributes not present")
      end
    end

    context "missing family_member" do
      let(:changed_attributes) { {changed_person_attributes: {}} }
      before do
        @result = described_class.new.call(changed_attributes, {})
      end

      it "returns failure message" do
        expect(@result.failure).to eql("cv family member not present")
      end
    end
  end
end