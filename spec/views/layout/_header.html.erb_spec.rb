require 'rails_helper'

RSpec.describe "layouts/_header.html.erb" do
  describe "Header Styles" do
    context "review_environmental variable set" do
      before do
        ENV['ENROLL_REVIEW_ENVIRONMENT'] = 'true'
      end

      it "renders pre_prod_nav_color CSS class" do
        visit root_url
        expect(page).to have_css("nav.pre_prod_nav_color")
      end
    end

    context "review_environmental variable NOT set" do
      before do
        ENV['ENROLL_REVIEW_ENVIRONMENT'] = 'false'
      end

      it "does not render pre_prod_nav_color CSS class" do
        visit root_url
        expect(page).to_not have_css("nav.pre_prod_nav_color")
      end
    end
  end
end
