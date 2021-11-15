require "rails_helper"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
RSpec.describe ConsumerRolesHelper, :type => :helper do
  let(:person) {FactoryBot.build(:person)}
  let(:consumer_role) {FactoryBot.build(:consumer_role)}
  before :each do
    allow(person).to receive(:consumer_role).and_return consumer_role
    allow(consumer_role).to receive(:person).and_return person
  end

  context "find_consumer_role_for_fields" do
    it "should return consumer_role from person" do
      expect(helper.find_consumer_role_for_fields(person)).to eq consumer_role
    end

    context "dependent" do
      let(:dependent) {double}
      it "should return new consumer_role" do
        allow(dependent).to receive(:persisted?).and_return false
        expect(helper.find_consumer_role_for_fields(dependent).new_record?).to eq true
      end

      it "should return new consumer_role without family member" do
        allow(dependent).to receive(:persisted?).and_return true
        allow(dependent).to receive(:family_member).and_return false
        expect(helper.find_consumer_role_for_fields(dependent).new_record?).to eq true
      end

      it "should return consumer_role from family_member" do
        allow(dependent).to receive(:family_member).and_return double(person: person)
        allow(dependent).to receive(:persisted?).and_return true
        expect(helper.find_consumer_role_for_fields(dependent)).to eq consumer_role
      end
    end
  end

  context "#show_naturalized_citizen_container" do
    it "should return true" do
      person.us_citizen = true
      expect(helper.show_naturalized_citizen_container(person)).to eq true
    end

    it "should return false" do
      person.us_citizen = false
      expect(helper.show_naturalized_citizen_container(person)).to eq false
    end

    it "should return false" do
      person.us_citizen = nil
      expect(helper.show_naturalized_citizen_container(person)).to eq false
    end
  end

  context "#show_immigration_status_container" do
    it "should return true" do
      person.us_citizen = false
      expect(helper.show_immigration_status_container(person)).to eq true
    end

    it "should return false" do
      person.us_citizen = true
      expect(helper.show_immigration_status_container(person)).to eq false
    end
  end

  context "#show_tribal_container" do
    it "should return true" do
      person.indian_tribe_member = true
      expect(helper.show_tribal_container(person)).to eq true
    end

    it "should return false" do
      person.indian_tribe_member = false
      expect(helper.show_tribal_container(person)).to eq false
    end

    it "should return false" do
      person.indian_tribe_member = nil
      expect(helper.show_tribal_container(person)).to eq false
    end
  end

  context "#show_naturalization_doc_type" do
    it "should return true" do
      person.us_citizen = true
      person.naturalized_citizen = true
      expect(helper.show_naturalization_doc_type(person)).to eq true
    end

    it "should return false" do
      person.us_citizen = false
      person.naturalized_citizen = true
      expect(helper.show_naturalization_doc_type(person)).to eq false
    end

    it "should return false" do
      person.us_citizen = true
      person.naturalized_citizen = false
      expect(helper.show_naturalization_doc_type(person)).to eq false
    end
  end

  context "#show_immigration_doc_type" do
    it "should return true" do
      person.us_citizen = false
      person.eligible_immigration_status = true
      expect(helper.show_immigration_doc_type(person)).to eq true
    end

    it "should return false" do
      person.us_citizen = true
      person.eligible_immigration_status = true
      expect(helper.show_immigration_doc_type(person)).to eq false
    end

    it "should return false" do
      person.us_citizen = false
      person.eligible_immigration_status = false
      expect(helper.show_immigration_doc_type(person)).to eq false
    end
  end

  context "show_vlp_documents_container" do
    it "should return true" do
      allow(helper).to receive(:show_naturalization_doc_type).and_return true
      allow(helper).to receive(:show_immigration_doc_type).and_return false
      expect(helper.show_vlp_documents_container(person)).to eq true
    end

    it "should return true" do
      allow(helper).to receive(:show_naturalization_doc_type).and_return false
      allow(helper).to receive(:show_immigration_doc_type).and_return true
      expect(helper.show_vlp_documents_container(person)).to eq true
    end

    it "should return false" do
      allow(helper).to receive(:show_naturalization_doc_type).and_return false
      allow(helper).to receive(:show_immigration_doc_type).and_return false
      expect(helper.show_vlp_documents_container(person)).to eq false
    end
  end

  context "show_keep_existing_plan" do
    let(:date) { TimeKeeper.date_of_record }
    let(:hbx_enrollment) {HbxEnrollment.new(effective_on: date, kind: 'individual')}
    let(:shop_hbx) {HbxEnrollment.new(effective_on: date, kind: 'employer_sponsored')}

    it "should return true when hbx_enrollment is shop" do
      expect(helper.show_keep_existing_plan("shop_for_plans", shop_hbx, date)).to eq true
      expect(helper.show_keep_existing_plan("", shop_hbx, date)).to eq true
    end

    it "should return false with shop_for_plans" do
      expect(helper.show_keep_existing_plan("shop_for_plans", hbx_enrollment, date)).to eq false
    end

    context "without shop_for_plans" do
      it "hbx_enrollment and new_effective_on is in the same year" do
        expect(helper.show_keep_existing_plan("", hbx_enrollment, date)).to eq true
      end

      it "hbx_enrollment and new_effective_on is not in the same year" do
        expect(helper.show_keep_existing_plan("", hbx_enrollment, (date + 1.year))).to eq false
      end
    end
  end

  context "ridp_redirection_link" do
    let(:person) {FactoryBot.build(:person, :with_consumer_role)}
    let(:family) { FactoryBot.build(:family)}
    let(:user) { FactoryBot.create(:user) }
    let(:current_user) { FactoryBot.create(:user, :person => person) }

    before :each do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(current_user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(person).to receive(:primary_family).and_return family
    end

    it "should return admin bookmark url" do
      allow(person.consumer_role).to receive(:identity_verified?).and_return true
      person.primary_family.update_attributes(application_type: 'Paper')
      consumer = person.consumer_role
      consumer.admin_bookmark_url = "/insured/ridp_agreement"
      person.save
      expect(helper.ridp_redirection_link(person)).to eq "/insured/ridp_agreement"
    end

    it "should return nil if identity is not verified and current user has not staff role" do
      allow(person.consumer_role).to receive(:identity_verified?).and_return false
      person.primary_family.update_attributes(application_type: 'In Person')
      consumer = person.consumer_role
      consumer.admin_bookmark_url = "/insured/ridp_agreement"
      person.save
      expect(helper.ridp_redirection_link(person)).to eq nil
    end
  end

end
end