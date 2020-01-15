require 'rails_helper'
require 'rake'
require 'csv'

describe 'Broker and GA Staff Roles Invitations Monthly report', :dbclean => :after_each do
  context 'reports:shop brokers_and_ga_staff_with_URL_from_admin_approval' do

    before do
      Rails.application.class.load_tasks
    end

    it "should invoke without errors" do
      expect { Rake::Task["reports:shop:brokers_and_ga_staff_with_URL_from_admin_approval"].invoke }.to_not raise_error
    end
  end
end
