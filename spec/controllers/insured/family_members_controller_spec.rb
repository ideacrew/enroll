# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Insured::FamilyMembersController, dbclean: :after_each do
  let(:test_family) { FactoryBot.build(:family, :with_primary_family_member) }
  let(:person) { test_family.primary_family_member.person }
  let(:user) { FactoryBot.create(:user) }

  let(:qle) { FactoryBot.create(:qualifying_life_event_kind) }
  let(:published_plan_year)  { FactoryBot.build(:plan_year, aasm_state: :published)}
  let(:employer_profile) { FactoryBot.create(:employer_profile) }
  let(:employee_role) { FactoryBot.create(:employee_role, employer_profile: employer_profile, person: person) }
  let(:employee_role_id) { employee_role.id }
  let(:census_employee) { FactoryBot.create(:census_employee) }

  before do
    # A relationship between the user and the person is established here mostly due to the new requirements from the FamilyMemberPolicy
    user.update(person: person)

    employer_profile.plan_years << published_plan_year
    employer_profile.save
  end

  describe "GET index" do
    before do
      # NOTE: this inclusion needed to be made due to the limitations of Factory relationships
      allow(person).to receive(:primary_family).and_return(test_family)
    end

    context 'normal' do
      before(:each) do
        allow(person).to receive(:broker_role).and_return(nil)
        allow(user).to receive(:person).and_return(person)
        allow(user).to receive(:has_hbx_staff_role?).and_return(false)
        sign_in(user)
        allow(controller.request).to receive(:referer).and_return('http://dchealthlink.com/insured/interactive_identity_verifications')
        get :index, params: { employee_role_id: employee_role_id }
      end

      it "renders the 'index' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("index")
      end

      it "assigns the person" do
        expect(assigns(:person)).to eq person
      end

      it "assigns the family" do
        # I'm not sure why this test ever expected for the controller to assign `family` to equal nil
        # the _family_members partial rendered in the `index` view will throw an error if @family is nil
        expect(assigns(:family)).to eq test_family
      end
    end

    context 'with no referer' do
      before(:each) do
        allow(person).to receive(:broker_role).and_return(nil)
        allow(user).to receive(:person).and_return(person)
        allow(user).to receive(:has_hbx_staff_role?).and_return(false)
        sign_in(user)
        allow(controller.request).to receive(:referer).and_return(nil)
        get :index, params: {employee_role_id: employee_role_id}
      end

      it "renders the 'index' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("index")
      end

      it "assigns the person" do
        expect(assigns(:person)).to eq person
      end

      it "assigns the family" do
        # I'm not sure why this test ever expected for the controller to assign `family` to equal nil
        # the _family_members partial rendered in the `index` view will throw an error if @family is nil
        expect(assigns(:family)).to eq test_family
      end
    end

    # Some times Effective dates vary even for the next day. So creating a new SEP & re-calculating effective on dates
    context "with sep_id in params" do

      subject { Observers::NoticeObserver.new }

      let(:sep) { FactoryBot.create :special_enrollment_period, family: test_family }
      let(:dup_sep) { double("SpecialEnrPeriod", qle_on: TimeKeeper.date_of_record - 5.days) }

      before :each do
        allow(person).to receive(:broker_role).and_return(nil)
        allow(user).to receive(:person).and_return(person)
        allow(user).to receive(:has_hbx_staff_role?).and_return(false)
        sign_in(user)
        allow(controller).to receive(:validate_address_params).and_return []
        allow(controller.request).to receive(:referer).and_return(nil)
      end

      it "should not duplicate sep if using current sep on same day" do
        get :index, params: {sep_id: sep.id, qle_id: sep.qualifying_life_event_kind_id}
        expect(assigns(:sep)).to eq sep
      end

      context "when using old active sep" do

        before do
          sep.update_attributes(submitted_at: TimeKeeper.datetime_of_record - 1.day)
        end

        it "should assign with old sep" do
          get :index, params: {sep_id: sep.id, qle_id: sep.qualifying_life_event_kind_id}
          expect(assigns(:sep)).to eq sep
        end

        it "should not duplicate sep" do
          get :index, params: {sep_id: sep.id, qle_id: sep.qualifying_life_event_kind_id}
          expect(assigns(:sep)).to_not eq dup_sep
        end

        it "should not have the today's date as submitted_at" do
          get :index, params: {sep_id: sep.id, qle_id: sep.qualifying_life_event_kind_id}
          expect(assigns(:sep).submitted_at.to_date).to_not eq TimeKeeper.date_of_record
        end

        context "when using expired active sep" do

          let(:active_qle) do
            create(:qualifying_life_event_kind, title: "Married", market_kind: "shop", reason: "marriage", start_on: TimeKeeper.date_of_record.prev_month.beginning_of_month, end_on: TimeKeeper.date_of_record.next_month.end_of_month)
          end

          before do
            sep.update_attributes(qualifying_life_event_kind_id: active_qle.id, submitted_at: TimeKeeper.datetime_of_record - 1.day, created_at: sep.created_at - 2.day)
            active_qle.update_attributes(is_active: false, end_on: TimeKeeper.date_of_record - 1.day)
          end

          it "should assign with old sep" do
            get :index, params: {sep_id: sep.id, qle_id: sep.qualifying_life_event_kind_id}
            expect(assigns(:sep)).to eq sep
          end

          it "should not duplicate sep" do
            get :index, params: {sep_id: sep.id, qle_id: sep.qualifying_life_event_kind_id}
            expect(assigns(:sep)).to_not eq dup_sep
          end

          it "should not have the today's date as submitted_at" do
            get :index, params: {sep_id: sep.id, qle_id: sep.qualifying_life_event_kind_id}
            expect(assigns(:sep).submitted_at.to_date).to_not eq TimeKeeper.date_of_record
          end
        end

        it "qle market kind is should be shop" do
          expect(qle.market_kind).to eq "shop"
        end
      end
    end

    it "with qle_id" do
      allow(person).to receive(:primary_family).and_return(test_family)
      allow(person).to receive(:broker_role).and_return(nil)
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(employee_role).to receive(:save!).and_return(true)
      allow(employer_profile).to receive(:published_plan_year).and_return(published_plan_year)
      sign_in user
      allow(controller).to receive(:validate_address_params).and_return []
      allow(controller.request).to receive(:referer).and_return('http://dchealthlink.com/insured/interactive_identity_verifications')
      expect do
        get :index, params: {employee_role_id: employee_role_id, qle_id: qle.id, effective_on_kind: 'date_of_event', qle_date: '10/10/2015', published_plan_year: '10/10/2015'}
      end.to change(test_family.special_enrollment_periods, :count).by(1)
    end
  end

  describe "GET show" do
    let(:dependent) { double("Dependent", family_id: '1') }
    let(:family_member) {double("FamilyMember", id: double("id"))}

    before(:each) do
      allow(Forms::FamilyMember).to receive(:find).and_return(dependent)
      allow(dependent).to receive(:family_id).and_return(test_family.id)
      allow(Family).to receive(:find).with(dependent.family_id).and_return(test_family)
      sign_in(user)
      get :show, params: {id: family_member.id}
    end

    it "should render show templage" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("show")
    end
  end

  describe "GET new" do
    let(:family_id) { "addbedddedtotallyafamiyid" }
    let(:dependent) { double }

    before(:each) do
      sign_in(user)
      allow(Forms::FamilyMember).to receive(:new).with({:family_id => family_id}).and_return(dependent)

      # the following line needed to be added to pass the test after the FamilyMemberPolicy was added
      allow(Family).to receive(:find).with(family_id).and_return(test_family)

      get :new, params: { family_id: family_id }
    end

    it "renders the 'new' template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("new")
    end

    it "assigns the dependent" do
      expect(assigns(:dependent)).to eq dependent
    end
  end

  describe "POST create" do
    let(:address) { double }
    let(:valid_addresses_attributes) do
      {"0" => {"kind" => "home", "address_1" => "address1_a", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211"},
       "1" => {"kind" => "mailing", "address_1" => "address1_b", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211" } }
    end
    let(:invalid_addresses_attributes) do
      {"0" => {"kind" => "home", "address_1" => "address1_a", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "222"},
       "1" => {"kind" => "mailing", "address_1" => "test", "address_2" => "", "city" => "test", "state" => "DC", "zip" => "223"} }
    end
    let(:dependent_properties) { {addresses: valid_addresses_attributes, :family_id => test_family.id, same_with_primary: "false" } }
    let(:save_result) { false }
    let!(:test_family) { FactoryBot.create(:family, :with_primary_family_member) }

    describe "with an invalid dependent" do
      before :each do
        sign_in(user)
        # No Resident Role
        allow_any_instance_of(Forms::FamilyMember).to receive(:save).and_return(save_result)
        post :create, params: {dependent: dependent_properties}, :format => "js"
      end

      it "should assign the dependent" do
        expect(assigns(:dependent).class).to eq(Forms::FamilyMember)
        expect(assigns(:dependent).family_id).to eq(test_family.id.to_s)
      end

      it "should render the new template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("new")
      end
    end

    describe "with a duplicate dependent" do
      let(:test_person) { FactoryBot.create(:person, :with_nuclear_family) }
      let(:duplicate_test_family) { test_person.primary_family }
      let(:test_user) { FactoryBot.create(:user) }
      let(:target_dependent) do
        duplicate_test_family.dependents.detect { |dependent| dependent.relationship == 'child' }
      end
      let(:duplicate_dependent_attributes) do
        {
          dependent: {
            family_id: duplicate_test_family.id,
            first_name: target_dependent.first_name,
            last_name: target_dependent.last_name,
            relationship: target_dependent.relationship,
            gender: target_dependent.gender,
            dob: "#{target_dependent.dob.year}-#{target_dependent.dob.month}-#{target_dependent.dob.day}"
          }
        }
      end
      before :each do
        test_user.update(person: test_person)
        sign_in(test_user)
        # No Resident Role

        post :create, params: duplicate_dependent_attributes, :format => "js"
      end

      it "should redirect to families home after detecting duplicate dependent" do
        alert_message = l10n(
          'insured.family_members.duplicate_error_message',
          action: "add",
          contact_center_phone_number: EnrollRegistry[:enroll_app].settings(:contact_center_short_number).item
        )
        expect(assigns(:dependent).errors[:base]).to include(alert_message)
      end

      context "when readding the deleted dependent" do
        before do
          target_dependent.update_attributes(is_active: false)
          sign_in(test_user)
          post :create, params: duplicate_dependent_attributes, :format => "js"
        end

        it "should not see the duplicate dependent error" do
          alert_message = l10n('insured.family_members.duplicate_error_message',
                               action: "add",
                               contact_center_phone_number: EnrollRegistry[:enroll_app].settings(:contact_center_short_number).item)
          expect(assigns(:dependent).errors[:base]).not_to include(alert_message)
        end
      end
    end

    describe "with a valid dependent" do
      let(:save_result) { true }

      before :each do
        sign_in(user)
        # No resident role
        allow_any_instance_of(Forms::FamilyMember).to receive(:save).and_return(save_result)
        post :create, params: {dependent: dependent_properties}, :format => "js"
      end

      it "should assign the dependent" do
        expect(assigns(:dependent).class).to eq(Forms::FamilyMember)
        expect(assigns(:dependent).family_id).to eq(test_family.id.to_s)
      end

      it "should assign the created" do
        expect(assigns(:created)).to eq true
      end

      it "should render the show template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("show")
      end
    end

    describe "with a valid dependent but not applying for coverage" do
      let(:save_result) { true }
      let(:dependent_properties) { { "is_applying_coverage" => "false", "same_with_primary" => "true", "family_id" => test_family.id.to_s } }
      let(:test_family) { FactoryBot.create(:family, :with_primary_family_member)}

      before :each do
        sign_in(user)
        # No resident role
        allow_any_instance_of(Forms::FamilyMember).to receive(:save).and_return(save_result)
        post :create, params: {dependent: dependent_properties}, :format => "js"
      end

      it "should assign the dependent" do
        expect(assigns(:dependent).class).to eq ::Forms::FamilyMember
        expect(assigns(:dependent).family_id).to eq(test_family.id.to_s)
      end

      it "should assign the created" do
        expect(assigns(:created)).to eq true
      end

      it "should render the show template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("show")
      end
    end

    describe "when update_vlp_documents failed" do
      before :each do
        allow(person).to receive(:user).and_return(user)
        allow(Family).to receive(:find).with(dependent_properties[:family_id]).and_return(test_family)
        sign_in(user)
        allow(controller).to receive(:update_vlp_documents).and_return false
        post :create, params: {dependent: dependent_properties}, :format => "js"
      end

      it "should render the new template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("new")
      end

      it "should get addresses as an array" do
        expect(response).to render_template("new")
        expect(assigns(:dependent).addresses.class).to eq Array
      end
    end

    describe "with a valid dependent but invalid addresses" do
      before :each do
        allow(person).to receive(:user).and_return(user)
        allow(Family).to receive(:find).with(dependent_properties[:family_id]).and_return(test_family)
        allow(controller).to receive(:update_vlp_documents).and_return false
        sign_in(user)
        post :create, params: {dependent: dependent_properties}, :format => "js"
      end

      let(:address_errors) {[{:zip => ["Home Addresses: zip should be in the form: 12345 or 12345-1234"]}, {:zip => ["Mailing Addresses: zip should be in the form: 12345 or 12345-1234"]}]}

      let(:dependent) { double(addresses: [invalid_addresses_attributes], family_member: true, same_with_primary: true) }
      let(:dependent_properties) { {addresses: invalid_addresses_attributes, :family_id => test_family.id, same_with_primary: "false" } }
      let!(:test_family) { FactoryBot.create(:family, :with_primary_family_member) }


      it "should assign the dependent" do
        expect(assigns(:dependent).class).to eq Forms::FamilyMember
        expect(assigns(:dependent).family_id).to eq(test_family.id.to_s)
      end

      it "should not assign the created" do
        expect(assigns(:created)).to eq nil
      end

      it "should assign the address_errors" do
        expect(assigns(:address_errors)).to eq address_errors
      end

      it "should render the new template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("new")
      end
    end
  end

  describe "DELETE destroy" do
    let(:dependent) { double(family_id: test_family.id) }
    let(:dependent_id) { "234dlfjadsklfj" }

    before :each do
      sign_in(user)
      allow(Family).to receive(:find).with(dependent.family_id).and_return(test_family)
    end

    it "should destroy the dependent" do
      allow(Forms::FamilyMember).to receive(:find).with(dependent_id).and_return(dependent)
      expect(dependent).to receive(:destroy!)
      delete :destroy, params: {id: dependent_id}
    end

    it "should render the index template" do
      allow(Forms::FamilyMember).to receive(:find).with(dependent_id).and_return(dependent)
      allow(dependent).to receive(:destroy!)
      delete :destroy, params: {id: dependent_id}
      expect(response).to have_http_status(:success)
      expect(response).to render_template("index")
    end

    context "Delete Duplicate FM members" do
      let(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent) }
      let(:test_person) { family.primary_person }
      let(:test_user) { FactoryBot.create(:user) }
      let(:dependent1) { family.family_members.where(is_primary_applicant: false).first }
      let(:dependent2) { family.family_members.where(is_primary_applicant: false).last }
      let!(:duplicate_family_member_1) do
        family.family_members << FamilyMember.new(person_id: dependent1.person.id)
        dup_fm = family.family_members.last
        dup_fm.save(validate: false)
        dup_fm
      end
      let!(:duplicate_family_member_2) do
        family.family_members << FamilyMember.new(person_id: dependent1.person.id)
        dup_fm = family.family_members.last
        dup_fm.save(validate: false)
        dup_fm
      end

      before do
        test_user.update(person: test_person)
        sign_in(test_user)
        allow(Family).to receive(:find).and_return(family)
      end

      it 'should destroy the duplicate dependents if exists' do
        expect(family.family_members.active.count).to eq 5
        delete :destroy, params: {id: dependent1.id}
        expect(response).to have_http_status(:success)
        family.reload
        expect(family.family_members.active.count).to eq 3
      end

    end
  end

  describe "GET edit" do
    let(:dependent) { double(family_member: double, family_id: test_family.id) }
    let(:dependent_id) { "234dlfjadsklfj" }

    before :each do
      sign_in(user)
      allow(Forms::FamilyMember).to receive(:find).with(dependent_id).and_return(dependent)
      allow(Family).to receive(:find).with(dependent.family_id).and_return(test_family)
      get :edit, params: {id: dependent_id}
    end

    it "should assign the dependent" do
      expect(assigns(:dependent)).to eq dependent
    end

    it "should render the edit template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("edit")
    end
  end

  describe "PUT update" do
    let(:address) { double }
    let(:family_member) { double }
    let(:valid_addresses_attributes) do
      {"0" => {"kind" => "home", "address_1" => "address1_a", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211"},
       "1" => {"kind" => "mailing", "address_1" => "address1_b", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211" } }
    end
    let(:invalid_addresses_attributes) do
      {"0" => {"kind" => "home", "address_1" => "address1_a", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "222"},
       "1" => {"kind" => "mailing", "address_1" => "test", "address_2" => "", "city" => "test", "state" => "DC", "zip" => "223"} }
    end
    let(:dependent) { double(addresses: [valid_addresses_attributes], family_member: true, same_with_primary: true) }
    let(:dependent_properties) do
      {
        addresses: valid_addresses_attributes,
        :family_id => test_family.id,
        same_with_primary: true
      }
    end
    let(:invalid_dependent_properties) do
      {
        addresses: invalid_addresses_attributes,
        :family_id => test_family.id,
        same_with_primary: false
      }
    end

    let(:update_result) { false }
    let!(:test_family) { FactoryBot.create(:family, :with_primary_family_member) }

    before(:each) do
      sign_in(user)
    end

    describe "with an invalid dependent" do
      it "should render the edit template" do
        put :update, params: {id: test_family.family_members.last.id.to_s, dependent: invalid_dependent_properties}
        expect(response).to have_http_status(:success)
        expect(response).to render_template("edit")
      end

      it "addresses should be an array" do
        put :update, params: {id: test_family.family_members.last.id.to_s, dependent: invalid_dependent_properties}
        expect(assigns(:dependent).addresses.class).to eq Array
      end
    end

    describe "with a valid dependent" do
      let(:update_result) { true }
      it "should render the show template" do
        allow(controller).to receive(:update_vlp_documents).and_return(true)
        put :update, params: {id: test_family.family_members.last.id.to_s, dependent: dependent_properties}
        expect(response).to have_http_status(:success)
        expect(response).to render_template("show")
      end

      it "should render the edit template when update_vlp_documents failure" do
        allow(controller).to receive(:update_vlp_documents).and_return(false)
        put :update, params: {id: test_family.family_members.last.id.to_s, dependent: dependent_properties}
        expect(response).to have_http_status(:success)
        expect(response).to render_template("edit")
      end
    end

    describe "with a valid dependent but invalid addresses" do
      before :each do
        allow(controller).to receive(:update_vlp_documents).and_return false
      end

      let(:address_errors) {[{:zip => ["Home Addresses: zip should be in the form: 12345 or 12345-1234"]}, {:zip => ["Mailing Addresses: zip should be in the form: 12345 or 12345-1234"]}]}

      let(:dependent) { double(addresses: [invalid_addresses_attributes], family_member: true, same_with_primary: true) }
      let(:dependent_properties) { ActionController::Parameters.new({addresses: invalid_addresses_attributes, :family_id => "saldjfalkdjf", same_with_primary: "false" }).permit! }

      it "should render the edit template" do
        put :update, params: {id: test_family.family_members.last.id.to_s, dependent: dependent_properties}
        expect(response).to have_http_status(:success)
        expect(response).to render_template("edit")
      end

      it "should assign the address_errors" do
        put :update, params: {id: test_family.family_members.last.id.to_s, dependent: dependent_properties}
        expect(assigns(:address_errors)).to eq address_errors
      end
    end
  end

  context 'permissions' do
    # this var will only be used in the CREATE and UPDATE permissions-related tests
    let(:dependent_properties) { { "is_applying_coverage" => "false", "same_with_primary" => "true", "family_id" => test_family.id.to_s } }

    before :each do
      allow(controller.request).to receive(:referer).and_return(nil)
      allow(Family).to receive(:find).with(test_family.id).and_return(test_family)
    end

    context 'a user without permissions' do
      let(:fake_person) { FactoryBot.create(:person, :with_consumer_role) }
      let(:fake_user) { FactoryBot.create(:user, :person => fake_person) }

      # let(:fake_family) { FactoryBot.create(:family, :with_primary_family_member, person: fake_person) }
      let(:fake_family) { FactoryBot.create(:family, :with_nuclear_family, person: fake_person) }
      let(:fake_family_member) { fake_family.family_members.first }
      let(:fake_employer_profile) { FactoryBot.create(:employer_profile) }
      let(:fake_employee_role) { FactoryBot.create(:employee_role, employer_profile: fake_employer_profile, person: fake_person) }
      let(:fake_employee_role_id) { fake_employee_role.id }

      before :each do
        sign_in(fake_user)
      end

      context 'index' do
        before do
          # NOTE: this inclusion needed to be made due to the limitations of Factory relationships
          allow(fake_person).to receive(:primary_family).and_return(test_family)
        end

        it "can't view another user's family_members index page" do
          get :index, params: { employee_role_id: employee_role_id }

          expect(response).to have_http_status(:redirect)
          expect(response).to_not render_template("index")
        end
      end

      context 'create' do
        it "can't create family members on behalf of another user" do
          post :create, params: { dependent: dependent_properties }

          expect(response).to have_http_status(:redirect)
          expect(response).to_not render_template("show")
          expect(response).to_not render_template("new")
          expect(assigns(:created)).to eq nil
        end
      end

      context 'new, show, edit, update, destroy' do
        let(:dependent) { double("Dependent", family_id: test_family.id) }
        let(:dependent_id) { "234dlfjadsklfj" }

        before do
          allow(Forms::FamilyMember).to receive(:find).and_return(dependent)
          allow(Family).to receive(:find).with(dependent.family_id).and_return(test_family)
          allow(dependent).to receive(:destroy!)
        end

        it "can't update family members on behalf of another user" do
          put :update, params: { id: dependent_id, dependent: dependent_properties }

          expect(response).to have_http_status(:redirect)
          expect(response).to_not render_template("show")
          expect(response).to_not render_template("edit")
        end

        it "can't delete family members on behalf of another user" do
          delete :destroy, params: { id: dependent_id }

          expect(response).to have_http_status(:redirect)
          expect(response).to_not render_template("index")
        end

        it "family_member :new template will not render" do
          get :new, params: { family_id: test_family.id }

          expect(response).to have_http_status(:redirect)
          expect(response).to_not render_template("new")
        end

        it "family_member :show template will not render" do
          get :show, params: { id: test_family.id }

          expect(response).to have_http_status(:redirect)
          expect(response).to_not render_template("show")
        end

        it "family_member :edit template will not render" do
          get :edit, params: { id: dependent_id }

          expect(response).to have_http_status(:redirect)
          expect(response).to_not render_template("edit")
        end
      end
    end

    context 'a super_admin' do
      let!(:admin_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
      let!(:admin_user) { FactoryBot.create(:user, :with_hbx_staff_role, :person => admin_person) }
      let!(:update_admin) { admin_person.hbx_staff_role.update_attributes(permission_id: permission.id) }

      before :each do
        sign_in(admin_user)
      end

      context 'index' do
        before do
          # NOTE: this inclusion needed to be made due to the limitations of Factory relationships
          allow(person).to receive(:primary_family).and_return(test_family)
        end

        context 'with permissions' do
          let!(:permission) { FactoryBot.create(:permission, :super_admin) }

          it "can't view another user's family_members index page" do
            # only including employer_id to avoid initializing more factories
            get :index, params: { employee_role_id: employee_role_id, family_id: test_family.id }

            expect(response).to have_http_status(:success)
            expect(response).to render_template("index")
          end
        end

        context 'without permissions' do
          let!(:permission) { FactoryBot.create(:permission, :developer) }

          it "can't view another user's family_members index page" do
            # only including employer_id to avoid initializing more factories
            get :index, params: { employee_role_id: employee_role_id, family_id: test_family.id }

            expect(response).to have_http_status(:redirect)
            expect(response).to_not render_template("index")
          end
        end
      end

      context 'create' do
        context 'with permissions' do
          let!(:permission) { FactoryBot.create(:permission, :super_admin) }

          it "can create family members on behalf of another user" do
            allow_any_instance_of(Forms::FamilyMember).to receive(:save).and_return(true)
            post :create, params: { dependent: dependent_properties }, :format => "js"

            expect(response).to have_http_status(:success)
            expect(response).to render_template("show")
          end
        end

        context 'without permissions' do
          let!(:permission) { FactoryBot.create(:permission, :developer) }

          it "can't create family members on behalf of another user" do
            post :create, params: { dependent: dependent_properties }

            expect(response).to have_http_status(:redirect)
            expect(response).to_not render_template("show")
            expect(response).to_not render_template("new")
            expect(assigns(:created)).to eq nil
          end
        end
      end

      context 'new, show, edit, update, destroy' do
        let(:valid_addresses_attributes) do
          {"0" => {"kind" => "home", "address_1" => "address1_a", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211"},
           "1" => {"kind" => "mailing", "address_1" => "address1_b", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211" } }
        end
        let(:dependent) { double(addresses: [valid_addresses_attributes], family_member: true, same_with_primary: true, family_id: test_family.id).as_null_object }
        let(:dependent_properties) do
          {
            addresses: valid_addresses_attributes,
            :family_id => test_family.id,
            same_with_primary: true
          }
        end
        let(:dependent_id) { "234dlfjadsklfj" }

        before do
          allow(Forms::FamilyMember).to receive(:find).and_return(dependent)
          allow(Family).to receive(:find).with(dependent.family_id).and_return(test_family)
          allow(dependent).to receive(:destroy!)
        end

        context 'with permissions' do
          let!(:permission) { FactoryBot.create(:permission, :super_admin) }

          it "can update family members for a user" do
            put :update, params: { id: dependent_id, dependent: dependent_properties }

            expect(response).to have_http_status(:success)
            expect(response).to render_template("show")
          end

          it "can delete family members for a user" do
            delete :destroy, params: { id: dependent_id }

            expect(response).to have_http_status(:success)
            expect(response).to render_template("index")
          end

          it "family_member :new template will render" do
            get :new, params: { family_id: test_family.id }

            expect(response).to have_http_status(:success)
            expect(response).to render_template("new")
          end

          it "family_member :show template will render" do
            get :show, params: { id: test_family.id }

            expect(response).to have_http_status(:success)
            expect(response).to render_template("show")
          end

          it "family_member :edit template will render" do
            get :edit, params: { id: dependent_id }

            expect(response).to have_http_status(:success)
            expect(response).to render_template("edit")
          end
        end

        context 'without permissions' do
          let!(:permission) { FactoryBot.create(:permission, :developer) }

          it "can't update family members for a user" do
            allow(controller).to receive(:update_vlp_documents).and_return(true)
            put :update, params: { id: dependent_id, dependent: dependent_properties }

            expect(response).to have_http_status(:redirect)
            expect(response).to_not render_template("show")
            expect(response).to_not render_template("edit")
          end

          it "can't delete family members for a user" do
            delete :destroy, params: { id: dependent_id }

            expect(response).to have_http_status(:redirect)
            expect(response).to_not render_template("index")
          end

          it "family_member :new template will not render" do
            get :new, params: { family_id: test_family.id }

            expect(response).to have_http_status(:redirect)
            expect(response).to_not render_template("new")
          end

          it "family_member :show template will not render" do
            get :show, params: { id: test_family.id }

            expect(response).to have_http_status(:redirect)
            expect(response).to_not render_template("show")
          end

          it "family_member :edit template will not render" do
            get :edit, params: { id: dependent_id }

            expect(response).to have_http_status(:redirect)
            expect(response).to_not render_template("edit")
          end
        end
      end
    end

    context 'a broker' do
      let!(:broker_user) { FactoryBot.create(:user, :person => writing_agent.person, roles: ['broker_role', 'broker_agency_staff_role']) }
      let(:broker_agency_profile) { FactoryBot.build(:benefit_sponsors_organizations_broker_agency_profile)}
      let(:writing_agent)         { FactoryBot.create(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id) }
      let(:assister)  do
        assister = FactoryBot.build(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, npn: "SMECDOA00")
        assister.save(validate: false)
        assister
      end

      before :each do
        sign_in(broker_user)
      end

      context 'index' do
        before do
          # NOTE: this inclusion needed to be made due to the limitations of Factory relationships
          allow(person).to receive(:primary_family).and_return(test_family)
        end

        context 'with permissions/hired by family' do
          before(:each) do
            test_family.broker_agency_accounts << BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id,
                                                                                                     writing_agent_id: writing_agent.id,
                                                                                                     start_on: Time.now,
                                                                                                     is_active: true)
          end

          it "can't view another user's family_members index page" do
            # only including employer_id to avoid initializing more factories
            get :index, params: { employee_role_id: employee_role_id, family_id: test_family.id }

            expect(response).to have_http_status(:success)
            expect(response).to render_template("index")
          end
        end

        context 'without permissions/not hired by family' do
          it "can't view another user's family_members index page" do
            # only including employer_id to avoid initializing more factories
            get :index, params: { employee_role_id: employee_role_id, family_id: test_family.id }

            expect(response).to have_http_status(:redirect)
            expect(response).to_not render_template("index")
          end
        end
      end

      context 'create' do
        context 'with permissions/hired by family' do
          before(:each) do
            test_family.broker_agency_accounts << BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id,
                                                                                                     writing_agent_id: writing_agent.id,
                                                                                                     start_on: Time.now,
                                                                                                     is_active: true)
          end

          it "can create family members on behalf of another user" do
            allow_any_instance_of(Forms::FamilyMember).to receive(:save).and_return(true)
            post :create, params: { dependent: dependent_properties }, :format => "js"

            expect(response).to have_http_status(:success)
            expect(response).to render_template("show")
          end
        end

        context 'without permissions/not hired by family' do
          it "can't create family members on behalf of another user" do
            post :create, params: { dependent: dependent_properties }

            expect(response).to have_http_status(:redirect)
            expect(response).to_not render_template("show")
            expect(response).to_not render_template("new")
            expect(assigns(:created)).to eq nil
          end
        end
      end

      context 'new, show, edit, update, destroy' do
        let(:valid_addresses_attributes) do
          {"0" => {"kind" => "home", "address_1" => "address1_a", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211"},
           "1" => {"kind" => "mailing", "address_1" => "address1_b", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211" } }
        end
        let(:dependent) { double(addresses: [valid_addresses_attributes], family_member: true, same_with_primary: true, family_id: test_family.id).as_null_object }
        let(:dependent_properties) do
          {
            addresses: valid_addresses_attributes,
            :family_id => test_family.id,
            same_with_primary: true
          }
        end
        let(:dependent_id) { "234dlfjadsklfj" }

        before do
          allow(Forms::FamilyMember).to receive(:find).and_return(dependent)
          allow(Family).to receive(:find).with(dependent.family_id).and_return(test_family)
          allow(dependent).to receive(:destroy!)
        end

        context 'with permissions/hired by family' do
          before(:each) do
            test_family.broker_agency_accounts << BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id,
                                                                                                     writing_agent_id: writing_agent.id,
                                                                                                     start_on: Time.now,
                                                                                                     is_active: true)
          end

          it "can update family members for a user" do
            put :update, params: { id: dependent_id, dependent: dependent_properties }

            expect(response).to have_http_status(:success)
            expect(response).to render_template("show")
          end

          it "can delete family members for a user" do
            delete :destroy, params: { id: dependent_id }

            expect(response).to have_http_status(:success)
            expect(response).to render_template("index")
          end

          it "family_member :new template will render" do
            get :new, params: { family_id: test_family.id }

            expect(response).to have_http_status(:success)
            expect(response).to render_template("new")
          end

          it "family_member :show template will render" do
            get :show, params: { id: test_family.id }

            expect(response).to have_http_status(:success)
            expect(response).to render_template("show")
          end

          it "family_member :edit template will render" do
            get :edit, params: { id: dependent_id }

            expect(response).to have_http_status(:success)
            expect(response).to render_template("edit")
          end
        end

        context 'without permissions/not hired by family' do
          it "can't update family members for a user" do
            allow(controller).to receive(:update_vlp_documents).and_return(true)
            put :update, params: { id: dependent_id, dependent: dependent_properties }

            expect(response).to have_http_status(:redirect)
            expect(response).to_not render_template("show")
            expect(response).to_not render_template("edit")
          end

          it "can't delete family members for a user" do
            delete :destroy, params: { id: dependent_id }

            expect(response).to have_http_status(:redirect)
            expect(response).to_not render_template("index")
          end

          it "family_member :new template will not render" do
            get :new, params: { family_id: test_family.id }

            expect(response).to have_http_status(:redirect)
            expect(response).to_not render_template("new")
          end

          it "family_member :show template will not render" do
            get :show, params: { id: test_family.id }

            expect(response).to have_http_status(:redirect)
            expect(response).to_not render_template("show")
          end

          it "family_member :edit template will not render" do
            get :edit, params: { id: dependent_id }

            expect(response).to have_http_status(:redirect)
            expect(response).to_not render_template("edit")
          end
        end
      end
    end
  end
end