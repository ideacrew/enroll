require 'rails_helper'

module BenefitSponsors
  RSpec.describe Inboxes::MessagesController, type: :controller, dbclean: :after_each do

    routes {BenefitSponsors::Engine.routes}
    let!(:security_question)  { FactoryBot.create_default :security_question }

    let!(:site) {FactoryBot.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, site_key: :cca)}

    let(:organization) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site)}
    let(:inbox) {FactoryBot.create(:benefit_sponsors_inbox, :with_message, recipient: organization.employer_profile)}
    let(:person) {FactoryBot.create(:person)}
    let(:user) {FactoryBot.create(:user, :person => person)}

    let(:broker_organization) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site)}
    let(:broker_person) { FactoryBot.create(:person, :with_broker_role) }
    let(:broker_user) { FactoryBot.create(:user, person: broker_person ) }

    let(:admin_person) {FactoryBot.create(:person)}
    let(:admin_user) {FactoryBot.create(:user, :person => admin_person)}
    let(:hbx_staff_role) {FactoryBot.create(:hbx_staff_role, person: admin_user.person)}

    before do
      Person.skip_callback(:save, :after, :trigger_primary_subscriber_publish)
    end

    after do
      Person.set_callback(:save, :after, :trigger_primary_subscriber_publish)
    end

    describe "GET show / DELETE destroy" do
      context "redirect show message if user not signed in" do
        before do
          get :show, params: {id: organization.employer_profile.id, message_id: inbox.messages.first.id}
        end

        it "should render sign in page" do
          expect(response).to redirect_to('http://test.host/users/sign_in')
        end

        it "should return http failure" do
          expect(response).to have_http_status(:redirect)
        end
      end

      context "for employer profile" do
        before do
          sign_in user
        end

        context "show message" do
          before do
            get :show, params: {id: organization.employer_profile.id, message_id: inbox.messages.first.id}
          end

          it "should render show template" do
            expect(response).to render_template("show")
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end
        end

        context "delete message" do
          before do
            delete :destroy, params: {id: organization.employer_profile.id, message_id: inbox.messages.first.id}, format: :js
          end

          it "should get a notice" do
            expect(flash[:notice]).to match /Successfully deleted inbox message./
          end
        end

      end

      context "for broker agency profile" do
        before do
          broker_person.broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_organization.broker_agency_profile.id)
          @broker_inbox = broker_person.build_inbox
          @broker_inbox.save!
          welcome_subject = "Welcome to #{Settings.site.short_name}"
          welcome_body = "#{Settings.site.short_name} is the #{Settings.aca.state_name}'s on-line marketplace to shop, compare, and select health insurance that meets your health needs and budgets."
          broker_message = @broker_inbox.messages.create(subject: welcome_subject, body: welcome_body)
          sign_in broker_user
        end

        context "show message" do
          before do
            get :show, params: {id: broker_person.id, message_id: @broker_inbox.messages.first.id}
          end

          it "should render show template" do
            expect(response).to render_template("show")
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end
        end

        context "delete message" do
          before do
            delete :destroy, params: {id: broker_person.id, message_id: @broker_inbox.messages.first.id}, format: :js
          end

          it "should get a notice" do

            expect(flash[:notice]).to match /Successfully deleted inbox message./
          end
        end
      end

      context "for broker agency profile - from Admin login" do
        before do
          broker_person.broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_organization.broker_agency_profile.id)
          @broker_inbox = broker_person.build_inbox
          @broker_inbox.save!
          welcome_subject = "Welcome to #{Settings.site.short_name}"
          welcome_body = "#{Settings.site.short_name} is the #{Settings.aca.state_name}'s on-line marketplace to shop, compare, and select health insurance that meets your health needs and budgets."
          broker_message = @broker_inbox.messages.create(subject: welcome_subject, body: welcome_body)
          sign_in admin_user
        end

        context "show message" do
          before do
            get :show, params:{id: broker_person.id, message_id: @broker_inbox.messages.first.id}
          end

          it "should render show template" do
            expect(response).to render_template("show")
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end
        end

        context "delete message" do
          before do
            delete :destroy, params:{id: broker_person.id, message_id: @broker_inbox.messages.first.id}, format: :js
          end

          it "should get a notice" do
            expect(flash[:notice]).to match /Successfully deleted inbox message./
          end
        end
      end
    end
  end
end
