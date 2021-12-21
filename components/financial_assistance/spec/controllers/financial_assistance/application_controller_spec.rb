# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::ApplicationController, dbclean: :after_each, type: :controller do
  let(:person) { FactoryBot.create(:person, :with_consumer_role)}
  let!(:user) { FactoryBot.create(:user, :person => person) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:family_id) { family.id}
  let(:application) { FactoryBot.create(:application, family_id: family_id, effective_date: TimeKeeper.date_of_record) }
  let(:params) {application.id}

  describe "#find_application" do
    context "hbx_admin" do
      let(:admin_user) { FactoryBot.create(:user, person: admin_person) }
      let(:admin_person) { FactoryBot.create(:person, :with_hbx_staff_role) }

      before do
        sign_in(admin_user)
        allow(controller).to receive(:params).and_return(application_id: application.id)
        allow(controller).to receive(:session).and_return(person_id: person.id)
      end

      it "finds the correct application" do
        expect(controller.send(:find_application)).to eq(application)
      end
    end

    context "user with the applications_controller" do
      before do
        sign_in(user)
        allow(controller).to receive(:params).and_return(id: application.id)
      end

      it "finds the correct application" do
        expect(controller.send(:find_application)).to eq(application)
      end
    end

    context "user with the other controllers" do
      before do
        sign_in(user)
        allow(controller).to receive(:params).and_return(application_id: application.id)
      end

      it "finds the correct application" do
        expect(controller.send(:find_application)).to eq(application)
      end
    end
  end
end