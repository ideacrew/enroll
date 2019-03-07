require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "upload_notice_to_employee_account")

describe UploadNoticeToEmployeeAccount, dbclean: :after_each do

  let(:given_task_name)     { "upload_notice_to_employee_account" }
  let(:subject)             { UploadNoticeToEmployeeAccount.new(given_task_name, double(:current_scope => nil)) }
  let!(:organization)       { FactoryGirl.create(:organization)}
  let(:bucket_name)         { 'notices' }
  let(:file_path)           { File.dirname(__FILE__) }
  let(:doc_id)              { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}{#sample-key" }
  let!(:employer_profile)   { FactoryGirl.create(:employer_profile, organization: organization)}
  let!(:plan_year)          { FactoryGirl.create(:plan_year, employer_profile: employer_profile)}
  let(:census_employee1)    { FactoryGirl.create(:census_employee ,employee_role_id: employee_role.id,employer_profile_id: employer_profile.id) }
  let(:person)              { FactoryGirl.create(:person) }
  let(:employee_role)       { FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}

  before(:each) do
    allow(ENV).to receive(:[]).with('hbx_id').and_return(person.hbx_id)
    allow(ENV).to receive(:[]).with('notice_name').and_return('Your Health Plan Open Enrollment Period has Begun')
    allow(ENV).to receive(:[]).with('file_path').and_return(file_path)
    allow(Aws::S3Storage).to receive(:save).with(file_path, bucket_name).and_return(doc_id)
  end

  context "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  context "upload notice" do
    it "should save notice as documents under person" do
      expect(person.documents.size).to eq 0
      subject.migrate
      person.reload
      expect(person.documents.size).to eq 1
    end
  end

  context "create_secure_inbox_message" do
    it "should send secure inbox message to person" do
      expect{ subject.migrate }.to change { person.reload.inbox.messages.count }.by 1
    end
  end
end
