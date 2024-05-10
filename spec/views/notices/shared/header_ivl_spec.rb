# frozen_string_literal: true

require 'rails_helper'
if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe 'notices/shared/header_ivl.html.erb' do
    include Config::SiteHelper

    let!(:person) { FactoryBot.create(:person) }
    let(:local_data) { {recipient: person} }

    before :each do
      render template: 'notices/shared/header_ivl', locals: local_data
    end

    context 'for matching text' do
      it { expect(rendered).to match(/#{l10n("notices.shared.your_id_is", site_short_name: site_short_name, hbx_id: person.hbx_id)}/) }
      it { expect(rendered).to match(/#{l10n("notices.shared.page")}/) }
      it { expect(rendered).to match(/#{l10n("notices.shared.of")}/) }
    end
  end
end
