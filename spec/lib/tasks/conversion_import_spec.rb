require 'rails_helper'
require 'rake'
require 'csv'

describe 'import conversion employer/employee details ', :dbclean => :after_each do

  before do
    load File.expand_path("#{Rails.root}/lib/tasks/conversion_import.rake", __FILE__)
    ENV['feins_list'] = ""
    Rake::Task.define_task(:environment)
  end

  context 'conversion_import:employers' do
    after :all do
      File.delete(File.join("#{Rails.root}/public", "employers_export_conversion.csv")) if File.file?(File.join("#{Rails.root}/public", "employers_export_conversion.csv"))
    end

    it 'should generate csv with given headers' do
      expected_csv_headers = %w(Action FEIN Doing\ Business\ As Legal\ Name Issuer\ Assigned\ Employer\ ID SIC\ code Physical\ Address\ 1 Physical\ Address\ 2 City County County\ FIPS\ code State Zip Mailing\ Address\ 1 Mailing\ Address\ 2
                     City State Zip Contact\ First\ Name Contact\ Last\ Name Contact\ Email Contact\ Phone Contact\ Phone\ Extension Enrolled\ Employee\ Count New\ Hire\ Coverage\ Policy Contact\ Address\ 1 Contact\ Address\ 2
                     City State Zip Broker\ Name Broker\ NPN TPA\ Name TPA\ Fein Coverage\ Start\ Date Carrier\ Selected Plan\ Selection\ Category Plan\ Name Plan\ HIOS\ ID Employer\ Contribution\ -\ Employee Employer\ Contribution\ -\ Spouse
                     Employer\ Contribution\ -\ Domestic\ Partner Employer\ Contribution\ -\ Child\ under\ 26)
      Rake::Task["conversion_import:employers"].invoke("")
      data = CSV.read "#{Rails.root}/public/employers_export_conversion.csv"
      expect(data).to eq [expected_csv_headers]
    end

    it 'should generate a csv when feins_list is nil' do
      Rake::Task["conversion_import:employers"].invoke("")
      expect(File.exists?("#{Rails.root}/public/employers_export_conversion.csv")).to be true
    end
  end

  context 'conversion_import:employees' do

    after :all do
      File.delete(File.join("#{Rails.root}/public", "employees_export_conversion.csv")) if File.file?(File.join("#{Rails.root}/public", "employees_export_conversion.csv"))
    end

    it 'should generate csv with given headers' do
      headers = %w(Action Type\ Of\ Enrollment Market Sponsor\ Name FEIN Issuer\ Assigned\ Employer\ ID  HIRED\ ON Benefit\ Begin\ Date Plan\ Name HIOS\ ID Premium\ Total Employer\ Contribution Employee\ Responsible\ Amount  Subscriber\ SSN Subscriber\ DOB Subscriber\ Gender Subscriber\ First\ Name Subscriber\ Middle\ Name Subscriber\ Last\ Name Subscriber\ Email Subscriber\ Phone
                     Subscriber\ Address\ 1 Subscriber\ Address\ 2 Subscriber\ City Subscriber\ State Subscriber\ Zip SELF)
      dep_headers = []
      7.times do |i|
        ["SSN", "DOB", "Gender", "First Name", "Middle Name", "Last Name", "Email", "Phone", "Address 1", "Address 2", "City", "State", "Zip", "Relationship"].each do |h|
          dep_headers << "Dep#{i + 1} #{h}"
        end
      end

      expected_csv_headers = headers + dep_headers
      Rake::Task["conversion_import:employees"].invoke("")
      data = CSV.read "#{Rails.root}/public/employees_export_conversion.csv"
      expect(data).to eq [expected_csv_headers]
    end

    it 'should generate a csv when feins_list is nil' do
      Rake::Task["conversion_import:employees"].invoke("")
      expect(File.exists?("#{Rails.root}/public/employees_export_conversion.csv")).to be true
    end


  end

end
