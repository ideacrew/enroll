require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe EmployerProfilePolicy, dbclean: :after_each do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"
    let(:profile) { benefit_sponsorship.organization.profiles.first }

    let(:policy) { BenefitSponsors::EmployerProfilePolicy.new(user, benefit_sponsorship.organization.profiles.first) }
    let(:person) { FactoryBot.create(:person) }

    context 'for a user with no role' do
      let(:user) { FactoryBot.create(:user, person: person) }

      shared_examples_for "should not permit for invalid user" do |policy_type|
        it "should not permit" do
          expect(policy.send(policy_type)).not_to be true
        end
      end

      it_behaves_like "should not permit for invalid user", :show?
    end

    context 'for a user with ER role' do
      let(:user) { FactoryBot.create(:user, person: person) }
      let(:er_staff_role) { FactoryBot.create(:benefit_sponsor_employer_staff_role, benefit_sponsor_employer_profile_id: benefit_sponsorship.organization.employer_profile.id) }

      shared_examples_for "should not permit for invalid user" do |policy_type|
        it "should permit for active ER staff role" do
          person.employer_staff_roles << er_staff_role
          expect(policy.send(policy_type)).to be true
        end

        it "should not permit for inactive ER staff role" do
          er_staff_role.update_attributes(aasm_state: "is_closed")
          person.employer_staff_roles << er_staff_role
          expect(policy.send(policy_type)).not_to be true
        end
      end

      it_behaves_like "should not permit for invalid user", :show?
    end

    describe '#show?' do
      let(:user) { FactoryBot.create(:user, person: person) }

      context 'when user does not exist' do
        let(:user) { nil }

        it 'should not authorize access' do
          expect(policy.show?).to be_falsey
        end
      end

      context 'when user exists without any staff role' do
        it 'should not authorize access' do
          expect(policy.show?).to be_falsey
        end
      end

      context 'when current user exists with staff role' do
        let!(:hbx_staff_role) do
          person.create_hbx_staff_role(benefit_sponsor_hbx_profile_id: BSON::ObjectId.new, hbx_profile_id: BSON::ObjectId.new)
        end

        it 'should authorize access' do
          expect(policy.show?).to be_truthy
        end
      end

      context 'when current user exists with broker role' do
        let(:person) { FactoryBot.create(:person, :with_broker_role) }
        let(:broker_agency_account) { double('broker_agency_account', writing_agent_id: person.broker_role.id) }

        before do
          allow(profile).to receive(:broker_agency_accounts).and_return([broker_agency_account])
        end

        it 'should authorize access' do
          expect(policy.show?).to be_truthy
        end
      end

      context 'when current user exists with general agency staff role' do
        let(:person) { FactoryBot.create(:person) }
        let(:ga_staff_role) { FactoryBot.create(:general_agency_staff_role, aasm_state: :active, person: person) }
        let(:general_agency_account) do
          double(
            'general_agency_account',
            benefit_sponsrship_general_agency_profile_id: ga_staff_role.benefit_sponsors_general_agency_profile_id
          )
        end

        before do
          allow(profile).to receive(:general_agency_accounts).and_return([general_agency_account])
        end

        it 'should authorize access' do
          expect(policy.show?).to be_truthy
        end
      end

      context 'when current user exists with broker agency staff role' do
        let(:person) { FactoryBot.create(:person) }

        let(:broker_staff_role) do
          person.broker_agency_staff_roles.create(aasm_state: :active, benefit_sponsors_broker_agency_profile_id: BSON::ObjectId.new)
        end

        let(:broker_agency_account) do
          double(
            'broker_agency_account',
            benefit_sponsors_broker_agency_profile_id: broker_staff_role.benefit_sponsors_broker_agency_profile_id
          )
        end

        before do
          allow(profile).to receive(:broker_agency_accounts).and_return([broker_agency_account])
        end

        it 'should authorize access' do
          expect(policy.show?).to be_truthy
        end
      end

      context 'when current user exists with employer staff role' do
        let(:person) { FactoryBot.create(:person) }
        let!(:employer_staff_role) do
          person.employer_staff_roles.create(aasm_state: :is_active, benefit_sponsor_employer_profile_id: profile.id)
        end

        it 'should authorize access' do
          expect(policy.show?).to be_truthy
        end
      end
    end

    describe '#coverage_reports?' do
      let(:user) { FactoryBot.create(:user, person: person) }

      context 'when user does not exist' do
        let(:user) { nil }

        it 'should not authorize access' do
          expect(policy.coverage_reports?).to be_falsey
        end
      end

      context 'when user exists without any staff role' do
        it 'should not authorize access' do
          expect(policy.coverage_reports?).to be_falsey
        end
      end

      context 'when current user exists with staff role without list_enrollments permission' do
        let!(:hbx_staff_role) do
          person.create_hbx_staff_role(benefit_sponsor_hbx_profile_id: BSON::ObjectId.new, hbx_profile_id: BSON::ObjectId.new)
        end
        let(:permission) { double('permission', list_enrollments: false) }

        before do
          allow(hbx_staff_role).to receive(:permission).and_return(permission)
        end

        it 'should not authorize access' do
          expect(policy.coverage_reports?).to be_falsey
        end
      end

      context 'when current user exists with staff role with list_enrollments permission' do
        let(:hbx_staff_role) do
          person.create_hbx_staff_role(benefit_sponsor_hbx_profile_id: BSON::ObjectId.new, hbx_profile_id: BSON::ObjectId.new)
        end
        let(:permission) { double('permission', list_enrollments: true) }

        before do
          allow(hbx_staff_role).to receive(:permission).and_return(permission)
        end

        it 'should authorize access' do
          expect(policy.coverage_reports?).to be_truthy
        end
      end

      context 'when current user exists with broker role' do
        let(:person) { FactoryBot.create(:person, :with_broker_role) }
        let(:broker_agency_account) { double('broker_agency_account', writing_agent_id: person.broker_role.id) }

        before do
          allow(profile).to receive(:broker_agency_accounts).and_return([broker_agency_account])
        end

        it 'should authorize access' do
          expect(policy.coverage_reports?).to be_truthy
        end
      end

      context 'when current user exists with general agency staff role' do
        let(:person) { FactoryBot.create(:person) }
        let(:ga_staff_role) { FactoryBot.create(:general_agency_staff_role, aasm_state: :active, person: person) }
        let(:general_agency_account) do
          double(
            'general_agency_account',
            benefit_sponsrship_general_agency_profile_id: ga_staff_role.benefit_sponsors_general_agency_profile_id
          )
        end

        before do
          allow(profile).to receive(:general_agency_accounts).and_return([general_agency_account])
        end

        it 'should authorize access' do
          expect(policy.coverage_reports?).to be_truthy
        end
      end

      context 'when current user exists with broker agency staff role' do
        let(:person) { FactoryBot.create(:person) }

        let(:broker_staff_role) do
          person.broker_agency_staff_roles.create(aasm_state: :active, benefit_sponsors_broker_agency_profile_id: BSON::ObjectId.new)
        end

        let(:broker_agency_account) do
          double(
            'broker_agency_account',
            benefit_sponsors_broker_agency_profile_id: broker_staff_role.benefit_sponsors_broker_agency_profile_id
          )
        end

        before do
          allow(profile).to receive(:broker_agency_accounts).and_return([broker_agency_account])
        end

        it 'should authorize access' do
          expect(policy.coverage_reports?).to be_truthy
        end
      end

      context 'when current user exists with employer staff role' do
        let(:person) { FactoryBot.create(:person) }
        let!(:employer_staff_role) do
          person.employer_staff_roles.create(aasm_state: :is_active, benefit_sponsor_employer_profile_id: profile.id)
        end

        it 'should authorize access' do
          expect(policy.coverage_reports?).to be_truthy
        end
      end
    end

    context '#can_download_document?' do
      let(:er_staff_role) { FactoryBot.create(:benefit_sponsor_employer_staff_role, benefit_sponsor_employer_profile_id: benefit_sponsorship.organization.employer_profile.id) }
      let(:user) { FactoryBot.create(:user, person: person) }

      context 'authorized employer staff' do
        before do
          person.employer_staff_roles << er_staff_role
          person.save!
        end

        it 'employer staff should be able to update' do
          expect(policy.can_download_document?).to be true
        end
      end

      context 'unauthorized employer staff' do
        it 'employer staff should not be able to update' do
          expect(policy.can_download_document?).to be false
        end
      end
    end
  end
end
