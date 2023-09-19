# frozen_string_literal: true

require 'rails_helper'

describe ConsumerRole, dbclean: :around_each do
  before { DatabaseCleaner.clean }

  let(:person) { FactoryBot.create(:person, :with_ssn) }
  let(:consumer_role) do
    FactoryBot.create(
      :consumer_role,
      is_applying_coverage: is_applying_coverage,
      person: person,
      lawful_presence_determination: lawful_presence_determination
    )
  end
  let(:lawful_presence_determination) { FactoryBot.build(:lawful_presence_determination, citizen_status: citizen_status) }

  describe '#eligible_for_invoking_dhs?' do
    shared_examples_for 'eligibility of invoking dhs call' do |citizen_status, is_applying_coverage, eligible|
      let(:citizen_status) { citizen_status }
      let(:is_applying_coverage) { is_applying_coverage }

      it "returns #{eligible} for citizen_status: #{citizen_status} and member attestation #{is_applying_coverage} to coverage required" do
        expect(consumer_role.eligible_for_invoking_dhs?).to eq(eligible)
      end
    end

    context 'with different citizen status and consumer applying for coverage' do
      it_behaves_like 'eligibility of invoking dhs call', 'alien_lawfully_present', true, true
      it_behaves_like 'eligibility of invoking dhs call', 'lawful_permanent_resident', true, false
      it_behaves_like 'eligibility of invoking dhs call', 'naturalized_citizen', true, true
      it_behaves_like 'eligibility of invoking dhs call', 'non_native_not_lawfully_present_in_us', true, false
      it_behaves_like 'eligibility of invoking dhs call', 'not_lawfully_present_in_us', true, false
      it_behaves_like 'eligibility of invoking dhs call', 'us_citizen', true, false
    end

    context 'with different citizen status and consumer not applying for coverage' do
      it_behaves_like 'eligibility of invoking dhs call', 'alien_lawfully_present', false, false
      it_behaves_like 'eligibility of invoking dhs call', 'lawful_permanent_resident', false, false
      it_behaves_like 'eligibility of invoking dhs call', 'naturalized_citizen', false, false
      it_behaves_like 'eligibility of invoking dhs call', 'non_native_not_lawfully_present_in_us', false, false
      it_behaves_like 'eligibility of invoking dhs call', 'not_lawfully_present_in_us', false, false
      it_behaves_like 'eligibility of invoking dhs call', 'us_citizen', false, false
    end
  end
end
