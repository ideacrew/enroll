# frozen_string_literal: true

require "rails_helper"

# Test ParseDateHelper, used to parse mm/dd/yyyy and yyyy-mm-dd formats from date fields
RSpec.describe ParseDateHelper, :type => :helper do
  let(:date) { Date.today }

  it "should parse a date in mm/dd/yyyy format" do
    formatted_date = date.strftime('%m/%d/%Y')

    expect(helper.parse_date(formatted_date)).to eq(date)
  end

  it "should parse a date in yyyy-mm-dd format" do
    formatted_date = date.strftime('%Y-%m-%d')

    expect(helper.parse_date(formatted_date)).to eq(date)
  end

  it "should return nil for invalid date string" do
    expect(helper.parse_date('10/11')).to eq(nil)
  end
end