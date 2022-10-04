# frozen_string_literal: true

require "rails_helper"
require 'csv'
require File.join(Rails.root, "app", "reports", "hbx_reports", "shop_enrollment_report")

describe ShopEnrollmentReport do
  subject { ShopEnrollmentReport.new("shop_enrollment_report", double(:current_scope => nil)) }

  before(:each) do
    subject.migrate
    @file = "#{Rails.root}/hbx_report/shop_enrollment_report.csv"
  end

  it "creates csv file" do
    ClimateControl.modify purchase_date_start: (0o6 / 0o1 / 2018).to_s, purchase_date_end: (0o6 / 10 / 2018).to_s do
      file_context = CSV.read(@file)
      expect(file_context.size).to be > 0
    end
  end

  it "returns correct fields" do
    ClimateControl.modify purchase_date_start: (0o6 / 0o1 / 2018).to_s, purchase_date_end: (0o6 / 10 / 2018).to_s do

      CSV.foreach(@file, :headers => true) do |csv|
        expect(csv).to eq ['Employer ID', 'Employer FEIN', 'Employer Name', 'Plan Year Start', 'Plan Year State', 'Employer State',
                           'Enrollment GroupID', 'Purchase Date', 'Coverage Start', 'Coverage End', 'Coverage Kind', 'Enrollment State',
                           'Subscriber HBXID', 'Subscriber First Name','Subscriber Last Name', 'HIOS ID', 'Premium Subtotal',
                           'ER Contribution', 'Applied APTC Amount', 'Total Responsible Amount', 'Family Size', 'Enrollment Reason', 'In Glue',
                           "Policy Plan Name", "Enrollee's Hbx Ids", "Enrollee's DOBs", "Member Coverage Start Date", "Member Coverage End Date",
                           "Osse Eligible", "Monthly Subsidy Amount", "Employee Contribution"]
      end
    end
  end

  after(:all) do
    FileUtils.rm_rf(Dir["#{Rails.root}//hbx_report"])
  end
end
