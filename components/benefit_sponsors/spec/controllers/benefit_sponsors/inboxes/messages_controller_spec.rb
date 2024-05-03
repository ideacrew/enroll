require 'rails_helper'

module BenefitSponsors
  RSpec.describe Inboxes::MessagesController, type: :controller, dbclean: :after_each do

    routes {BenefitSponsors::Engine.routes}
    let!(:security_question)  { FactoryBot.create_default :security_question }

    let!(:site) {FactoryBot.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, site_key: :cca)}

    let(:organization) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, site: site)}
    let!(:active_employer_staff_role) {FactoryBot.create(:benefit_sponsor_employer_staff_role, aasm_state: 'is_active', benefit_sponsor_employer_profile_id: organization.employer_profile.id)}
    let(:inbox) {FactoryBot.create(:benefit_sponsors_inbox, :with_message, recipient: organization.employer_profile)}
    let(:person) {FactoryBot.create(:person, employer_staff_roles: [active_employer_staff_role])}
    let(:user) {FactoryBot.create(:user, :person => person)}

    let(:broker_organization) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site)}
    let(:broker_person) { FactoryBot.create(:person, :with_broker_role) }
    let(:broker_user) { FactoryBot.create(:user, person: broker_person ) }

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

        context "show message" do
          before do
            sign_in user
            get :show, params: {id: organization.employer_profile.id, message_id: inbox.messages.first.id}
          end

          it "should render show template" do
            expect(response).to render_template("show")
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end
        end

        context "does not show message without needed employer privileges" do
          it "should not render show template and raise a error" do
            person.employer_staff_roles = []
            person.save!
            sign_in user
            get :show, params: {id: organization.employer_profile.id, message_id: inbox.messages.first.id}
            expect(response).to_not have_http_status(:success)
          end
        end

        context "delete message" do
          before do
            sign_in user
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
          welcome_subject = "Welcome to #{EnrollRegistry[:enroll_app].setting(:short_name).item}"
          welcome_body = "#{EnrollRegistry[:enroll_app].setting(:short_name).item} is the #{Settings.aca.state_name}'s on-line marketplace to shop, compare, and select health insurance that meets your health needs and budgets."
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
        let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
        let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
        let(:user_of_family) { FactoryBot.create(:user, person: person) }
        let(:hbx_profile) do
          FactoryBot.create(
            :hbx_profile,
            :normal_ivl_open_enrollment,
            us_state_abbreviation: EnrollRegistry[:enroll_app].setting(:state_abbreviation).item,
            cms_id: "#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.upcase}0"
          )
        end
        let(:hbx_staff_person) { FactoryBot.create(:person) }
        let(:hbx_staff_role) do
          hbx_staff_person.create_hbx_staff_role(
            permission_id: permission.id,
            subrole: permission.name,
            hbx_profile: hbx_profile
          )
        end
        let(:hbx_admin_user) do
          FactoryBot.create(:user, person: hbx_staff_person)
          hbx_staff_role.person.user
        end

        let(:market_kind) { :both }
        let(:broker_person) { FactoryBot.create(:person) }
        let(:broker_role) { FactoryBot.create(:broker_role, person: broker_person) }
        let(:broker_user) { FactoryBot.create(:user, person: broker_person) }
        let(:message) { FactoryBot.create(:message, :inbox_folder, inbox: broker_person.inbox) }

        let(:site) do
          FactoryBot.create(
            :benefit_sponsors_site,
            :with_benefit_market,
            :as_hbx_profile,
            site_key: ::EnrollRegistry[:enroll_app].settings(:site_key).item
          )
        end

        let(:broker_agency_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
        let(:broker_agency_profile) { broker_agency_organization.broker_agency_profile }
        let(:broker_agency_id) { broker_agency_profile.id }

        let(:broker_agency_account) do
          family.broker_agency_accounts.create!(
            benefit_sponsors_broker_agency_profile_id: broker_agency_id,
            writing_agent_id: broker_role.id,
            is_active: baa_active,
            start_on: TimeKeeper.date_of_record
          )
        end

        let(:broker_staff_person) { FactoryBot.create(:person) }

        let(:broker_staff_state) { 'active' }

        let(:broker_staff) do
          FactoryBot.create(
            :broker_agency_staff_role,
            person: broker_staff_person,
            aasm_state: broker_staff_state,
            benefit_sponsors_broker_agency_profile_id: broker_agency_id
          )
        end
        let(:broker_staff_user) { FactoryBot.create(:user, person: broker_staff_person) }

        let(:permission) { FactoryBot.create(:permission, :super_admin) }

        before do
          broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
          broker_person.create_broker_agency_staff_role(
            benefit_sponsors_broker_agency_profile_id: broker_role.benefit_sponsors_broker_agency_profile_id
          )
          broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id, market_kind: market_kind)
          broker_role.approve!
          broker_staff
          sign_in broker_staff_user
        end

        context "show message" do
          before do
            get :show, params: { id: broker_role.person.id, message_id: message.id }
          end

          it "should render show template" do
            expect(response).to render_template("show")
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end
        end
      end
    end
  end
end
