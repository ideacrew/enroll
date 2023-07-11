# frozen_string_literal: true

require 'rails_helper'

module BenefitSponsors
  # benefit sponsorships
  module BenefitSponsorships
    RSpec.describe ShopOsseEligibility::Grant,
                   type: :model,
                   dbclean: :after_each do
      describe 'A new model instance' do
        it { is_expected.to be_mongoid_document }
        it { is_expected.to have_fields(:title, :key, :description) }
        it { is_expected.to embed_many(:state_histories) }

        context 'with all required fields' do
          subject do
            create(
              :benefit_sponsors_benefit_sponsorship_osse_grant,
              :with_state_history
            )
          end

          context 'with all required arguments' do
            it 'should be valid' do
              subject.validate
              expect(subject).to be_valid
            end

            it 'should be findable' do
              subject.save!
              expect(described_class.find(subject.id)).to eq subject
            end

            it 'should have state history' do
              subject.save!
              record = described_class.find(subject.id)
              expect(record.state_histories).not_to be_empty
            end
          end
        end
      end
    end
  end
end
