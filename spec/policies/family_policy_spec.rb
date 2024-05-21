# frozen_string_literal: true

require "rails_helper"

# TODO: We may need to refactor these at a per client level but not sure.
describe FamilyPolicy, "given a user who has no properties" do
  let(:primary_person_id) { double }
  let(:family) { instance_double(Family) }
  let(:user) { instance_double(User, :person => nil) }

  subject { FamilyPolicy.new(user, family) }

  it "can't show" do
    expect(subject.legacy_show?).to be_falsey
  end
end

describe FamilyPolicy, "given a user who is the primary member" do
  let(:primary_person_id) { double }
  let(:family) { instance_double(Family, :primary_applicant => primary_member) }
  let(:person) { instance_double(Person, :id => primary_person_id) }
  let(:user) { instance_double(User, :person => person) }
  let(:primary_member) { instance_double(FamilyMember, :person_id => primary_person_id) }

  subject { FamilyPolicy.new(user, family) }

  it "can show" do
    expect(subject.legacy_show?).to be_truthy
  end
end

describe FamilyPolicy, "given a family with an active broker agency account", :dbclean => :after_each do
  let(:broker_person_id) { double }
  let(:broker_agency_profile_id) { double }
  let(:person) { FactoryBot.create(:person, :with_family)}
  let(:family) { person.primary_family }
  let(:site)  { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile, market_kind: 'shop', legal_name: 'Legal Name1', assigned_site: site) }
  let(:broker_person) { instance_double(Person, :id => broker_person_id, :active_broker_staff_roles => [broker_agency_staff_role], :active_general_agency_staff_roles => [], :hbx_staff_role => nil) }
  let(:broker_agency_staff_role) { instance_double(BrokerAgencyStaffRole, :benefit_sponsors_broker_agency_profile_id => broker_agency_profile_id) }
  let(:broker_agency_account) {FactoryBot.create(:broker_agency_account, broker_agency_profile_id: broker_agency_profile_id_account, writing_agent_id: broker_role.id, is_active: true)}

  subject { FamilyPolicy.new(user, family) }

  before(:each) do
    allow(broker_person).to receive(:broker_role).and_return nil
  end

  describe "when the user is an active member of the same broker agency as the account" do
    let(:broker_agency_profile_id_account) { broker_agency_profile.id }
    let(:user) { FactoryBot.create(:user, :person => person)}

    it "can show" do
      expect(subject.legacy_show?).to be_truthy
    end
  end

  describe "when the user is an active member of a different broker agency from the account" do
    let(:broker_person_id) { double }
    let(:broker_agency_profile_id) { double }
    let(:broker_agency_profile_id_account) { double }
    let(:broker_person) { instance_double(Person, :id => broker_person_id, :active_broker_staff_roles => [broker_agency_staff_role], :active_general_agency_staff_roles => [], :hbx_staff_role => nil) }
    let(:user) { FactoryBot.create(:user, :person => broker_person)}

    it "can't show" do
      expect(subject.legacy_show?).to be_falsey
    end
  end
end

describe FamilyPolicy, "given a family where the primary has an active employer broker account", dbclean: :after_each do
  let(:broker_person_id) { double }
  let(:broker_agency_profile_id) { double }
  let(:site)  { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let(:organization)        { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let(:employer_profile)    { organization.employer_profile }
  let(:employee_role) {FactoryBot.create(:employee_role, employer_profile: employer_profile)}
  let(:person) { FactoryBot.create(:person, :with_family)}
  let(:family) { person.primary_family }
  let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile, market_kind: 'shop', legal_name: 'Legal Name1', assigned_site: site) }
  let(:broker_person) { instance_double(Person, :id => broker_person_id, :active_broker_staff_roles => [broker_agency_staff_role], :active_general_agency_staff_roles => [], :hbx_staff_role => nil) }
  let(:broker_agency_staff_role) { instance_double(BrokerAgencyStaffRole, :benefit_sponsors_broker_agency_profile_id => broker_agency_profile_id) }
  let(:broker_agency_account) {FactoryBot.create(:broker_agency_account, broker_agency_profile_id: broker_agency_profile_id_account, writing_agent_id: broker_role.id, is_active: true)}

  subject { FamilyPolicy.new(user, family) }

  before(:each) do
    allow(broker_person).to receive(:broker_role).and_return nil
  end

  describe "when the user is an active member of the same broker agency as the account" do
    let(:broker_agency_profile_id_account) { broker_agency_profile.id }
    let(:user) { FactoryBot.create(:user, :person => person)}

    it "can show" do
      expect(subject.legacy_show?).to be_truthy
    end
  end

  describe "when the user is an active member of a different broker agency from the account" do
    let(:broker_agency_profile_id_account) { double }
    let(:employee_person) { employee_role.person }
    let(:user) { FactoryBot.create(:user, :person => employee_person)}

    it "can't show" do
      expect(subject.legacy_show?).to be_falsey
    end
  end
