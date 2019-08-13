require 'rails_helper'

class DummyNoticeKind
  attr_accessor :title, :event_name, :resource, :market_kind, :notice_number, :notice_path, :notice_type
  include Notifier::NoticeBuilder

  def initialize(params)
    self.event_name = params[:event_name]
    self.title = params[:title]
    self.market_kind = params[:market_kind]
    self.notice_number = params[:notice_number]
  end
end

module Notifier
  module NoticeBuilder
    RSpec.describe NoticeBuilder, dbclean: :around_each do
      let(:hbx_id) { "1234" }
      let(:resource) { EmployeeRole.new }
      let(:event_name) {"acapi.info.events.employer.welcome_notice_to_employer"}
      let(:payload) do
        {
          "employer_id" => hbx_id,
          "event_object_kind" => "BenefitSponsors::Organizations::AcaShopDcEmployerProfile",
          "event_object_id" => "12345"
        }
      end
      let(:subject) do
        DummyNoticeKind.new(event_name: event_name, title: 'Test', notice_number: "ABC_123")
      end

      describe ".store_paper_notice" do
        let(:bucket_name) { 'paper-notices' }
        let(:notice_filename_for_paper_notice) { "#{hbx_id}_#{subject.title}_#{subject.notice_number.delete('_')}_#{subject.notice_type}.pdf" }
        let(:doc_uri) { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}#sample-key" }
        let(:notice_path_for_paper_notice) { Rails.root.join("tmp", notice_filename_for_paper_notice) }

        before do
          allow(FileUtils).to receive(:cp)
          allow(File).to receive(:delete)
          allow(resource).to receive(:person).and_return(double(hbx_id: '1234'))
          allow(subject).to receive(:is_employer?).and_return(false)
          allow(subject).to receive(:resource).and_return(resource)
          allow(subject).to receive(:notice_path).and_return("notice_path")
          allow(subject).to receive(:notice_type).and_return("ER")
          allow(Aws::S3Storage).to receive(:save).and_return(doc_uri)
          subject.store_paper_notice
        end

        it 'AWS Storage to save doc_uri' do
          expect(Aws::S3Storage).to have_received(:save).with(notice_path_for_paper_notice, bucket_name, notice_filename_for_paper_notice)
        end
      end

      describe ".send_generic_notice_alert" do
        let(:usermailer) {double "UserMailer"}

        before do
          allow(subject).to receive(:is_employer?).and_return(false)
          allow(UserMailer).to receive(:generic_notice_alert).and_return(usermailer)
          allow(usermailer).to receive(:deliver_now).and_return(true)
          subject.send_generic_notice_alert
        end

        it "should receive send_generic_notice_alert" do
          expect(UserMailer).to have_received(:generic_notice_alert)
        end
      end
    end
  end
end
