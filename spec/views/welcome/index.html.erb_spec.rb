require 'rails_helper'

RSpec.describe "welcome/index.html.erb", :type => :view, dbclean: :after_each  do
  let(:user) { FactoryBot.create(:user, oim_id: "test@enroll.com") }

  unless EnrollRegistry[:enroll_app].setting(:site_key).item == :cca
    describe "a signed in user" do
      before :each do
        sign_in user
      end
      it "should has current_user oim_id" do
        render
        # expect(rendered).to match /#{user.oim_id}/
        expect(rendered).not_to match(/Broker Registration/)
        expect(rendered).not_to match(/General Agency Registration/)
      end
    end
  end

  describe "not signed in user" do
    xcontext "with general agency enabled" do
      before :each do
        allow(EnrollRegistry[:general_agency].feature).to receive(:is_enabled).and_return(true)
        Enroll::Application.reload_routes!
        render
      end
      it "shows registration if not signed in" do
        expect(rendered).to match(/Broker Registration/)
        expect(rendered).to match(/General Agency Registration/)
      end
    end

    xcontext "with general agency disabled" do
      before :each do
        allow(view).to receive(:general_agency_enabled?).and_return(false)
        render
      end
      it "does not show general agency related links" do
        expect(rendered).not_to match(/General Agency Registration/)
        expect(rendered).not_to match(/General Agency Portal/)
      end
    end

    xcontext "with enabled IVL market" do
      before do
        # TODO: We need to refactor Settings.aca.market_kinds stuff
        allow(Settings.aca).to receive(:market_kinds).and_return(%w[individual shop])
        Enroll::Application.reload_routes!
        allow(EnrollRegistry[:medicaid_tax_credits_link].feature).to receive(:is_enabled).and_return(true)

        # allow(view).to receive(:general_agency_enabled?).and_return(false)
        render
      end

      it "shows the Consumer portal link" do
        expect(rendered).to have_link('Consumer/Family Portal')
      end

      it "shows the Assistest consumer portal link" do
        expect(rendered).to have_link('Assisted Consumer/Family Portal')
      end
    end

    context "with disabled IVL market" do
      before do
        # allow(view).to receive(:general_agency_enabled?).and_return(false)
        allow(view).to receive(:individual_market_is_enabled?).and_return(false)
        allow(EnrollRegistry[:medicaid_tax_credits_link].feature).to receive(:is_enabled).and_return(false)
        render
      end
      it "does not show the Consumer portal links" do
        expect(rendered).not_to have_link('Consumer/Family Portal')
      end
      it "does not show the Assisted consumer portal link" do
        expect(rendered).not_to have_link('Assisted Consumer/Family Portal')
      end
    end
  end
end