end

describe FamilyPolicy, "given a family where the primary has an active employer general agency account account" do
  let(:primary_person_id) { double }
  let(:ga_person_id) { double }
  let(:general_agency_profile_id) { double }
  let(:family) { instance_double(Family, :primary_applicant => primary_member, :active_broker_agency_account => nil) }
  let(:employer_profile) { instance_double(EmployerProfile, :active_broker_agency_account => nil, :active_general_agency_account => general_agency_account) }
  let(:employee_role) { instance_double(EmployeeRole, :employer_profile => employer_profile) }
  let(:person) { instance_double(Person, :id => primary_person_id, :active_employee_roles => [employee_role], :active_broker_staff_roles => [broker_agency_staff_role]) }
  let(:broker_agency_staff_role) { instance_double(BrokerAgencyStaffRole, :benefit_sponsors_broker_agency_profile_id => '1234') }
  let(:user) { instance_double(User, :person => ga_person) }
  let(:ga_person) { instance_double(Person, :id => ga_person_id, :broker_role => nil, :active_general_agency_staff_roles => [general_agency_staff_role], :active_broker_staff_roles => [broker_agency_staff_role], :hbx_staff_role => nil) }
  let(:general_agency_staff_role) { instance_double(GeneralAgencyStaffRole, :benefit_sponsors_general_agency_profile_id => general_agency_profile_id) }
  let(:general_agency_account) { instance_double(SponsoredBenefits::Accounts::GeneralAgencyAccount, :benefit_sponsrship_general_agency_profile_id => general_agency_account_profile_id) }
  let(:primary_member) { instance_double(FamilyMember, :person_id => primary_person_id, :person => person) }

  subject { FamilyPolicy.new(user, family) }

  describe "when the user is an active member of the same general agency as the account" do
    let(:general_agency_account_profile_id) { general_agency_profile_id }

    it "can show" do
      expect(subject.legacy_show?).to be_truthy
    end
  end

  describe "when the user is an active member of a different general agency from the account" do
    let(:general_agency_account_profile_id) { double }

    it "can't show" do
      expect(subject.legacy_show?).to be_falsey
    end
  end
end

describe FamilyPolicy, "given a user who has the modify family permission" do
  let(:primary_person_id) { double }
  let(:family) { instance_double(Family, :primary_applicant => primary_member, :active_broker_agency_account => nil) }
  let(:person) { instance_double(Person, :id => primary_person_id) }
  let(:user) { instance_double(User, :person => permissioned_person) }
  let(:permissioned_person) { instance_double(Person, :id => double, :hbx_staff_role => hbx_staff_role) }
  let(:primary_member) { instance_double(FamilyMember, :person_id => primary_person_id, :person => person) }
  let(:hbx_staff_role) { instance_double(HbxStaffRole, :permission => permission) }
  let(:permission) { instance_double(Permission, :modify_family => true) }

  subject { FamilyPolicy.new(user, family) }

  it "can show" do
    expect(subject.legacy_show?).to be_truthy
  end

  it "can can_view_entire_family_enrollment_history" do
    expect(subject.can_view_entire_family_enrollment_history?).to be_truthy
  end
end

