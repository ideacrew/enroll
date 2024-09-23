require "rails_helper"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  describe ConsumerRolePolicy, dbclean: :after_each do
    subject { described_class }
    let(:consumer_role) { FactoryBot.create(:consumer_role) }
    let(:consumer_person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:broker_person) { FactoryBot.create(:person, :with_broker_role) }
    let(:assister_person) { FactoryBot.create(:person, :with_assister_role) }
    let(:csr_person) { FactoryBot.create(:person, :with_csr_role) }
    let(:employee_person) { FactoryBot.create(:person, :with_employee_role) }

    permissions :privacy? do
      it "grants access when consumer" do
        expect(subject).to permit(FactoryBot.build(:user, :consumer, person: consumer_person), ConsumerRole)
      end

      it "grants access when broker" do
        expect(subject).to permit(FactoryBot.build(:user, :broker, person: broker_person), ConsumerRole)
      end

      it "grants access when assister" do
        expect(subject).to permit(FactoryBot.build(:user, :assister, person: assister_person), ConsumerRole)
      end

      it "grants access when csr" do
        expect(subject).to permit(FactoryBot.build(:user, :csr, person: csr_person), ConsumerRole)
      end

      it "grants access when user without roles" do
        expect(subject).to permit(User.new, ConsumerRole)
      end

      it "denies access when employee" do
        expect(subject).not_to permit(FactoryBot.build(:user, :employee, person: employee_person), ConsumerRole)
      end

      it "denies access when employer_staff" do
        expect(subject).not_to permit(FactoryBot.build(:user, :employer_staff), ConsumerRole)
      end
    end

    permissions :edit? do
      let(:hbx_staff_user) {FactoryBot.create(:user, person: person)}
      let(:person) { FactoryBot.create(:person, :with_hbx_staff_role) }
      let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person)}
      let(:permission) { FactoryBot.create(:permission)}

      it "grants access when hbx_staff" do
        allow(hbx_staff_role).to receive(:permission).and_return permission
        allow(person).to receive(:hbx_staff_role).and_return hbx_staff_role
        allow(hbx_staff_user).to receive(:person).and_return person
        allow(permission).to receive(:can_update_ssn).and_return true
        expect(subject).to permit(hbx_staff_user, consumer_role)
      end

      it "denies access when normal user" do
        expect(subject).not_to permit(User.new, consumer_role)
      end

      context "consumer" do
        let(:user) { FactoryBot.create(:user, :consumer, person: consumer_role.person) }
        let(:consumer_role) { FactoryBot.create(:consumer_role) }
        let(:other_consumer_role) { FactoryBot.build(:consumer_role) }

        it "grants access" do
          expect(subject).to permit(user, consumer_role)
        end

        it "denies access" do
          expect(subject).not_to permit(user, other_consumer_role)
        end
      end
    end


    permissions :ridp_document_upload? do
      context 'when a valid user is logged in' do
        context 'when the user is a consumer' do
          let(:user_of_family) { FactoryBot.create(:user, person: person) }
          let(:logged_in_user) { user_of_family }
          let(:consumer_user) { FactoryBot.create(:user, person: person) }
          let(:person) { FactoryBot.create(:person, :with_consumer_role) }
          let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

          context 'with user is consumer' do
            it 'grants access' do
              expect(subject).to permit(consumer_user, family.primary_person.consumer_role)
            end
          end
        end

        context 'when the user is a hbx staff' do
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

          let(:logged_in_user) { hbx_admin_user }
          let!(:person) { FactoryBot.create(:person, :with_consumer_role) }

          context 'when the hbx staff has the correct permission' do
            let(:permission) { FactoryBot.create(:permission, :super_admin) }

            it 'grants access' do
              expect(subject).to permit(logged_in_user, person.consumer_role)
            end
          end

          context 'when the hbx staff does not have the correct permission' do
            let(:permission) { FactoryBot.create(:permission, :developer) }

            it 'denies access' do
              expect(subject).not_to permit(logged_in_user, person.consumer_role)
            end
          end
        end

        context 'when the user is an assigned broker' do
          let(:market_kind) { 'both' }
          let(:broker_person) { FactoryBot.create(:person, :with_broker_role) }
          let(:broker_person) { FactoryBot.create(:person) }
          let(:broker_role) { FactoryBot.create(:broker_role, person: broker_person, market_kind: market_kind) }
          let(:broker_user) { FactoryBot.create(:user, person: broker_person) }
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

          let(:logged_in_user) { broker_user }

          let(:broker_agency_account) do
            family.broker_agency_accounts.create!(
              benefit_sponsors_broker_agency_profile_id: broker_agency_id,
              writing_agent_id: broker_role.id,
              is_active: baa_active,
              start_on: TimeKeeper.date_of_record
            )
          end
          let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
          let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

          before do
            broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
            broker_person.create_broker_agency_staff_role(
              benefit_sponsors_broker_agency_profile_id: broker_role.benefit_sponsors_broker_agency_profile_id
            )
            broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id, market_kind: market_kind)
            broker_role.approve!
            broker_agency_account
          end

          context 'with active associated individual market certified broker' do
            context 'when broker is logged in' do
              let(:baa_active) { true }
              it 'grants access' do
                expect(subject).to permit(logged_in_user, person.consumer_role)
              end
            end
          end

          context 'with active associated shop market certified broker' do
            let(:baa_active) { false }
            let(:market_kind) { 'shop' }

            it 'denies access' do
              expect(subject).not_to permit(logged_in_user, person.consumer_role)
            end
          end

          context 'with unassociated broker' do
            let(:baa_active) { false }

            it 'denies access' do
              expect(subject).not_to permit(logged_in_user, person.consumer_role)
            end
          end
        end

        context 'when the user is an assigned broker staff' do
          let(:market_kind) { :both }
          let(:broker_person) { FactoryBot.create(:person) }
          let(:broker_role) { FactoryBot.create(:broker_role, person: broker_person) }
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
          let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
          let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

          let(:logged_in_user) { broker_staff_user }

          let(:broker_agency_account) do
            family.broker_agency_accounts.create!(
              benefit_sponsors_broker_agency_profile_id: broker_agency_id,
              writing_agent_id: broker_role.id,
              is_active: baa_active,
              start_on: TimeKeeper.date_of_record
            )
          end

          before do
            broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
            broker_person.create_broker_agency_staff_role(
              benefit_sponsors_broker_agency_profile_id: broker_role.benefit_sponsors_broker_agency_profile_id
            )
            broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id, market_kind: market_kind)
            broker_role.approve!
            broker_agency_account
            broker_staff
          end

          context 'with active associated individual market certified broker' do
            context 'when broker is logged in' do
              let(:baa_active) { true }
              it 'grants access' do
                expect(subject).to permit(logged_in_user, person.consumer_role)
              end
            end
          end

          context 'with active associated shop market certified broker' do
            let(:baa_active) { false }
            let(:market_kind) { 'shop' }

            it 'denies access' do
              expect(subject).not_to permit(logged_in_user, person.consumer_role)
            end
          end

          context 'with unassociated broker' do
            let(:baa_active) { false }

            it 'denies access' do
              expect(subject).not_to permit(logged_in_user, person.consumer_role)
            end
          end
        end
      end
    end

    permissions :verification_document_upload? do
      context 'when a valid user is logged in' do
        context 'when the user is a consumer' do
          let(:user_of_family) { FactoryBot.create(:user, person: person) }
          let(:logged_in_user) { user_of_family }
          let(:consumer_user) { FactoryBot.create(:user, person: person) }
          let(:person) { FactoryBot.create(:person, :with_consumer_role) }
          let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

          context 'with user is consumer' do
            it 'grants access' do
              person.consumer_role.move_identity_documents_to_verified
              expect(subject).to permit(consumer_user, family.primary_person.consumer_role)
            end
          end
        end

        context 'when the user is a hbx staff' do
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

          let(:logged_in_user) { hbx_admin_user }
          let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
          let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

          context 'when the hbx staff has the correct permission' do
            let(:permission) { FactoryBot.create(:permission, :super_admin) }

            it 'grants access' do
              expect(subject).to permit(logged_in_user, person.consumer_role)
            end
          end

          context 'when the hbx staff does not have the correct permission' do
            let(:permission) { FactoryBot.create(:permission, :developer) }

            it 'denies access' do
              expect(subject).not_to permit(logged_in_user, person.consumer_role)
            end
          end
        end

        context 'when the user is an assigned broker' do
          let(:market_kind) { 'both' }
          let(:broker_person) { FactoryBot.create(:person, :with_broker_role) }
          let(:broker_person) { FactoryBot.create(:person) }
          let(:broker_role) { FactoryBot.create(:broker_role, person: broker_person, market_kind: market_kind) }
          let(:broker_user) { FactoryBot.create(:user, person: broker_person) }
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

          let(:logged_in_user) { broker_user }

          let(:broker_agency_account) do
            family.broker_agency_accounts.create!(
              benefit_sponsors_broker_agency_profile_id: broker_agency_id,
              writing_agent_id: broker_role.id,
              is_active: baa_active,
              start_on: TimeKeeper.date_of_record
            )
          end
          let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
          let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

          before do
            person.consumer_role.move_identity_documents_to_verified
            broker_agency_profile.update_attributes(market_kind: :individual)
            broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
            broker_person.create_broker_agency_staff_role(
              benefit_sponsors_broker_agency_profile_id: broker_role.benefit_sponsors_broker_agency_profile_id
            )
            broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id)
            broker_role.approve!
            broker_agency_account
          end

          context 'with active associated individual market certified broker' do
            context 'when broker is logged in' do
              let(:baa_active) { true }
              it 'grants access' do
                expect(subject).to permit(logged_in_user, person.consumer_role)
              end
            end
          end

          context 'with active associated shop market certified broker' do
            let(:baa_active) { false }
            let(:market_kind) { 'shop' }

            it 'denies access' do
              expect(subject).not_to permit(logged_in_user, person.consumer_role)
            end
          end

          context 'with unassociated broker' do
            let(:baa_active) { false }

            it 'denies access' do
              expect(subject).not_to permit(logged_in_user, person.consumer_role)
            end
          end
        end

        context 'when the user is an assigned broker staff' do
          let(:market_kind) { :both }
          let(:broker_person) { FactoryBot.create(:person) }
          let(:broker_role) { FactoryBot.create(:broker_role, person: broker_person) }
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
          let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
          let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

          let(:logged_in_user) { broker_staff_user }

          let(:broker_agency_account) do
            family.broker_agency_accounts.create!(
              benefit_sponsors_broker_agency_profile_id: broker_agency_id,
              writing_agent_id: broker_role.id,
              is_active: baa_active,
              start_on: TimeKeeper.date_of_record
            )
          end

          before do
            person.consumer_role.move_identity_documents_to_verified
            broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
            broker_person.create_broker_agency_staff_role(
              benefit_sponsors_broker_agency_profile_id: broker_role.benefit_sponsors_broker_agency_profile_id
            )
            broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id, market_kind: market_kind)
            broker_role.approve!
            broker_agency_account
            broker_staff
          end

          context 'with active associated individual market certified broker' do
            context 'when broker is logged in' do
              let(:baa_active) { true }
              it 'grants access' do
                expect(subject).to permit(logged_in_user, person.consumer_role)
              end
            end
          end

          context 'with active associated shop market certified broker' do
            let(:baa_active) { false }
            let(:market_kind) { 'shop' }

            it 'denies access' do
              expect(subject).not_to permit(logged_in_user, person.consumer_role)
            end
          end

          context 'with unassociated broker' do
            let(:baa_active) { false }

            it 'denies access' do
              expect(subject).not_to permit(logged_in_user, person.consumer_role)
            end
          end
        end
      end
    end

    permissions :ridp_verified? do
      let(:hbx_staff_user) {FactoryBot.create(:user, person: person)}
      let(:person) { FactoryBot.create(:person, :with_hbx_staff_role) }
      let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person)}
      let(:permission) { FactoryBot.create(:permission)}
      let(:user_without_staff_role) { FactoryBot.create(:user, person: consumer_person) }

      it "grants access when hbx_staff" do
        allow(hbx_staff_role).to receive(:permission).and_return permission
        allow(person).to receive(:hbx_staff_role).and_return hbx_staff_role
        allow(hbx_staff_user).to receive(:person).and_return person
        expect(subject).to permit(hbx_staff_user, consumer_role)
      end

      it "denies access when normal user" do
        consumer_role.update!(identity_validation: 'na')
        expect(subject).not_to permit(user_without_staff_role, consumer_role)
      end

      context "consumer" do
        let(:user) { FactoryBot.create(:user, :consumer, person: consumer_role.person) }
        let(:consumer_role) { FactoryBot.create(:consumer_role) }
        let(:other_consumer_role) { FactoryBot.build(:consumer_role) }

        it "grants access when identity validation is complete" do
          allow(user).to receive(:has_hbx_staff_role?).and_return false
          allow(consumer_role).to receive(:identity_validation).and_return 'valid'
          expect(subject).to permit(user, consumer_role)
        end

        it "denies access when identity validation is incomplete" do
          allow(user).to receive(:has_hbx_staff_role?).and_return false
          allow(other_consumer_role).to receive(:identity_validation).and_return 'invalid'
          expect(subject).not_to permit(user, other_consumer_role)
        end
      end

      context "broker" do
        let(:user) { FactoryBot.create(:user, :broker, person: broker_person) }
        let(:consumer_role) { FactoryBot.create(:consumer_role) }
        let(:broker_role) { FactoryBot.create(:broker_role) }
        let(:other_consumer_role) { FactoryBot.build(:consumer_role) }

        it "grants access when identity validation is complete" do
          allow(user).to receive(:has_hbx_staff_role?).and_return false
          allow(consumer_role).to receive(:identity_validation).and_return 'valid'
          expect(subject).to permit(user, consumer_role)
        end

        it "denies access when identity validation is incomplete" do
          consumer_role.update!(identity_validation: 'na')
          allow(user).to receive(:has_hbx_staff_role?).and_return false
          allow(other_consumer_role).to receive(:identity_validation).and_return 'invalid'
          expect(subject).not_to permit(user, consumer_role)
        end
      end
    end
  end
end
