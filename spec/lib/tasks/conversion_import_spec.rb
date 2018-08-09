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
      expected_csv_headers = %w(fein dba legal_name sic_code physical_address_1 physical_address_2 city county state zip mailing_address_1 mailing_address_2 city state zip contact_first_name contact_last_name contact_email contact_phone
                                 Enrolled_Employee_count New_Hire_Coverage_Policy coverage_start_date)
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
      headers = %w(sponsor_name fein hired_on benefit_begin_date premium_total employer_contribution subscriber_ssn subscriber_dob subscriber_gender subscriber_first_name subscriber_middle_initial subscriber_last_name subscriber_email subscriber_phone
                     subscriber_address_1 subscriber_address_2 subscriber_city subscriber_state subscriber_zip)
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