# frozen_string_literal: true

require 'rails_helper'
require 'rake'

require File.join(Rails.root, 'app', 'data_migrations', 'delete_duplicate_addresses')

describe DeleteDuplicateAddresses, dbclean: :after_each do
  let(:given_task_name) { 'delete_duplicate_addresses' }

  subject { DeleteDuplicateAddresses.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'for a given hxb_id' do
    let(:person) { FactoryBot.create(:person) }

    around do |example|
      ClimateControl.modify person_hbx_id: hbx_id do
        example.run
      end
    end


    context 'for an invalid person hbx_id' do
      let(:hbx_id) { 'hbx_id' }

      it 'should do nothing' do
        expect { subject.migrate }.not_to raise_error
      end
    end

    context 'has duplicate addresses' do
      let(:hbx_id) { person.hbx_id }

      before do
        address = person.addresses.first.dup
        @address_id = address.id
        person.addresses << address
        person.save!
        subject.migrate
        person.reload
      end

      it 'should delete duplicate address' do
        expect { person.addresses.find(@address_id.to_s) }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end
  end
end
