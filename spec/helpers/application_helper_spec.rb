require "rails_helper"

RSpec.describe ApplicationHelper, :type => :helper do
  describe "#format_date_with_hyphens" do
    it "returns date with hyphens" do
      expect(helper.format_date_with_hyphens(TimeKeeper.date_of_record)).to eq(TimeKeeper.date_of_record.to_s.gsub("/","-"))
    end
  end
end