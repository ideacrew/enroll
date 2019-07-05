require 'rails_helper'
require 'rake'
require 'csv'

describe 'Monthly Reports Sep', :dbclean => :after_each do
  context 'reports:monthly_reports_sep date="Month,Year"' do

    let(:date) { "2020-12-20" }
    let(:start_date) { Date.parse(date) }
    let(:end_date) { Date.parse(date).next_month }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    let!(:enrollments) do
      10.times do
        FactoryBot.create(
          :hbx_enrollment,
          created_at: Date.parse(date),
          family: family,
          enrollment_kind: 'special_enrollment',
          kind: 'individual'
        )
      end
    end

    before do
      ClimateControl.modify date: date do
        load File.expand_path("#{Rails.root}/lib/tasks/hbx_reports/monthly_reports_sep.rake", __FILE__)
        Rake::Task.define_task(:environment)
        allow(Family).to receive(:monthly_reports_scope).and_return(Family.all)
        allow(HbxEnrollment).to receive(:enrollments_for_monthly_report_sep_scope).with(start_date, end_date, family.id).and_return(HbxEnrollment.all)
        Rake::Task["reports:monthly_reports_sep"].invoke
      end
    end

    it "should generate the proper report" do
      file_name = "#{Rails.root}/monthly_sep_enrollments_report_#{date.gsub(" ", "").split(",").join("_")}.csv"
      expect(File.exist?(file_name)).to eq(true)
    end
  end
end