describe FamilyPolicy, 'given a family with an active broker with only broker role' do
  let(:primary_person_id) { double }
  let(:broker_person_id) { double }
  let(:broker_agency_profile_id) { double }
  let(:family) { instance_double(Family, :primary_applicant => primary_member, :active_broker_agency_account => broker_agency_account) }
  let(:person) { instance_double(Person, :id => primary_person_id, :active_employee_roles => []) }
  let(:user) { instance_double(User, :person => broker_person) }
  let(:broker_role) { instance_double(BrokerRole, :benefit_sponsors_broker_agency_profile_id => broker_agency_profile_id) }
  let(:broker_person) { instance_double(Person, :id => broker_person_id, :broker_role => broker_role, :active_general_agency_staff_roles => [], :hbx_staff_role => nil) }
  let(:broker_agency_account) { instance_double(BenefitSponsors::Accounts::BrokerAgencyAccount, :benefit_sponsors_broker_agency_profile_id => broker_agency_profile_id_account) }
  let(:primary_member) { instance_double(FamilyMember, :person_id => primary_person_id, :person => person) }


  subject { FamilyPolicy.new(user, family) }

  before(:each) do
    allow(family).to receive(:active_broker_agency_account).and_return broker_agency_account
    allow(broker_person).to receive(:active_broker_staff_roles).and_return []
  end

  context 'when the user is an active member of the same broker agency as the account' do
    let(:broker_agency_profile_id_account) { broker_agency_profile_id }

    it 'can show' do
      allow(broker_person).to receive(:active_broker_staff_roles).and_return []
      expect(subject.legacy_show?).to be_truthy
    end
  end
end

describe 'can_broker_modify_family' do

  let(:person) { FactoryBot.create(:person, :with_family) }
  let(:user) { FactoryBot.create(:user, person: person) }
  let(:family) { person.primary_family }
  let(:broker_role) { FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person) }
  let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile) }
  let(:broker_agency_account) { FactoryBot.create(:benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: broker_agency_profile, writing_agent_id: broker_role.id, is_active: true) }

  subject { FamilyPolicy.new(user, family) }

  context 'person with only broker role' do

    it 'can modify family' do
      allow(family).to receive(:active_broker_agency_account).and_return broker_agency_account
      expect(subject.can_broker_modify_family?(broker_role, nil)).to be_truthy
    end
  end

  context 'person with only broker staff role' do

    let!(:broker_agency_staff_role1) { FactoryBot.create(:broker_agency_staff_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person) }
    let!(:broker_agency_staff_role2) { FactoryBot.create(:broker_agency_staff_role, aasm_state: 'pending', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person) }

    it 'can modify family' do
      allow(family).to receive(:active_broker_agency_account).and_return broker_agency_account
      expect(subject.can_broker_modify_family?(nil, person.active_broker_staff_roles)).to be_truthy
    end
  end

  context 'person with broker role and broker staff roles' do
    let(:person) { FactoryBot.create(:person, :with_family) }
    let(:person1) { FactoryBot.create(:person, :with_family) }
    let(:user) { FactoryBot.create(:user, person: person) }
    let(:family) { person.primary_family }
    let(:broker_role) { FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person) }
    let(:broker_role1) { FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile1.id, person: person1) }
    let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile) }
    let(:broker_agency_profile1) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile) }
    let(:broker_agency_account) { FactoryBot.create(:benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: broker_agency_profile, writing_agent_id: broker_role1.id, is_active: true) }
    let(:user) { FactoryBot.create(:user, person: person) }
    let(:broker_agency_account1) { FactoryBot.create(:benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: broker_agency_profile1, writing_agent_id: broker_role1.id, is_active: true) }
    let!(:broker_agency_staff_role1) { FactoryBot.create(:broker_agency_staff_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person) }
    let!(:broker_agency_staff_role) { FactoryBot.create(:broker_agency_staff_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile1.id, person: person1) }

    it "should return true if broker has a broker role and a broker staff role for a different agency" do
      allow(family).to receive(:active_broker_agency_account).and_return broker_agency_account
      expect(subject.can_broker_modify_family?(broker_role1, person.active_broker_staff_roles)).to be_truthy
    end

    it "should return true if broker has a broker role and a staff role for the same agency" do
      allow(family).to receive(:active_broker_agency_account).and_return broker_agency_account1
      expect(subject.can_broker_modify_family?(broker_role1, person1.active_broker_staff_roles)).to be_truthy
    end
  end
end

