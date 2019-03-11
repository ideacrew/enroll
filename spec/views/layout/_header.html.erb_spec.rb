require 'rails_helper'

RSpec.describe "layouts/_header.html.erb" do
  describe "Header Styles" do
    context "settings set to deployed_to_production" do
      before do
        allow(Settings.site).to receive(:deployed_to_production).and_return(true)
      end

      it "does NOT render pre_prod_nav_color CSS class" do
        visit root_url
        expect(page).to_not have_css("nav.pre_prod_nav_color")
      end
    end

    context "setting NOT set to deployed_to_production" do
      before do
        allow(Settings.site).to receive(:deployed_to_production).and_return(false)
      end

      it "renders pre_prod_nav_color CSS class" do
        visit root_url
        expect(page).to have_css("nav.pre_prod_nav_color")
      end
    end
  end
end
