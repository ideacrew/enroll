# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::EdiGateway::TriggerBulkTax1095aNotices do

  describe 'with invalid params' do
    it "should fail to publish" do
      result = described_class.new.call({tax_year: Date.today.year,tax_form_type: "", exclusion_list: []})
      expect(result.success?).to be_falsey
      expect(result.failure).to eq("Valid tax form type is not present")
    end
  end

  describe 'with valid params' do
    it "return success" do
      result = described_class.new.call({tax_year: Date.today.year,tax_form_type: "IVL_TAX", exclusion_list: []})
      expect(result.success?).to be_truthy
    end
  end
end
