require 'rails_helper'

module Notifier
  module NoticeBuilder
    class DummyNoticeKind
      attr_accessor :title, :event_name, :resource, :market_kind, :notice_number
      include Notifier::NoticeBuilder

      def initialize(params)
        self.event_name = params[:event_name]
        self.title = params[:title]
        self.market_kind = params[:market_kind]
        self.notice_number = params[:notice_number]
      end
    end

    RSpec.describe NoticeBuilder, dbclean: :around_each do
      let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
      let!(:model_instance)     { FactoryBot.build(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site, hbx_id: "38739472") }
      let(:employer_profile)    { model_instance.employer_profile }
      let(:event_name) {"acapi.info.events.employer.welcome_notice_to_employer"}
      let(:resource) {model_instance.employer_profile }
      let(:payload) do
        {
          "employer_id" => employer_profile.hbx_id.to_s,
          "event_object_kind" => "BenefitSponsors::Organizations::AcaShop#{Settings.site.key.capitalize}EmployerProfile",
          "event_object_id" => employer_profile.id
        }
      end
      let(:subject) do
        Notifier::NoticeBuilder::DummyNoticeKind.new(event_name: event_name, title: 'Test', notice_number: "ABC_123")
      end

      describe ".store_paper_notice" do
        let(:bucket_name) { 'paper-notices' }
        let(:notice_filename_for_paper_notice) { "#{employer_profile.organization.hbx_id}_#{subject.title}_#{subject.notice_number.delete('_')}_#{subject.notice_type}.pdf" }
        let(:doc_uri) { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}#sample-key" }
        let(:notice_path_for_paper_notice) { Rails.root.join("tmp", notice_filename_for_paper_notice) }

        before do
          allow(FileUtils).to receive(:cp)
          allow(File).to receive(:delete)
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