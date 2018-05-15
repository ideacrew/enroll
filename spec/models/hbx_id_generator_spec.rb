require 'rails_helper'

describe HbxIdGenerator do
  describe "with a slugged configuration" do
    it "generates member ids" do
      expect(HbxIdGenerator.generate_member_id).not_to eq nil
    end

    it "generates policy ids" do
      expect(HbxIdGenerator.generate_policy_id).not_to eq nil
    end

    it "generates organization ids" do
      expect(HbxIdGenerator.generate_organization_id).not_to eq nil
    end

    it "generates family id's" do
      expect(HbxIdGenerator.generate_family_id).not_to eq nil
    end

    it "generates tax_household id's" do
      expect(HbxIdGenerator.generate_tax_household_id).not_to eq nil
    end

    it "generates case id's" do
      expect(HbxIdGenerator.generate_case_id).not_to eq nil
    end
  end

  describe "with an amqp source" do
    let(:generator) { HbxIdGenerator::AmqpSource }
    let(:amqp_response) {
     {:body => ("[" + sequence_number + "]")}
    }

    before(:each) do
      allow(Acapi::Requestor).to receive(:request).with("sequence.next", {:sequence_name => sequence_name}, 2).and_return(amqp_response)
    end

    describe "for member ids" do
      let(:sequence_name) { "member_id" }
      let(:sequence_number) { "23423434" }

      it "returns the expected member_id" do
        expect(generator.generate_member_id).to eq sequence_number
      end
    end

    describe "for policy ids" do
      let(:sequence_name) { "policy_id" }
      let(:sequence_number) { "878234" }

      it "returns the expected policy_id" do
        expect(generator.generate_policy_id).to eq sequence_number
      end
    end

    describe "for organization ids" do
      let(:sequence_name) { "organization_id" }
      let(:sequence_number) { "2343234444" }

      it "returns the expected organization_id" do
        expect(generator.generate_organization_id).to eq sequence_number
      end
    end

    describe "for family id's" do
      let(:sequence_name) { "family_id" }
      let(:sequence_number) { "867433" }

      it "returns the expected family id's" do
        expect(generator.generate_family_id).to eq sequence_number
      end
    end

    describe "for tax_household id's" do
      let(:sequence_name) { "tax_household_id" }
      let(:sequence_number) { "86748765433" }

      it "returns the expected family id's" do
        expect(generator.generate_tax_household_id).to eq sequence_number
      end
    end

    describe "for case id's" do
      let(:sequence_name) { "case_id" }
      let(:sequence_number) { "8748738939" }

      it "returns the expected family id's" do
        expect(generator.generate_case_id).to eq sequence_number
      end
    end

  end
end
