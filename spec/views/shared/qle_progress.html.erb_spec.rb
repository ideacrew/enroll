require 'rails_helper'

describe "shared/_qle_progress.html.erb" do
  let(:plan) { FactoryBot.build(:plan) }
  let(:enrollment) { double(id: 'hbx_id') }
  let(:person) { FactoryBot.create(:person)}
  context "step 1" do
    before :each do
      assign :change_plan, "change"
      allow(person).to receive(:consumer_role).and_return(true)
      @person=person
      render 'shared/qle_progress', step: '1'
    end

    it "should have li option for Plan Selection" do
      expect(rendered).to have_selector("li", text: "Plan Selection")
    end

    it "should have li option for household" do
      expect(rendered).to have_selector("li", text: "Household")
    end

    it "should have 25% complete" do
      expect(rendered).to match /25%/
    end
  end

  context "step 3" do
    before :each do
      assign :change_plan, "change"
      assign :plan, plan
      assign :enrollment, enrollment
      allow(person).to receive(:consumer_role).and_return(false)
      @person = person
      render 'shared/qle_progress', step: '3'
    end

    it "should have 75% complete" do
      expect(rendered).to match /75%/
    end

    it "should have li option for household" do
      expect(rendered).to have_selector("li", text: "Household")
    end

    it "should have purchase button" do
      expect(rendered).to have_selector('a', text: 'Confirm')
    end

    it "should have previous option" do
      expect(rendered).to match /PREVIOUS/i
    end

    it "should not have disabled link" do
      expect(rendered).not_to have_selector('a.disabled')
    end
  end

  context "step 3 Consumer" do
    before :each do
      assign :change_plan, "change"
      assign :plan, plan
      assign :enrollment, enrollment
      allow(person).to receive(:consumer_role).and_return(true)
      @person = person
      render 'shared/qle_progress', step: '3', kind: 'individual'
    end

    it "should have 75% complete" do
      expect(rendered).to match /75%/
    end

    it "should have li option for household" do
      expect(rendered).to have_selector("li", text: "Household")
    end

    it "should have purchase button" do
      expect(rendered).to have_selector('a', text: 'Confirm')
    end

    it "should have previous option" do
      expect(rendered).to match /PREVIOUS/i
    end

    it "should have disabled link" do
      expect(rendered).to have_selector('a.disabled')
    end
  end
end
