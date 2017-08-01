require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "updating_broker_agency_address")

describe UpdatingBrokerAgencyAddress, dbclean: :after_each do

  let(:given_task_name) { "updating_broker_agency_addresss" }
  subject { UpdatingBrokerAgencyAddress.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "migrate", dbclean: :after_each do
    before do
      allow(ENV).to receive(:[]).with('fein').and_return organization.fein
    end
    let(:address) { Address.new(kind: 'primary', address_1: '106 Autumn Hill Way', address_2: '', address_3: '', city: 'Gaithersburg', county: nil, state: 'MD', location_state_code: nil, zip: '20877', country_name: '', full_text: nil) }
    let(:phone) { Phone.new(kind: 'phone main', country_code: '', area_code: '301', number: '9227984', extension: '', primary: nil, full_phone_number: '3019227984') }
    let(:office_location) { OfficeLocation.new(is_primary: true, address: address, phone: phone) }
    let!(:organization){  Organization.new(:legal_name => "Alvin Frager", :fein => "521698168", :dba => "Alvin Frager Insurance", office_locations: [office_location]) }
    let!(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, :organization => organization) }
    
    it "should update the org address" do
      expect(organization.office_locations.first.address.address_1).to eq "106 Autumn Hill Way"
      subject.migrate
      organization.reload
      expect(organization.office_locations.first.address.address_1).to eq "308 Southwest Drive"
    end

  end
end