describe 'user permission' do
  let(:primary_person_id) { double }
  let(:family) { instance_double(Family, :primary_applicant => primary_member, :active_broker_agency_account => nil) }
  let(:person) { instance_double(Person, :id => primary_person_id) }
  let(:user) { instance_double(User, :person => permissioned_person) }
  let(:permissioned_person) { instance_double(Person, :id => double, :hbx_staff_role => hbx_staff_role) }
  let(:primary_member) { instance_double(FamilyMember, :person_id => primary_person_id, :person => person) }
  let(:hbx_staff_role) { instance_double(HbxStaffRole, :permission => permission) }
  subject { FamilyPolicy.new(user, family) }

  context 'can_edit_aptc?' do
    let(:permission) { instance_double(Permission, :can_edit_aptc => true) }
    it 'should return true' do
      expect(subject.can_edit_aptc?).to be_truthy
    end
  end

  context 'can_view_sep_history?' do
    let(:permission) { instance_double(Permission, :can_view_sep_history => true) }
    it 'should return true' do
      expect(subject.can_view_sep_history?).to be_truthy
    end
  end

  context 'can_reinstate_enrollment?' do
    let(:permission) { instance_double(Permission, :can_reinstate_enrollment => true) }
    it 'should return true' do
      expect(subject.can_reinstate_enrollment?).to be_truthy
    end
  end

  context 'can_cancel_enrollment?' do
    let(:permission) { instance_double(Permission, :can_cancel_enrollment => true) }
    it 'should return true' do
      expect(subject.can_cancel_enrollment?).to be_truthy
    end
  end

  context 'can_terminate_enrollment?' do
    let(:permission) { instance_double(Permission, :can_terminate_enrollment => true) }
    it 'should return true' do
      expect(subject.can_terminate_enrollment?).to be_truthy
    end
  end

  context 'change_enrollment_end_date?' do
    let(:permission) { instance_double(Permission, :change_enrollment_end_date => true) }
    it 'should return true' do
      expect(subject.change_enrollment_end_date?).to be_truthy
    end
  end

  context 'can_drop_enrollment_members?' do
    let(:permission) { instance_double(Permission, :can_drop_enrollment_members => true) }
    it 'should return true' do
      expect(subject.can_drop_enrollment_members?).to be_truthy
    end
  end

  context 'change_enrollment_end_date?' do
    let(:permission) { instance_double(Permission, :can_view_username_and_email => true) }
    it 'should return true' do
      expect(subject.can_view_username_and_email?).to be_truthy
    end

    context 'when person is not linked to user' do
      let(:permission) { instance_double(Permission, :can_view_username_and_email => true) }
      let(:user) { instance_double(User, :person => nil) }

      it 'should return false' do
        expect(subject.can_view_username_and_email?).to be_falsey
      end
    end

    context 'when hbx_staff role is nil' do
      let(:permission) { instance_double(Permission, :can_view_username_and_email => true) }
      let(:permissioned_person) { instance_double(Person, :id => double, :hbx_staff_role => nil, csr_role: nil) }
      it 'should return false' do
        expect(subject.can_view_username_and_email?).to be_falsey
      end
    end
  end
end

describe FamilyPolicy, "#hire_broker_agency?" do
  RSpec.shared_examples_for "a FamilyPolicy given a user with a needed permission" do |check|
    before :each do
      perm_list = [
        :individual_market_primary_family_member?,
        :individual_market_non_ridp_primary_family_member?,
        :individual_market_admin?,
        :shop_market_primary_family_member?,
        :shop_market_admin?,
        :fehb_market_primary_family_member?,
        :fehb_market_admin?,
        :coverall_market_primary_family_member?,
        :coverall_market_admin?
      ]
      allow(subject).to receive(check.to_sym).and_return(true)
      (perm_list - [check].compact).each do |perm|
        allow(subject).to receive(perm.to_sym).and_return(false)
      end
    end

    it "has the ability to #{check} and can hire_broker_agency" do
      expect(subject.hire_broker_agency?).to be_truthy
    end
  end

  let(:user) { instance_double(User, person: nil, identity_verified?: false) }
  let(:family) { instance_double(Family, primary_person: nil) }

  subject { described_class.new(user, family) }

  it "can't hire_broker_agency without permissions" do
    expect(subject.hire_broker_agency?).to be_falsey
  end

  it_behaves_like "a FamilyPolicy given a user with a needed permission", :individual_market_primary_family_member?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :individual_market_non_ridp_primary_family_member?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :individual_market_admin?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :shop_market_primary_family_member?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :shop_market_admin?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :fehb_market_primary_family_member?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :fehb_market_admin?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :coverall_market_primary_family_member?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :coverall_market_admin?
