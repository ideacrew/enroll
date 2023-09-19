# frozen_string_literal: true

require 'rails_helper'

describe ConsumerRole, dbclean: :around_each do
  before { DatabaseCleaner.clean }

  let(:person) { FactoryBot.create(:person, :with_ssn) }
  let(:consumer_role) { FactoryBot.create(:consumer_role, person: person, lawful_presence_determination: lawful_presence_determination) }
  let(:lawful_presence_determination) { FactoryBot.build(:lawful_presence_determination, citizen_status: citizen_status) }

  describe '#eligible_for_invoking_dhs?' do
    shared_examples_for 'eligibility of invoking dhs call' do |citizen_status, eligible|
      let(:citizen_status) { citizen_status }

      it "returns #{eligible} for citizen_status: #{citizen_status}" do
        expect(consumer_role.eligible_for_invoking_dhs?).to eq(eligible)
      end
    end

    context "native validation doesn't exist" do
      it_behaves_like 'eligibility of invoking dhs call', 'alien_lawfully_present', true
      it_behaves_like 'eligibility of invoking dhs call', 'lawful_permanent_resident', false
      it_behaves_like 'eligibility of invoking dhs call', 'naturalized_citizen', true
      it_behaves_like 'eligibility of invoking dhs call', 'non_native_not_lawfully_present_in_us', false
      it_behaves_like 'eligibility of invoking dhs call', 'not_lawfully_present_in_us', false
      it_behaves_like 'eligibility of invoking dhs call', 'us_citizen', false
    end
  end
end
