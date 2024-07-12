# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Person, type: :model do
  let(:person) { FactoryBot.create(:person) }

  describe '#person_addresses=' do
    let(:address_attributes) { { 'kind' => 'home', 'address_1' => '123 Main St', 'city' => 'test', 'state' => 'CA', 'zip' => '52486' } }
    let(:array_attributes) { [address_attributes] }

    context 'without an existing address' do
      it 'assigns the address attributes to the addresses association' do
        person.addresses.delete_all
        expect do
          person.person_addresses = array_attributes
        end.to change { person.addresses.size }.by(1)
        expect(person.addresses.last.kind).to eq('home')
        expect(person.addresses.last.address_1).to eq('123 Main St')
        expect(person.addresses.last.city).to eq('test')
        expect(person.addresses.last.state).to eq('CA')
        expect(person.addresses.last.zip).to eq('52486')
      end
    end

    context 'with an existing address' do
      it 'updates an existing address' do
        existing_address = person.home_address
        expect do
          person.person_addresses = array_attributes
        end.to change { person.addresses.size }.by(0)
        expect(existing_address.kind).to eq('home')
        expect(existing_address.address_1).to eq('123 Main St')
        expect(existing_address.city).to eq('test')
        expect(existing_address.state).to eq('CA')
        expect(existing_address.zip).to eq('52486')
      end
    end
  end

  describe '#person_emails=' do
    let(:email_attributes) { { 'kind' => 'home', 'address' => 'test@example.com' } }
    let(:array_attributes) { [email_attributes] }

    context 'without an existing email' do
      it 'assigns the email attributes to the emails association' do
        person.emails.delete_all
        expect do
          person.person_emails = array_attributes
        end.to change { person.emails.size }.by(1)
        expect(person.emails.last.kind).to eq('home')
        expect(person.emails.last.address).to eq('test@example.com')
      end
    end

    context 'with an existing email' do
      it 'updates an existing email' do
        existing_email = person.home_email
        expect do
          person.person_emails = array_attributes
        end.to change { person.emails.size }.by(0)
        expect(existing_email.kind).to eq('home')
        expect(existing_email.address).to eq('test@example.com')
      end
    end
  end

  describe '#person_phones=' do
    let(:phone_attributes) { { 'kind' => 'home', 'full_phone_number' => '2584567854' } }
    let(:array_attributes) { [phone_attributes] }
    context 'without an existing phone' do
      it 'assigns the phone attributes to the phones association' do
        person.phones.delete_all
        expect do
          person.person_phones = array_attributes
        end.to change { person.phones.size }.by(1)
        expect(person.phones.last.kind).to eq('home')
        expect(person.phones.last.full_phone_number).to eq('2584567854')
      end
    end

    context 'with an existing phone' do
      it 'updates an existing phone' do
        existing_phone = person.home_phone
        expect do
          person.person_phones = array_attributes
        end.to change{ person.phones.size }.by(0)
        expect(existing_phone.kind).to eq('home')
        expect(existing_phone.full_phone_number).to eq('2584567854')
      end
    end
  end

  describe '#add_new_verification_type' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }

    before do
      person.add_new_verification_type(VerificationType::ALIVE_STATUS)
    end

    it 'returns Alive status' do
      expect(person.reload.alive_status).to be_a(VerificationType)
      expect(person.alive_status.type_name).to eq(VerificationType::ALIVE_STATUS)
      expect(person.alive_status.validation_status).to eq('unverified')
    end
  end

  describe 'track_history' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:new_hbx_id) { HbxIdGenerator.generate_member_id }

    it 'tracks history on hbx_id' do
      person.save!
      current_hbx_id = person.hbx_id
      person.hbx_id = new_hbx_id
      person.save!
      expect(person.hbx_id).to eq(new_hbx_id)
      expect(
        person.history_tracks.where(
          action: 'update',
          original: { 'hbx_id' => current_hbx_id },
          modified: { 'hbx_id' => new_hbx_id.to_s }
        ).present?
      ).to be_truthy
    end
  end
end
