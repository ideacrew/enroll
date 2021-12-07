# frozen_string_literal: true

require 'rails_helper'
require 'aasm/rspec'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe "views/benefit_sponsors/benefit_applications/benefit_applications/edit.html.slim", :type => :view, dbclean: :after_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month + 1 }
  let(:effective_on) { current_effective_date }
  let(:aasm_state) { :active }
  let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.last.benefit_packages.first.health_sponsored_benefit}
  let(:employer_profile) { benefit_sponsorship.profile }
  let(:user) { FactoryBot.create(:user) }

  before :each do
    benefit_sponsorship.benefit_applications.last.benefit_packages.first.health_sponsored_benefit.delete
    benefit_sponsorship.reload
    form = BenefitSponsors::Forms::BenefitApplicationForm.for_edit({id: benefit_sponsorship.benefit_applications.last.id, benefit_sponsorship_id: benefit_sponsorship.id})
    view.extend Pundit
    view.extend ApplicationHelper
    view.extend BenefitSponsors::Engine.routes.url_helpers
    view.extend BenefitSponsors::Employers::EmployerHelper
    view.extend BenefitSponsors::ApplicationHelper

    assign(:benefit_application_form, form)
    allow(view).to receive(:product_rates_available?).and_return(true)
    allow(view).to receive(:benefit_sponsorship_benefit_application_path).and_return('/')
    # view.should_receive(:render).with(hash_including(:partial => "form")).and_return("<span id=\"rendered-form\"/>")
    allow(view).to receive(:render).and_return("<span id=\"rendered-form\"/>")
    sign_in user
    render template: "benefit_sponsors/benefit_applications/benefit_applications/edit"
  end

  it 'should not show Reference Plans if health sponsored benefits does not present' do
    expect(rendered).to_not match(/Reference Plans/)
  end
end
