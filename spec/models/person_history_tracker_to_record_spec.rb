require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe "Person with history tracks and a list of addresses", :dbclean => :after_each do
  let(:person) do
    Person.create!({
      first_name: "Example",
      last_name: "Person",
      addresses: [
        Address.new({
          kind: "home",
          address_1: "1234 Some Street",
          city: "Washington",
          state: "DC",
          zip: "20000"
        }),
        Address.new({
          kind: "work",
          address_1: "1234 Some Other Street",
          city: "Washington",
          state: "DC",
          zip: "20000"
        })
      ]
    })
  end

  describe "when we add a mailing and delete work" do
    before :each do
      person
      sleep(1.5)
      mailing_address = Address.new({
          kind: "mailing",
          address_1: "1234 Some Third Street",
          city: "Washington",
          state: "DC",
          zip: "20000"
        })
      person.addresses.detect do |address|
        address.kind == "work"
      end.destroy
      person.save
      person.addresses << mailing_address
      person.reload
    end

    it "has a mailing address, but no work address" do
      expect(person.addresses.map(&:kind)).to include("mailing")
      expect(person.addresses.map(&:kind)).not_to include("work")
    end

    it "reverts to the original state" do
      puts person.history_tracks.map(&:created_at).map(&:to_f).inspect
      reverted_person = person.history_tracker_to_record(person.created_at)
      expect(reverted_person.addresses.map(&:kind)).not_to include("mailing")
      expect(reverted_person.addresses.map(&:kind)).to include("work")
    end
  end

end


describe "Person with history tracks and a consumer role", :dbclean => :after_each do

  let(:non_curam_ivl_person) do
    FactoryBot.create(:person, :with_family, gender: 'male', first_name: "Tom", last_name: "Cruise")
  end
  let!(:consumer_role) do
    ConsumerRole.create!(
      person: non_curam_ivl_person,
      is_state_resident: true,
      citizen_status: 'us_citizen',
      vlp_documents: [FactoryBot.build(:vlp_document)],
      ridp_documents: [FactoryBot.build(:ridp_document)],
      is_applicant: true
    )
  end

  describe "history_track_to_person" do
    describe "creating records" do
      before do
      end
    end

    describe "destroying records" do
      context "embeds many addresses" do
        before do
          FactoryBot.create(:address, person: non_curam_ivl_person)
          FactoryBot.create(:address, person: non_curam_ivl_person)
          non_curam_ivl_person.addresses.first.destroy
          FactoryBot.create(:address, person: non_curam_ivl_person)
        end

        it "undoes the destroyed records" do
        end
      end
    end

    describe "editing records" do
      context "embeds_one consumer role" do
        before do
          non_curam_ivl_person
          sleep(1.5)
          non_curam_ivl_person.consumer_role.update_attributes!(is_state_resident: false, citizen_status: 'undocumented_immigrant')
          sleep(1.5)
          non_curam_ivl_person.consumer_role.update_attributes!(is_state_resident: true, citizen_status: 'us_citizen')
        end

        it "undoes changes to a person when a HistoryTrack instance passed as arguement" do
          target_history_track =  non_curam_ivl_person.history_tracks.where(modified: {"is_state_resident" => false}).last
          past_person = non_curam_ivl_person.history_tracker_to_record(target_history_track.created_at)
          expect(past_person.consumer_role.is_state_resident).to eq(false)
          target_history_track =  non_curam_ivl_person.history_tracks.where(modified: {"is_state_resident" => true}).last
          past_person = non_curam_ivl_person.history_tracker_to_record(target_history_track.created_at)
          expect(past_person.consumer_role.is_state_resident).to eq(true)
        end
      end

      context "embeds_many address updated" do
        before do
          non_curam_ivl_person
          sleep(1.5)
          non_curam_ivl_person.update_attributes!(addresses_attributes: { "0" => { id: non_curam_ivl_person.addresses.first.id, address_1: '1600 PA Ave' } })
          sleep(1.5)
          non_curam_ivl_person.update_attributes!(addresses_attributes: { "0" => { id: non_curam_ivl_person.addresses.first.id, address_1: '111 1 St NE' } })
          sleep(1.5)
          non_curam_ivl_person.update_attributes!(addresses_attributes: { "0" => { id: non_curam_ivl_person.addresses.first.id, address_1: '1150 Connecticut Ave' } })
        end

        it "successfully returns the addresses" do
          expect(non_curam_ivl_person.addresses.first.address_1).to eq('1150 Connecticut Ave')
          target_history_track =  non_curam_ivl_person.history_tracks.where(modified: {"address_1"=>'1600 PA Ave'}).last
          past_person = non_curam_ivl_person.history_tracker_to_record(target_history_track.created_at)
          expect(past_person.addresses.first.address_1).to eq('1600 PA Ave')
        end
      end

      context "just person record itself" do
        before do
          non_curam_ivl_person
          non_curam_ivl_person.update_attributes!(gender: 'female')
          sleep 1.5
          non_curam_ivl_person.update_attributes!(gender: 'male')
          sleep 1.5
          non_curam_ivl_person.update_attributes!(dob: Date.today - 22.years)
          sleep 1.5
          non_curam_ivl_person.update_attributes!(gender: 'female')
        end

        it "undoes changes to a person when a HistoryTrack instance passed as arguement" do
          history_tracks = non_curam_ivl_person.history_tracks.to_a.sort_by(&:created_at).reverse
          puts history_tracks.map { |t| "#{t.created_at} - #{t.version} - #{t['original']}"}.join("\n")
          expect(non_curam_ivl_person.history_tracker_to_record(history_tracks[1].created_at).gender).to eq('male')
          expect(non_curam_ivl_person.history_tracker_to_record(history_tracks.third.created_at).dob).to_not eq(Date.today - 22.years)
          expect(non_curam_ivl_person.history_tracker_to_record(history_tracks.second.created_at).gender).to eq('male')
        end
      end
    end
  end
end