require 'rails_helper'

module SponsoredBenefits
  RSpec.describe BenefitApplications::BenefitApplication, type: :model, dbclean: :around_each do
    let(:subject) { BenefitApplications::BenefitApplication.new }
    let(:date_range) { (Date.today..1.year.from_now) }

    it "assigns date ranges correctly" do
      expect(subject.send(:tidy_date_range, date_range)).to be_kind_of(Range)
    end

    it "assigns effective_period correctly" do
      subject.effective_period = date_range
      expect(subject.effective_period).to eq(date_range)
    end
  end
end
