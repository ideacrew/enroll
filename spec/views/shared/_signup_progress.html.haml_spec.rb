require 'rails_helper'

RSpec.describe "shared/_signup_progress.html.haml" do
  context "step 1" do
    before :each do
      render "shared/signup_progress"
    end

    it "shouldn't display the waive button" do
      expect(rendered).not_to have_selector('a', text: /Waive/)
    end
  end

  context "step 2" do
    before :each do
      render "shared/signup_progress", step: 2
    end

    it "shouldn't display the waive button" do
      expect(rendered).not_to have_selector('a', text: /Waive/)
    end
  end

  context "step 3" do
    before :each do
      render "shared/signup_progress", step: 3
    end

    it "shouldn't display the waive button" do
      expect(rendered).not_to have_selector('a', text: /Waive/)
    end
  end

  context "step 4" do
    before :each do
      render "shared/signup_progress", step: 4
    end

    it "shouldn't display the waive button" do
      expect(rendered).not_to have_selector('a', text: /Waive/)
    end
  end

  context "step 5" do
    before :each do
      render "shared/signup_progress", step: 5
    end

    it "should display the waive button" do
      expect(rendered).to have_selector('a', text: /Waive/)
    end
  end

  context "step 6" do
    let(:hbx_enrollment) { instance_double("HbxEnrollment", id: "hbx enrollment id") }
    let(:plan) { instance_double("Plan", id: "plan id") }
    before :each do
      assign(:enrollment, hbx_enrollment)
      assign(:enrollable, true)
      assign(:plan, plan)
    end

    it "should display the waive button" do
      render "shared/signup_progress", step: 6
      expect(rendered).to have_selector('a', text: /Waive/)
    end

    context "when enrollment cannot be completed" do
      before :each do
        assign(:enrollable, false)
      end

      it "should disable the purchase button" do
        render "shared/signup_progress", step: 6
        expect(rendered).to match /<a[^>]*disabled="disabled"[^>]*>Purchase/
      end
    end
  end

  context "step 7" do
    before :each do
      render "shared/signup_progress", step: 7
    end

    it "shouldn't display the waive button" do
      expect(rendered).not_to have_selector('a', text: /Waive/)
    end
  end
end
