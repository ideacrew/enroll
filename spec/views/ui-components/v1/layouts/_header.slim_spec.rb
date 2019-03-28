require 'rails_helper'

RSpec.describe "layouts/_header.html.erb" do
  describe "Header Styles" do
    context "when environment variable PRODUCTION is set to true" do
      it "does NOT render pre_prod_nav_color CSS class" do
        ClimateControl.modify PRODUCTION: "true" do
          visit root_url
          expect(page).to_not have_css("nav.pre_prod_nav_color")
        end
      end
    end

    context "when environment variable PRODUCTION is not set" do
      it "renders pre_prod_nav_color CSS class" do
        visit root_url
        expect(page).to have_css("nav.pre_prod_nav_color")
      end
    end
  end
end
