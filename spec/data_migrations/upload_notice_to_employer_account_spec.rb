require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "upload_notice_to_employer_account")

describe UploadNoticeToEmployerAccount, dbclean: :after_each do

  let(:given_task_name) { "upload_notice_to_employer_account" }
  subject { UploadNoticeToEmployerAccount.new(given_task_name, double(:current_scope => nil)) }
  let!(:organization)      { FactoryGirl.create(:organization)}
  let(:bucket_name) { 'notices' }
  let(:file_path) { File.dirname(__FILE__) }
  let(:doc_id) { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}{#sample-key" }
  let!(:employer_profile)  { FactoryGirl.create(:employer_profile, organization: organization)}
  let!(:plan_year)         { FactoryGirl.create(:plan_year, employer_profile: employer_profile)}

  before(:each) do
    allow(ENV).to receive(:[]).with('fein').and_return(organization.fein)
    allow(ENV).to receive(:[]).with('notice_name').and_return('Special Enrollment Denial Notice')
    allow(ENV).to receive(:[]).with('file_path').and_return(file_path)
  end

  context "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  context "upload notice" do
    it "should save notice as documents under employer profile" do
      allow(Aws::S3Storage).to receive(:save).with(file_path, bucket_name).and_return(doc_id)
      expect(employer_profile.documents.size).to eq 0
      subject.migrate
      employer_profile.reload
      expect(employer_profile.documents.size).to eq 1
    end
  end

  context "create_secure_inbox_message" do
    it "should send secure inbox message to employer account" do
      allow(Aws::S3Storage).to receive(:save).with(file_path, bucket_name).and_return(doc_id)
      expect(employer_profile.inbox.messages.size).to eq 0
      subject.migrate
      employer_profile.reload
      expect(employer_profile.inbox.messages.size).to eq 1
    end
  end

  context "for a case when doc_uri is nil" do
    it "should not send secure inbox message to employer account when the pdf is not uploaded to S3 instead should raise error" do
      allow(Aws::S3Storage).to receive(:save).with(file_path, bucket_name).and_return(nil)
      expect(employer_profile.inbox.messages.size).to eq 0
      expect{subject.migrate}.to raise_error(RuntimeError, /Unable to generate the doc_uri for notice: SpecialEnrollmentDenialNotice to #{employer_profile.legal_name}'s account/)
      expect(employer_profile.inbox.messages.size).to eq 0
    end
  end
end
