# frozen_string_literal: true

require 'rails_helper'

module Validators
  RSpec.describe AddressContract,  dbclean: :after_each do

    subject do
      described_class.new.call(params)
    end

    describe "missing address1 field" do

      let(:params) do
        { kind: 'test', address_2: '1234', address_3: 'person', city: 'test', county: '', state: 'DC', zip: '12345', county_name: '' }
      end
      let(:error_message) {{:address_1 => ["is missing", "must be a string"]}}


      it "fails" do
        expect(subject).not_to be_success
        expect(subject.errors.to_h).to eq error_message
      end
    end

    describe "missing kind field" do

      let(:params) do
        { address_1: 'test', address_2: '1234', address_3: 'person', city: 'test', county: '', state: 'DC', zip: '12345', county_name: '' }
      end
      let(:error_message) {{:kind => ["is missing", "must be a string"]}}


      it "fails" do
        expect(subject).not_to be_success
        expect(subject.errors.to_h).to eq error_message
      end
    end

    describe "missing city field" do

      let(:params) { { kind: 'test', address_1: '1234', address_2: '1234', address_3: 'person', county: '', state: 'DC', zip: '12345', county_name: '' }}
      let(:error_message) {{:city => ["is missing", "must be a string"]}}


      it "fails" do
        expect(subject).not_to be_success
        expect(subject.errors.to_h).to eq error_message
      end
    end

    describe "missing state field" do

      let(:params) { { kind: 'test', address_1: '1234', address_2: '1234', address_3: 'person', city: 'test', county: '', zip: '12345', county_name: '' }}
      let(:error_message) {{:state => ["is missing", "must be a string"]}}


      it "fails" do
        expect(subject).not_to be_success
        expect(subject.errors.to_h).to eq error_message
      end
    end

    describe "missing zip" do

      let(:params) { { kind: 'test', address_1: '1234', address_2: '1234', address_3: 'person', city: 'test', state: 'DC', county: '', county_name: '' }}
      let(:error_message) {{:zip => ["is missing", "must be a string"]}}

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.errors.to_h).to eq error_message
      end
    end

    describe "passing empty address_1, city, kind, state, zip" do

      let(:params) { { kind: 'test', address_1: '', address_2: '1234', address_3: 'person', city: '', state: '', zip: '', county: '', county_name: '' }}
      let(:error_message) {{:address_1 => ["Test Addresses: address 1 can't be blank"], :city => ["Test Addresses: city can't be blank"], :state => ["Test Addresses: state can't be blank"], :zip => ["Test Addresses: zip can't be blank"]}}

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.errors.to_h).to eq error_message
      end
    end

    describe "passing all fields with invalid zip address_1, city, kind, state, zip" do

      let(:params) { { kind: 'test', address_1: '1234', address_2: '1234', address_3: 'person', city: 'city', state: 'DC', zip: '223', county: '', county_name: '' }}
      let(:error_message) {{:zip => ["Test Addresses: zip should be in the form: 12345 or 12345-1234"]}}

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.errors.to_h).to eq error_message
      end
    end

    describe "all valid fields" do

      let(:params) { { kind: 'test', address_1: '1234', address_2: '1234', address_3: 'person', city: 'test', state: 'DC', zip: '12345', county: '', county_name: '' }}

      it "passes" do
        expect(subject).to be_success
      end
    end
  end
end