end

describe FamilyPolicy, "#request_help?" do
  RSpec.shared_examples_for "a FamilyPolicy given a user with a needed permission" do |check|
    before :each do
      perm_list = [
        :individual_market_primary_family_member?,
        :individual_market_non_ridp_primary_family_member?,
        :individual_market_admin?,
        :shop_market_primary_family_member?,
        :shop_market_admin?,
        :fehb_market_primary_family_member?,
        :fehb_market_admin?,
        :coverall_market_primary_family_member?,
        :coverall_market_admin?,
        :active_associated_shop_market_family_broker?,
        :active_associated_shop_market_general_agency?,
        :active_associated_fehb_market_family_broker?,
        :active_associated_fehb_market_general_agency?,
        :active_associated_coverall_market_family_broker?
      ]
      allow(subject).to receive(check.to_sym).and_return(true)
      (perm_list - [check].compact).each do |perm|
        allow(subject).to receive(perm.to_sym).and_return(false)
      end
    end

    it "has the ability to #{check} and can request_help" do
      expect(subject.request_help?).to be_truthy
    end
  end

  let(:user) { instance_double(User, person: nil, identity_verified?: false) }
  let(:family) { instance_double(Family, primary_person: nil) }

  subject { described_class.new(user, family) }

  it "can't request_help without permissions" do
    expect(subject.request_help?).to be_falsey
  end

  it_behaves_like "a FamilyPolicy given a user with a needed permission", :individual_market_primary_family_member?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :individual_market_non_ridp_primary_family_member?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :individual_market_admin?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :shop_market_primary_family_member?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :shop_market_admin?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :fehb_market_primary_family_member?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :fehb_market_admin?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :coverall_market_primary_family_member?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :coverall_market_admin?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :active_associated_shop_market_family_broker?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :active_associated_shop_market_general_agency?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :active_associated_fehb_market_family_broker?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :active_associated_fehb_market_general_agency?
  it_behaves_like "a FamilyPolicy given a user with a needed permission", :active_associated_coverall_market_family_broker?
end

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe FamilyPolicy, dbclean: :after_each, type: :model do
    subject { described_class }

    let(:person) { FactoryBot.create(:person, :with_resident_role, :with_active_resident_role) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

    permissions :upload_paper_application? do
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

        context 'when the hbx staff has the correct permission' do
          let(:permission) { FactoryBot.create(:permission, :super_admin) }

          it 'grants access' do
            expect(subject).to permit(logged_in_user, family)
          end
        end

        context 'when the hbx staff does not have the correct permission' do
          let(:permission) { FactoryBot.create(:permission, :developer) }

          it 'denies access' do
            expect(subject).not_to permit(logged_in_user, family)
          end
        end
      end

      context 'when a valid user is not logged in' do
        let(:no_role_person) { FactoryBot.create(:person) }
        let(:no_role_user) { FactoryBot.create(:user, person: no_role_person) }
        let(:logged_in_user) { no_role_user }

        it 'denies access' do
          expect(subject).not_to permit(logged_in_user, family)
        end
      end
    end

    permissions :download_paper_application? do
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

        context 'when the hbx staff has the correct permission' do
          let(:permission) { FactoryBot.create(:permission, :super_admin) }

          it 'grants access' do
            expect(subject).to permit(logged_in_user, family)
          end
        end

        context 'when the hbx staff does not have the correct permission' do
          let(:permission) { FactoryBot.create(:permission, :developer) }

          it 'denies access' do
            expect(subject).not_to permit(logged_in_user, family)
          end
        end
      end

      context 'when a valid user is not logged in' do
        let(:no_role_person) { FactoryBot.create(:person) }
        let(:no_role_user) { FactoryBot.create(:user, person: no_role_person) }
        let(:logged_in_user) { no_role_user }

        it 'denies access' do
          expect(subject).not_to permit(logged_in_user, family)
        end
      end
    end
  end
end
