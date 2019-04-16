require "rails_helper"
require 'csv'
require File.join(Rails.root, "app", "reports", "hbx_reports", "shop_enrollment_report")

describe ShopEnrollmentReport do
  subject { ShopEnrollmentReport.new("shop_enrollment_report", double(:current_scope => nil)) }

  before(:each) do
    allow(ENV).to receive(:[]).with("purchase_date_start").and_return('06/01/2018')
    allow(ENV).to receive(:[]).with("purchase_date_end").and_return('06/10/2018')
    subject.migrate
    @file = "#{Rails.root}/shop_enrollment_report.csv"
  end

  it "creates csv file" do
    file_context = CSV.read(@file)
    expect(file_context.size).to be > 0
  end

  it "returns correct fields" do
    CSV.foreach(@file, :headers => true) do |csv|
      fields = ['Employer ID', 'Employer FEIN', 'Employer Name', 'Employer Plan Year Start Date', 'Plan Year State', 'Employer State',
                'Enrollment Group ID', 'Enrollment Purchase Date/Time', 'Coverage Start Date', 'Enrollment State', 'Subscriber HBX ID',
                'Subscriber First Name','Subscriber Last Name', 'Plan HIOS Id', 'Covered lives on the enrollment', 'Enrollment Reason',
                'In Glue']
      expect(csv).to eq fields
    end
  end

  after(:all) do
    FileUtils.rm("#{Rails.root}/shop_enrollment_report.csv")
  end
end