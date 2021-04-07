require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'update_subject_for_messages')

describe UpdateSubjectForMessages, dbclean: :after_each do
  let(:given_task_name) { 'update_subject_for_messages' }
  subject { UpdateSubjectForMessages.new(given_task_name, double(:current_scope => nil)) }

  context 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'updating subject for messages' do
    let!(:site)                 { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:organization)         { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let!(:employer_profile)     { organization.employer_profile }
    let!(:benefit_sponsorship)  { employer_profile.add_benefit_sponsorship }
    let (:message) {FactoryBot.build(:message, subject: 'Welcome to MA Health Link')}

    before(:each) do
      employer_profile.inbox.post_message(message)
    end

    it 'should update subject' do
      ClimateControl.modify fein: organization.fein, incorrect_subject: 'Welcome to MA Health Link', correct_subject: 'Welcome to Health Connector' do
        subject.migrate
        employer_profile.inbox.messages.first.reload
        expect(employer_profile.inbox.messages.first.subject).to eql ('Welcome to Health Connector')
      end
    end
  end
end
