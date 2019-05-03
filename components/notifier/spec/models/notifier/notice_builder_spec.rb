require 'rails_helper'

module Notifier
  RSpec.describe Notifier::NoticeBuilder, type: :model, dbclean: :after_each do

    context "when notice body is pdf" do
      let!(:notice_builder) {Notifier::NoticeKind.create(title: "test", notice_number: "IVL_PRE", recipient: "Notifier::MergeDataModels::ConsumerRole", event_name: "projected_eligibility_notice", market_kind: :aca_individual)}

      it "should not raise error" do
        notice_builder.template = Notifier::Template.new(raw_body: "test")
        notice_builder.save!
        expect(notice_builder.generate_pdf_notice).not_to be nil
      end

      it "should return true" do
        expect(notice_builder.correct_content_type).to be true
      end
    end

    context "Notice body is not pdf" do
      let!(:notice_builder) {Notifier::NoticeKind.create(title: "test", notice_number: "IVL_PRE", recipient: "Notifier::MergeDataModels::ConsumerRole", event_name: "projected_eligibility_notice", market_kind: :aca_individual)}

      it "should raise error" do
        notice_builder.template = Notifier::Template.new(raw_body: "test")
        notice_builder.save!
        allow(notice_builder).to receive(:correct_content_type).and_return(false)
        expect{notice_builder.generate_pdf_notice}.to raise_error "Notice body is empty or not pdf"
      end
    end
  end
end
