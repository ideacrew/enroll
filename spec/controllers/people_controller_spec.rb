# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PeopleController, dbclean: :after_each do
  let(:email) {FactoryBot.build(:email)}
  let(:consumer_role){FactoryBot.build(:consumer_role, :contact_method => "Paper Only")}
  let(:census_employee){FactoryBot.build(:census_employee)}
  let(:employee_role){FactoryBot.build(:employee_role, :census_employee => census_employee)}
  let(:person) { FactoryBot.create(:person) }
  let(:user) { FactoryBot.create(:user, person: person) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:vlp_document){FactoryBot.build(:vlp_document)}

  before do
    family
    consumer_role.move_identity_documents_to_verified
  end

  describe "different roles" do
    let!(:permission)                           { FactoryBot.create(:permission, :hbx_staff) }
    let!(:person_with_hbx_staff_role)           { FactoryBot.create(:person, :with_hbx_staff_role)}
    let!(:hack_to_get_the_correct_permission)   { person_with_hbx_staff_role.hbx_staff_role.permission_id = permission.id}
    let!(:hbx_staff_user)                       { FactoryBot.create(:user, :person => person_with_hbx_staff_role) }
    let!(:other_user)                           { FactoryBot.create(:user) }

    it "should allow hbx staff to show person" do
      sign_in hbx_staff_user
      get :show, params: {id: person.id}
      expect(response).to have_http_status(:success)
    end

    it "should not allow cross person review" do
      sign_in other_user
      get :show, params: {id: person.id}
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST update" do
    let(:vlp_documents_attributes) { {"1" => vlp_document.attributes.to_hash}}
    let(:consumer_role_attributes) { consumer_role.attributes.to_hash}
    let(:person_attributes) { person.attributes.to_hash}
    let(:email_attributes) { {"0" => {"kind" => "home", "address" => "test@example.com"}}}
    let(:addresses_attributes) do
      {"0" => {"kind" => "home", "address_1" => "address1_a", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211", "county" => "test", "id" => person.addresses[0].id.to_s},
       "1" => {"kind" => "mailing", "address_1" => "address1_b", "address_2" => "", "city" => "city1", "state" => "DC", "zip" => "22211", "county" => "test", "id" => person.addresses[1].id.to_s} }
    end

    before :each do
      allow(Person).to receive(:find).and_return(person)
      allow(Person).to receive(:where).and_return(Person)
      allow(Person).to receive(:first).and_return(person)
      allow(controller).to receive(:sanitize_person_params).and_return(true)
      allow(person).to receive(:consumer_role).and_return(consumer_role)
      allow(person).to receive(:employee_roles).and_return [employee_role]
      allow_any_instance_of(VlpDoc).to receive(:sensitive_info_changed?).and_return([false, false])
      allow(person).to receive(:is_consumer_role_active?).and_return(false)
      allow(EnrollRegistry[:aca_shop_market].feature).to receive(:is_enabled).and_return(true)
      person_attributes[:addresses_attributes] = addresses_attributes
      person_attributes[:consumer_role_attributes] = consumer_role_attributes

      sign_in user
      post :update, params: {id: person.id, person: person_attributes}
    end

    describe "native status" do
      let!(:ai_an_person) {FactoryBot.create(:person, :with_consumer_role, tribal_id: '123')}
      let!(:ai_an_person_params) {ai_an_person.attributes.to_hash.merge(:is_applying_coverage => "true") }
      let!(:ai_an_family) { FactoryBot.create(:family, :with_primary_family_member, person: ai_an_person) }
      let!(:hbx_enrollment_member) do
        FactoryBot.build(:hbx_enrollment_member,
                         is_subscriber: true,
                         applicant_id: ai_an_family.family_members.first.id,
                         coverage_start_on: TimeKeeper.date_of_record.beginning_of_month,
                         eligibility_date: TimeKeeper.date_of_record.beginning_of_month)
      end
      let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, hbx_enrollment_members: [hbx_enrollment_member], family: ai_an_family, household: ai_an_family.latest_household, is_active: true) }

      let!(:user2) { FactoryBot.create(:user, person: ai_an_person) }

      before :each do
        allow(Person).to receive(:find).and_return(ai_an_person)
        ai_an_person.consumer_role.move_identity_documents_to_verified
        ai_an_person.consumer_role.coverage_purchased
        request.env['HTTP_REFERER'] = "insured/families/personal"
        allow(ai_an_person).to receive(:is_consumer_role_active?).and_return(true)

        sign_in user2
      end

      context "when native status has changed" do

        before do
          allow_any_instance_of(VlpDoc).to receive(:native_status_changed?).and_return(true)
          post :update, params: {id: ai_an_person.id, person: ai_an_person_params}
        end

        it "fails native status" do
          ai_an_person.reload
          expect(ai_an_person.consumer_role.workflow_state_transitions.first.event).to eql('fail_native_status!')
        end
      end

      context "when native status has not changed" do
        before do
          allow_any_instance_of(VlpDoc).to receive(:native_status_changed?).and_return(false)
          post :update, params: {id: ai_an_person.id, person: ai_an_person_params}
        end

        it "does not fail native status" do
          ai_an_person.reload
          expect(ai_an_person.consumer_role.workflow_state_transitions.first.event).to_not eql('fail_native_status!')
        end
      end
    end

    context "to verify if addresses are updated?" do

      it "should not create new address instances on update" do
        expect(assigns(:valid_vlp)).to be_nil
        expect(person.addresses.count).to eq 2
      end

      it "should not empty the person's addresses on update" do
        expect(assigns(:valid_vlp)).to be_nil
        expect(person.addresses).not_to eq []
      end

      it "should update county" do
        expect(person.addresses.first.county).to eq 'test'
      end
    end

    context "employee roles are updated" do
      it "should update active employee role's contact method to match consumer role contact method" do
        expect(person.consumer_role.contact_method).to eq(person.employee_roles.first.contact_method)
      end
    end

    context "when individual" do
      before do
        request.env['HTTP_REFERER'] = "insured/families/personal"
        allow(person).to receive(:is_consumer_role_active?).and_return(true)
      end
      it "update person" do
        allow(consumer_role).to receive(:find_document).and_return(vlp_document)
        allow(consumer_role).to receive(:check_for_critical_changes).and_return(true)
        allow(vlp_document).to receive(:save).and_return(true)
        allow(consumer_role).to receive(:check_native_status).and_return(true)
        consumer_role_attributes[:vlp_documents_attributes] = vlp_documents_attributes
        person_attributes[:consumer_role_attributes] = consumer_role_attributes
        post :update,  params: {id: person.id, person: person_attributes}
        expect(response).to redirect_to(personal_insured_families_path)
        expect(assigns(:person)).not_to be_nil
        expect(assigns(:valid_vlp)).to eq(true)
        expect(flash[:notice]).to eq 'Person was successfully updated.'
      end

      it "should update is_applying_coverage" do
        allow(person).to receive(:update_attributes).and_return(true)
        allow(consumer_role).to receive(:check_for_critical_changes).and_return(true)
        allow(consumer_role).to receive(:check_native_status).and_return(true)
        person_attributes.merge!({"is_applying_coverage" => "false"})

        post :update, params: {id: person.id, person: person_attributes}
        expect(assigns(:valid_vlp)).to eq(true)
        expect(assigns(:person).consumer_role.is_applying_coverage).to eq false
      end

      context 'person update failed' do
        let!(:invalid_vlp_doc) { FactoryBot.build(:vlp_document, subject: 'Other (With Alien Number)') }
        let!(:consumer_role_attributes) { person.consumer_role.attributes.to_hash}
        let!(:person_attributes) { person.attributes.to_hash}
        let!(:invalid_vlp_documents_attributes) { {"1" => invalid_vlp_doc.attributes.to_hash}}

        before do
          allow(person).to receive(:is_consumer_role_active?).and_return(true)
          allow(consumer_role).to receive(:check_for_critical_changes).and_return(true)
          consumer_role_attributes[:vlp_documents_attributes] = invalid_vlp_documents_attributes
          person_attributes[:consumer_role] = consumer_role_attributes
          post :update, params: {id: person.id, person: person_attributes}
        end

        it "should update is_applying_coverage" do
          expect(assigns(:valid_vlp)).to eq(false)
          expect(flash[:alert]).to include('Person update failed.')
        end
      end
    end

    context "when employee" do
      it "when employee" do
        person_attributes[:emails_attributes] = email_attributes
        allow(person).to receive(:update_attributes).and_return(true)

        post :update, params: {id: person.id, person: person_attributes}
        expect(response).to redirect_to(family_account_path)
        expect(flash[:notice]).to eq 'Person was successfully updated.'
      end
    end

    context "dependent lives with primary member" do
      let(:dependent) { FactoryBot.create(:person) }
      let(:address) { FactoryBot.create(:address, kind: "home", address_1: "address1_a", address_2: "", city: "city1", state: "DC", zip: "22211", person: dependent) }
      let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
      let(:family_member) { FactoryBot.create(:family_member, family: family, person: dependent) }
      let(:addresses_attributes2) do
        {
          "0" => { "kind" => "home",
                   "address_1" => "address1_changed",
                   "address_2" => "",
                   "city" => "city1",
                   "state" => "DC",
                   "zip" => "22211",
                   "id" => person.addresses[0].id.to_s },
          "1" => { "kind" => "mailing",
                   "address_1" => "address1_b",
                   "address_2" => "",
                   "city" => "city1",
                   "state" => "DC",
                   "zip" => "22211",
                   "id" => person.addresses[1].id.to_s }
        }
      end

      before do
        family.save
        family_member.save
        person.primary_family.reload

        person_attributes[:addresses_attributes] = addresses_attributes2
        post :update, params: {id: person.id, person: person_attributes}
      end

      it "when primary address is updated" do
        primary_address = person.addresses.select{|address| address.kind == 'home'}.first
        dependent_address = person.primary_family.family_members.reject(&:is_primary_applicant?).first.person.addresses.first
        expect(primary_address.same_address?(dependent_address)).to eq true
      end
    end
  end

  context 'populate county information on dependent address' do
    let(:person) { FactoryBot.create(:person, first_name: 'test', addresses: [address]) }
    let(:dependent) { FactoryBot.create(:person, addresses: [address]) }
    let(:address) { FactoryBot.build(:address, kind: "home", address_1: "address1_a", address_2: "", city: "city1", state: "ME", zip: "22211", county: "test") }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:family_member) { FactoryBot.create(:family_member, family: family, person: dependent) }
    let(:person_attributes) { person.attributes.to_hash}
    let(:addresses_attributes3) do
      {
        "0" => { "kind" => "home",
                 "address_1" => "address1_changed",
                 "address_2" => "",
                 "city" => "city1",
                 "state" => "ME",
                 "zip" => "22111",
                 "county" => "test_3",
                 "id" => person.addresses[0].id.to_s }
      }
    end

    before do
      family.save
      family_member.save
      person.primary_family.reload
      allow(person).to receive(:primary_family).and_return(family)
      person_attributes[:addresses_attributes] = addresses_attributes3
    end

    it "when primary address is updated with county information" do
      sign_in(user)
      post :update, params: { id: person.id, person: person_attributes }

      person.reload
      dependent.reload
      primary_address = person.addresses.select{|address| address.kind == 'home'}.first
      dependent_address = dependent.addresses.first
      expect(primary_address.same_address?(dependent_address)).to eq true
      expect(primary_address.county).to eq dependent_address.county
    end
  end
end
