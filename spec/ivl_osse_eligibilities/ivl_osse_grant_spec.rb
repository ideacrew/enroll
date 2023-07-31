# frozen_string_literal: true

require "rails_helper"

RSpec.describe IvlOsseEligibilities::IvlOsseGrant,
               type: :model,
               dbclean: :after_each do
  describe "A new model instance" do
    it { is_expected.to be_mongoid_document }
    it { is_expected.to have_fields(:title, :key, :description) }

    context "with all required fields" do
      subject { create(:ivl_osse_eligibility_grant) }

      context "with all required arguments" do
        it "should be valid" do
          subject.validate
          expect(subject).to be_valid
        end

        it "should be findable" do
          subject.save!
          expect(described_class.find(subject.id)).to eq subject
        end
      end
    end
  end
end
