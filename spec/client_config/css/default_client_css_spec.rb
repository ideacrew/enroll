# frozen_string_literal: true

require 'rails_helper'

# Rspec to help maintain client configured CSS better
RSpec.describe "Default Client Specific CSS with Resource Registry" do

  context "colors" do
    context "application colors" do
      if EnrollRegistry[:enroll_app].setting(:site_key).item == :me
        it "should have dark blue text" do
          expect(EnrollRegistry[:application_text_color].settings(:color).item).to eq("#487ba2")
        end
      end
      if EnrollRegistry[:enroll_app].setting(:site_key).item == :dc
        it "should have black text" do
          expect(EnrollRegistry[:application_text_color].settings(:color).item).to eq("#333")
        end
      end
    end
  end
end