require "rails_helper"

shared_examples "a valid invitation" do |sk, role|
  it "should be valid with a source_kind of #{sk} and a role of #{role}" do
    record = Invitation.new({role: role, source_kind: sk}.merge(valid_params))
    expect(record.valid?).to eq true
  end
end

shared_examples "an invitation with invalid source kind and role" do |sk, role|
  it "should be invalid with a source_kind of #{sk} and a role of #{role}" do
    record = Invitation.new({role: role, source_kind: sk}.merge(valid_params))
    expect(record.valid?).to eq false
    expect(record).to have_errors_on(:base)
  end
end

describe Invitation do
  before :each do
    DatabaseCleaner.clean
  end

  after :each do
    DatabaseCleaner.clean
  end

  describe "basic model" do
    subject { Invitation.new }

    before :each do
      subject.valid?
    end

    it "should require an invitation role" do
      expect(subject).to have_errors_on(:role)
    end

    it "should require a source_id" do
      expect(subject).to have_errors_on(:source_id)
    end

    it "should require a source_kind" do
      expect(subject).to have_errors_on(:source_kind)
    end

    it "should require an invitation email" do
      expect(subject).to have_errors_on(:invitation_email)
    end

    ["employee_role", "broker_role", "employer_staff_role"].each do |role|
      it "should allow a role of #{role}" do
        record = Invitation.new(role: role)
        record.valid?
        expect(record).not_to have_errors_on(:role)
      end
    end

    ["census_employee", "broker_role", "employer_staff_role"].each do |source_kind|
      it "should allow a source_kind of #{source_kind}" do
        record = Invitation.new(source_kind: source_kind)
        record.valid?
        expect(record).not_to have_errors_on(:source_kind)
      end
    end
  end


  describe "enforcing type constraints" do
    def self.invite_types
      {
        "census_employee" => "employee_role",
        "broker_role" => "broker_role",
        "employer_staff_role" => "employer_staff_role",
        "csr_role" => "csr_role",
        "assister_role" => "assister_role",
        "hbx_staff_role" => "hbx_staf_role",
      }
    end

    def self.source_kinds
      invite_types.keys
    end

    def self.role_kinds
      invite_types.values
    end
    let(:valid_params) {
      {
        :source_id => BSON::ObjectId.new,
        :invitation_email => "user@somewhere.com"
      } 
    }

    [0,1,2].each do |idx|
      include_examples "a valid invitation", source_kinds[idx], role_kinds[idx]
    end

    [[0,1],
     [0,2],
     [1,0],
     [1,2],
     [2,0],
     [4,2],
     [2,1]].each do |idx|
       include_examples "an invitation with invalid source kind and role", source_kinds[idx.first], role_kinds[idx.last]
     end
  end


  describe "starting in the initial state" do
    let(:valid_params) { {:source_id => BSON::ObjectId.new} }
    subject { Invitation.new(valid_params) }

    it "should have been 'sent'" do
      expect(subject.sent?).to eq true
    end

    it "should not have been claimed" do
      expect(subject.claimed?).to eq false
    end

    it "should be able to be claimed" do
      expect(subject.may_claim?).to eq true
    end
  end

  describe "#claim_broker_agency_staff_role" do
    let(:user) { FactoryBot.create :user }
    let(:redirection_obj) { instance_double(InvitationsController) }
    let(:general_agency_staff_role) { FactoryBot.create :general_agency_staff_role }
    let(:invitation) { FactoryBot.create :invitation, :general_agency_staff_role, user: user, source_id: general_agency_staff_role.id }

    subject { invitation.claim_general_agency_staff_role user, redirection_obj }

    it "runs the create_sso_account method on the redirection_obj with 'general_agent'" do
      expect(redirection_obj).to receive(:create_sso_account).with(
        user, general_agency_staff_role.person, 15, 'general_agent'
      )
      subject
    end
  end

  describe "valid, in the sent state" do
    let(:source_id) { BSON::ObjectId.new }
    let(:valid_params) {
      {
        :source_id => source_id,
        :source_kind => "census_employee",
        :role => "employee_role",
        :invitation_email => "user@somewhere.com"
      } 
    }
    let(:user) { User.new }
    let(:redirection_obj) { instance_double(InvitationsController) }
    let(:mock_census_employee) { instance_double(CensusEmployee) }

    subject { Invitation.new(valid_params) }

    before :each do
      allow(CensusEmployee).to receive(:find).with(source_id).and_return(mock_census_employee)
      allow(redirection_obj).to receive(:redirect_to_employee_match)
    end

    it "can be claimed by a user" do
      subject.claim_invitation!(user, redirection_obj)
      expect(subject.user).to eq user
    end
  end

  context "broker invitation email" do
    let(:broker_role) {broker_role=FactoryBot.create(:broker_role);
      broker_role.email=Email.new(kind:"work", address:"broker@email.com");
      broker_role}

    describe "invite_broker!" do
      it "returns an Invitation" do
        expect(Invitation.invite_broker!(broker_role)).to be_a_kind_of(Invitation)
      end
    end
  end

  context "general_agency_staff_role invitation email" do
    let(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role) }
    let(:person) { general_agency_staff_role.person }
    let(:invitation) { Invitation.new }
    before :each do
      person.add_work_email('test@dc.com') if person.work_email.blank?
      person.save
    end

    describe "invite_general_agency_staff!" do
      it "returns an Invitation" do
        expect(Invitation.invite_general_agency_staff!(general_agency_staff_role)).to be_a_kind_of(Invitation)
      end

      it "should call send_agent_invitation" do
        allow(Invitation).to receive(:create).and_return invitation
        expect(invitation).to receive(:send_agent_invitation!)
        Invitation.invite_general_agency_staff!(general_agency_staff_role)
      end
    end
  end
