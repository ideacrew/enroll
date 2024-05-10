# frozen_string_literal: true

require 'rails_helper'
if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe 'notices/shared/footer_ivl.html.erb' do
    include Config::SiteHelper

    let!(:person) { FactoryBot.create(:person) }
    let(:notice) { instance_double("PdfTemplates::ConditionalEligibilityNotice") }
    let(:hbe) { instance_double("PdfTemplates::Hbe") }
    let(:phone) { "1-800-555-5555" }
    let(:local_data) { {notice: notice} }

    before :each do
      allow(notice).to receive(:hbe).and_return(hbe)
      allow(hbe).to receive(:phone).and_return(phone)
      render template: 'notices/shared/footer_ivl', locals: local_data
    end

    context 'for matching text' do
      it { expect(rendered).to match(/(#{l10n("notices.shared.questions_call", site_short_name: site_short_name, phone: phone, website: site_website_name.downcase)})*/) }
    end
  end
end
