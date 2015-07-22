require "rails_helper"

RSpec.describe ApplicationHelper, :type => :helper do
  describe "#dob_in_words" do
    it "returns date of birth in words for < 1 year" do
      expect(helper.dob_in_words(0, "20/06/2015".to_date)).to eq time_ago_in_words("20/06/2015".to_date)
      expect(helper.dob_in_words(0, "20/07/2015".to_date)).to eq time_ago_in_words("20/07/2015".to_date)
      expect(helper.dob_in_words(0, "20/07/2014".to_date)).to eq time_ago_in_words("20/07/2014".to_date)
    end
  end

  describe "#enrollment_progress_bar" do
    let(:employer_profile){FactoryGirl.create(:employer_profile)}
    let(:plan_year){FactoryGirl.create(:plan_year, employer_profile: employer_profile)}

    it "display progress bar" do
      expect(helper.enrollment_progress_bar(plan_year, 1, minimum: false)).to include('<div class="progress-wrapper">')
    end
  end
end
