require 'rails_helper'
require 'rake'
require 'csv'

describe 'user account with no email address' do
  describe 'report:user_account:with_no_email_address' do
    let(:person)   { FactoryGirl.create(:person) }
    before do
      load File.expand_path("#{Rails.root}/lib/tasks/hbx_reports/users_account_with_no_email.rake", __FILE__)
      Rake::Task.define_task(:environment)
    end

    it 'should generate csv report with user and person information' do
      allow(User).to receive_message_chain(:where, :map, :compact).and_return([person])
      allow(person).to receive_message_chain(:user, :oim_id).and_return('Test123')
      allow(person).to receive_message_chain(:user, :roles).and_return(['consumer'])
      allow(person).to receive_message_chain(:user, :created_at).and_return('10/9/2016')
      start_date = (Date.today-10).strftime('%d/%m/%Y')
      end_date = Date.today.strftime('%d/%m/%Y')
      Rake::Task["report:user_account:with_no_email_address"].invoke(start_date,end_date)
      result =  [["username", "user_first_name", "user_last_name", "user_roles", "person_hbx_id", "person_home_email", "person_work_email", "user_created_at"], ["Test123", "John", person.last_name, "[\"consumer\"]", person.hbx_id, person.emails.first.address, "", "10/9/2016"]]
      data = CSV.read "#{Rails.root}/hbx_report/users_account_with_no_email.csv"
      expect(data).to eq result
    end

    it 'should generate user csv report in hbx_report' do
      start_date = (Date.today-10).strftime('%d/%m/%Y')
      end_date = Date.today.strftime('%d/%m/%Y')
      Rake::Task["report:user_account:with_no_email_address"].invoke(start_date,end_date)
      expect(File.directory?("#{Rails.root}/hbx_report")).to be true
      expect(File.exists?("#{Rails.root}/hbx_report/users_account_with_no_email.csv")).to be true
    end
  end
end
