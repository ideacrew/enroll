require "rails_helper"

describe Forms::BulkActionsForAdmin, ".cancel_enrollments" do

  let(:params) { {
    :family_actions_id => "family_actions_5824903a7af880f17a000009",
    :family_id => "5824903a7af880f17a000009",
    :commit => "Submit",
    :controller => "exchanges/hbx_profiles",
    :action => "update_cancel_enrollment"}
  }

  subject {
    Forms::BulkActionsForAdmin.new(params)
  }

  context 'initialize new form model with the params from the controller' do

    it "should store the value of params[:family_id] in the @family_id variable" do
      expect(subject.family_id).to eq(params[:family_id])
    end

    it "should store the value of params[:family_actions_id] in the @row variable" do
      expect(subject.row).to eq(params[:family_actions_id])
    end

    it "should store the value of params[:result] in the @row variable" do
      expect(subject.row).to eq(params[:family_actions_id])
    end
  end

  context ".transition_family_members" do
    let(:consumer_person) {FactoryGirl.create(:person, :with_resident_role)}
    let!(:consumer_role_person) { consumer_person.consumer_role }
    let(:consumer_family) { FactoryGirl.create(:family, :with_primary_family_member, person: consumer_person) }
    let!(:individual_market_transition) { FactoryGirl.create(:individual_market_transition, person: consumer_person) }
    let(:qle) {FactoryGirl.create(:qualifying_life_event_kind, title: "Not eligible for marketplace coverage due to citizenship or immigration status", reason: "eligibility_failed_or_documents_not_received_by_due_date ")}

    let(:consumer_params) {
      {
        "transition_effective_date_#{consumer_person.id}" => TimeKeeper.date_of_record.to_s,
        "transition_user_#{consumer_person.id}" => consumer_person.id,
        "transition_market_kind_#{consumer_person.id}" => "consumer",
        "transition_reason_#{consumer_person.id}" => "eligibility_failed_or_documents_not_received_by_due_date",
        "family_actions_id" => "family_actions_#{consumer_family.id}",
        :family => consumer_family.id,
        "qle_id" => qle.id
      }
    }

    it "should create a consumer_role for given person" do
      expect(consumer_role_person).to be nil
      Forms::BulkActionsForAdmin.new(consumer_params).transition_family_members
      consumer_person.reload
      expect(consumer_person.consumer_role.class).to eq ConsumerRole
    end

    it "should not create a consumer_role as the person already has one" do
      FactoryGirl.create(:consumer_role, person: consumer_person)
      consumer_role = consumer_person.consumer_role
      expect(consumer_person.consumer_role.class).to eq ConsumerRole
      expect{Forms::BulkActionsForAdmin.new(consumer_params).transition_family_members}.not_to raise_error
      expect(consumer_person.consumer_role).to eq consumer_role
    end
  end
end