end

describe "A Broker Invitation" do
  let(:person) { instance_double(Person, :user => user, :consumer_role => consumer_role) }
  let(:broker) { instance_double(BrokerRole, :person => person, :email_address => email_address) }

  before :each do
    allow(EnrollRegistry).to receive(
      :feature_enabled?
    ).with(:broker_role_consumer_enhancement).and_return(
      setting_enabled
    )
  end

  describe "when:
              - :broker_role_consumer_enhancement is disabled
              - the broker doesn't have an email" do
    let(:setting_enabled) { false }
    let(:consumer_role) { nil }
    let(:user) { nil }
    let(:email_address) { nil }

    it "should not invite the broker" do
      expect(Invitation.should_invite_broker_or_broker_staff_role?(broker)).to be_falsey
    end

    it "should not notify the broker of being approved" do
      expect(Invitation.should_notify_linked_broker?(broker)).to be_falsey
    end
  end

  describe "when:
              - :broker_role_consumer_enhancement is disabled
              - the broker doesn't has an email" do
    let(:setting_enabled) { false }
    let(:consumer_role) { nil }
    let(:user) { nil }
    let(:email_address) { "some email address" }

    it "should invite the broker" do
      expect(Invitation.should_invite_broker_or_broker_staff_role?(broker)).to be_truthy
    end

    it "should not notify the broker of being approved" do
      expect(Invitation.should_notify_linked_broker?(broker)).to be_falsey
    end
  end

  describe "when:
              - :broker_role_consumer_enhancement is enabled
              - the broker doesn't have an email" do
    let(:setting_enabled) { true }
    let(:consumer_role) { nil }
    let(:user) { nil }
    let(:email_address) { nil }

    it "should not invite the broker" do
      expect(Invitation.should_invite_broker_or_broker_staff_role?(broker)).to be_falsey
    end

    it "should not notify the broker of being approved" do
      expect(Invitation.should_notify_linked_broker?(broker)).to be_falsey
    end
  end

  describe "when:
              - :broker_role_consumer_enhancement is enabled
              - the broker has an email
              - the broker's person DOESN'T HAVE a user
              - the broker's person DOESN'T HAVE a consumer role" do
    let(:setting_enabled) { true }
    let(:consumer_role) { nil }
    let(:user) { nil }
    let(:email_address) { "some email address" }

    it "should invite the broker" do
      expect(Invitation.should_invite_broker_or_broker_staff_role?(broker)).to be_truthy
    end

    it "should not notify the broker of being approved" do
      expect(Invitation.should_notify_linked_broker?(broker)).to be_falsey
    end
  end

  describe "when:
              - :broker_role_consumer_enhancement is enabled
              - the broker has an email
              - the broker's person DOESN'T HAVE a user
              - the broker's person HAS a consumer role" do
    let(:setting_enabled) { true }
    let(:consumer_role) { double }
    let(:user) { nil }
    let(:email_address) { "some email address" }

    it "should invite the broker" do
      expect(Invitation.should_invite_broker_or_broker_staff_role?(broker)).to be_truthy
    end

    it "should not notify the broker of being approved" do
      expect(Invitation.should_notify_linked_broker?(broker)).to be_falsey
    end
  end

  describe "when:
              - :broker_role_consumer_enhancement is enabled
              - the broker has an email
              - the broker's person HAS a user
              - the broker's person DOESN'T HAVE a consumer role" do
    let(:setting_enabled) { true }
    let(:consumer_role) { nil }
    let(:user) { double }
    let(:email_address) { "some email address" }

    it "should invite the broker" do
      expect(Invitation.should_invite_broker_or_broker_staff_role?(broker)).to be_truthy
    end

    it "should not notify the broker of being approved" do
      expect(Invitation.should_notify_linked_broker?(broker)).to be_falsey
    end
  end

  describe "when:
              - :broker_role_consumer_enhancement is enabled
              - the broker has an email
              - the broker's person HAS a user
              - the broker's person HAS a consumer role" do
    let(:setting_enabled) { true }
    let(:consumer_role) { double }
    let(:user) { double }
    let(:email_address) { "some email address" }

    it "should not invite the broker" do
      expect(Invitation.should_invite_broker_or_broker_staff_role?(broker)).to be_falsey
    end

    it "should notify the broker of being approved" do
      expect(Invitation.should_notify_linked_broker?(broker)).to be_truthy
    end
  end
