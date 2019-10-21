# frozen_string_literal: true

require "rails_helper"
if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  require File.join(Rails.root, "app", "data_migrations", "import_ivl_benefit_coverage_period")

  describe ImportIvlBenefitCoveragePeriod, :dbclean => :after_each do
    let(:given_task_name) { "import_ivl_benefit_coverage_period" }
    subject { ImportIvlBenefitCoveragePeriod.new(given_task_name, double(:current_scope => nil)) }

    describe "given a task name" do
      it "has the given task name" do
        expect(subject.name).to eql given_task_name
      end
    end

    describe "create 2021 benefit coverage period for IVL market" do
      let!(:hbx_profile) { FactoryBot.create(:hbx_profile) }
      let!(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, hbx_profile: hbx_profile) }
      let!(:bcp) do
        FactoryBot.create(:benefit_coverage_period,
                          start_on: Date.new(2020,1,1),
                          end_on: Date.new(2020,12,31),
                          open_enrollment_start_on: Date.new(2019,11,1),
                          open_enrollment_end_on: Date.new(2020,1,31),
                          title: "Individual Market Benefits 2020",
                          benefit_sponsorship: benefit_sponsorship)
      end

      before(:each) do
        ClimateControl.modify :year => "2021" do
          allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
          subject.migrate
          hbx_profile.reload
        end
      end

      it "should return coverage start on" do
        bcp_2021 = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == 2021 }
        expect(bcp_2021.start_on).to eq Date.new(2021,1,1)
      end

      it "should return coverage end on" do
        bcp_2021 = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == 2021 }
        expect(bcp_2021.end_on).to eq Date.new(2021,12,31)
      end

      it "should return open enrollment start on" do
        bcp_2021 = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == 2021 }
        expect(bcp_2021.open_enrollment_start_on).to eq Date.new(2020,11,1)
      end

      it "should return open enrollment end on" do
        bcp_2021 = hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == 2021 }
        expect(bcp_2021.open_enrollment_end_on).to eq Date.new(2021,1,31)
      end
    end
  end
end
