require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "import_2020_ivl_benefit_package")

 describe Import2020IvlBenefitPackage, :dbclean => :after_each do
  let(:given_task_name) { "import_2020_ivl_benefit_package" }
  subject { Import2020IvlBenefitPackage.new(given_task_name, double(:current_scope => nil)) }

   describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

   describe "create 2020 benefit package for IVL market" do
    let!(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let!(:benefit_sponsorship) { FactoryGirl.create(:benefit_sponsorship, hbx_profile: hbx_profile) }
    let!(:bcp) { FactoryGirl.create(:benefit_coverage_period, start_on: Date.new(2019,1,1), end_on: Date.new(2019,12,31), open_enrollment_start_on: Date.new(2018,11,1), open_enrollment_end_on: Date.new(2019,2,8), title: "Individual Market Benefits 2018", benefit_sponsorship: benefit_sponsorship) }
     before(:each) do
      allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
      subject.migrate
      hbx_profile.reload
    end

     it "should return coverage start on" do
      bcp_2019 = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == 2020 }
      expect(bcp_2019.start_on).to eq Date.new(2020,1,1)
    end

     it "should return coverage end on" do
      bcp_2019 = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == 2020 }
      expect(bcp_2019.end_on).to eq Date.new(2020,12,31)
    end

     it "should return open enrollment start on" do
      bcp_2019 = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == 2020 }
      expect(bcp_2019.open_enrollment_start_on).to eq Date.new(2019,11,1)
    end

     it "should return open enrollment end on" do
      bcp_2019 = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == 2020 }
      expect(bcp_2019.open_enrollment_end_on).to eq Date.new(2020,1,31)
    end
  end
end
