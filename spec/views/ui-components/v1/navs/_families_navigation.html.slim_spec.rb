# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "_families_navigation.html.slim", :type => :view, dbclean: :after_each  do
  let(:person) {FactoryBot.create(:person, :with_consumer_role, :with_family)}
  let(:hbx_staff) {FactoryBot.create(:person, :with_hbx_staff_role)}
  let(:user) {FactoryBot.create(:user, person: hbx_staff)}
  let(:user1) {FactoryBot.create(:user, person: person)}

  describe "osse content" do
    before do
      assign(:person, person)
      assign(:employee_role, nil)
      assign(:family_members, nil)
      EnrollRegistry["aca_ivl_osse_subsidy"].feature.stub(:is_enabled).and_return(true)
    end

    context "login as an admin" do
      before do
        sign_in(user)
        render "ui-components/v1/navs/families_navigation.html.slim"
      end

      it "should display hc4cc text" do
        expect(rendered).to include(l10n("osse_eligibility"))
      end
    end

    context "login as a consumer" do
      before do
        sign_in(user1)
        render "ui-components/v1/navs/families_navigation.html.slim"
      end

      it "should not display hc4cc text" do
        expect(rendered).to_not include(l10n("osse_eligibility"))
      end
    end

    context "login as an admin, but the consumer does not have a consumer role" do
      before do
        sign_in(user)
        person.consumer_role = nil
        person.save
        render "ui-components/v1/navs/families_navigation.html.slim"
      end

      it "should not display hc4cc text" do
        expect(rendered).to_not include(l10n("osse_eligibility"))
      end
    end
  end
end