end

describe "A Broker Staff Invitation" do
  let(:person) { instance_double(Person, :user => user, :consumer_role => consumer_role, :broker_role => broker_role) }
  let(:broker_staff) do
    instance_double(
      BrokerAgencyStaffRole,
      :person => person,
      :email_address => email_address,
      :broker_agency_profile => broker_agency_profile
    )
  end
  let(:broker_role) { nil }
  let(:broker_agency_profile) do
    instance_double(
      BenefitSponsors::Organizations::BrokerAgencyProfile,
      :id => "A BROKER AGENCY PROFILE ID"
    )
  end

  before :each do
    allow(EnrollRegistry).to receive(
      :feature_enabled?
    ).with(:broker_role_consumer_enhancement).and_return(
      setting_enabled
    )
  end

  describe "when:
              - :broker_role_consumer_enhancement is disabled
              - the broker staff doesn't have an email" do
    let(:setting_enabled) { false }
    let(:consumer_role) { nil }
    let(:user) { nil }
    let(:email_address) { nil }

    it "should not invite the broker" do
      expect(Invitation.should_invite_broker_or_broker_staff_role?(broker_staff)).to be_falsey
    end

    it "should not notify the broker staff of being approved" do
      expect(Invitation.should_notify_linked_broker_staff?(broker_staff)).to be_falsey
    end
  end

  describe "when:
              - :broker_role_consumer_enhancement is disabled
              - the broker staff doesn't have an email" do
    let(:setting_enabled) { false }
    let(:consumer_role) { nil }
    let(:user) { nil }
    let(:email_address) { "some email address" }

    it "should invite the broker" do
      expect(Invitation.should_invite_broker_or_broker_staff_role?(broker_staff)).to be_truthy
    end

    it "should not notify the broker staff of being approved" do
      expect(Invitation.should_notify_linked_broker_staff?(broker_staff)).to be_falsey
    end
  end

  describe "when:
              - :broker_role_consumer_enhancement is enabled
              - the broker staff doesn't have an email" do
    let(:setting_enabled) { true }
    let(:consumer_role) { nil }
    let(:user) { nil }
    let(:email_address) { nil }

    it "should not invite the broker" do
      expect(Invitation.should_invite_broker_or_broker_staff_role?(broker_staff)).to be_falsey
    end

    it "should not notify the broker staff of being approved" do
      expect(Invitation.should_notify_linked_broker_staff?(broker_staff)).to be_falsey
    end
  end

  describe "when:
              - :broker_role_consumer_enhancement is enabled
              - the broker staff has an email
              - the broker staff's person DOESN'T HAVE a user
              - the broker staff's person DOESN'T HAVE a consumer role" do
    let(:setting_enabled) { true }
    let(:consumer_role) { nil }
    let(:user) { nil }
    let(:email_address) { "some email address" }

    it "should invite the broker" do
      expect(Invitation.should_invite_broker_or_broker_staff_role?(broker_staff)).to be_truthy
    end

    it "should not notify the broker staff of being approved" do
      expect(Invitation.should_notify_linked_broker_staff?(broker_staff)).to be_falsey
    end
  end

  describe "when:
              - :broker_role_consumer_enhancement is enabled
              - the broker staff has an email
              - the broker staff's person DOESN'T HAVE a user
              - the broker staff's person HAS a consumer role" do
    let(:setting_enabled) { true }
    let(:consumer_role) { double }
    let(:user) { nil }
    let(:email_address) { "some email address" }

    it "should invite the broker" do
      expect(Invitation.should_invite_broker_or_broker_staff_role?(broker_staff)).to be_truthy
    end

    it "should not notify the broker staff of being approved" do
      expect(Invitation.should_notify_linked_broker_staff?(broker_staff)).to be_falsey
    end
  end

  describe "when:
              - :broker_role_consumer_enhancement is enabled
              - the broker staff has an email
              - the broker staff's person HAS a user
              - the broker staff's person DOESN'T HAVE a consumer role" do
    let(:setting_enabled) { true }
    let(:consumer_role) { nil }
    let(:user) { double }
    let(:email_address) { "some email address" }

    it "should invite the broker" do
      expect(Invitation.should_invite_broker_or_broker_staff_role?(broker_staff)).to be_truthy
    end

    it "should not notify the broker staff of being approved" do
      expect(Invitation.should_notify_linked_broker_staff?(broker_staff)).to be_falsey
    end
  end

  describe "when:
              - :broker_role_consumer_enhancement is enabled
              - the broker staff has an email
              - the broker staff's person HAS a user
              - the broker staff's person HAS a consumer role
              - the broker staff has no broker role" do
    let(:setting_enabled) { true }
    let(:consumer_role) { double }
    let(:user) { double }
    let(:email_address) { "some email address" }

    it "should not invite the broker" do
      expect(Invitation.should_invite_broker_or_broker_staff_role?(broker_staff)).to be_falsey
    end

    it "should notify the broker staff of being approved" do
      expect(Invitation.should_notify_linked_broker_staff?(broker_staff)).to be_truthy
    end
  end

  describe "when:
              - :broker_role_consumer_enhancement is enabled
              - the broker staff has an email
              - the broker staff's person HAS a user
              - the broker staff's person HAS a consumer role
              - the broker staff has a broker role with a different agency" do
    let(:setting_enabled) { true }
    let(:consumer_role) { double }
    let(:user) { double }
    let(:email_address) { "some email address" }
    let(:broker_role) do
      instance_double(
        BrokerRole,
        :broker_agency_profile => a_different_broker_agency_profile
      )
    end
    let(:a_different_broker_agency_profile) do
      instance_double(
        BenefitSponsors::Organizations::BrokerAgencyProfile,
        :id => "A DIFFERENT BROKER AGENCY PROFILE ID"
      )
    end

    it "should not invite the broker" do
      expect(Invitation.should_invite_broker_or_broker_staff_role?(broker_staff)).to be_falsey
    end

    it "should notify the broker staff of being approved" do
      expect(Invitation.should_notify_linked_broker_staff?(broker_staff)).to be_truthy
    end
  end

  describe "when:
              - :broker_role_consumer_enhancement is enabled
              - the broker staff has an email
              - the broker staff's person HAS a user
              - the broker staff's person HAS a consumer role
              - the broker staff has a broker role with the same agency" do
    let(:setting_enabled) { true }
    let(:consumer_role) { double }
    let(:user) { double }
    let(:email_address) { "some email address" }
    let(:broker_role) do
      instance_double(
        BrokerRole,
        :broker_agency_profile => broker_agency_profile
      )
    end

    it "should not invite the broker" do
      expect(Invitation.should_invite_broker_or_broker_staff_role?(broker_staff)).to be_falsey
    end

    it "should NOT notify the broker staff of being approved" do
      expect(Invitation.should_notify_linked_broker_staff?(broker_staff)).to be_falsey
    end
  end
end