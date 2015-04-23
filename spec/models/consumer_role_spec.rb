require 'rails_helper'

describe ConsumerRole, dbclean: :after_each do
  it { should delegate_method(:hbx_id).to :person }
  it { should delegate_method(:ssn).to :person }
  it { should delegate_method(:dob).to :person }
  it { should delegate_method(:gender).to :person }

  it { should validate_presence_of :is_incarcerated }
  it { should validate_presence_of :is_applicant }
  it { should validate_presence_of :is_state_resident }
  it { should validate_presence_of :citizen_status }
  it { should validate_presence_of :gender }
  it { should validate_presence_of :ssn }
  it { should validate_presence_of :dob }

  let(:address) {FactoryGirl.build(:address)}
  let(:saved_person) {FactoryGirl.create(:person, gender: "male", dob: "10/10/1974", ssn: "123456789")}

  let(:is_incarcerated) {false}
  let(:is_applicant) {true}
  let(:is_state_resident) {true}
  let(:citizen_status) {"us_citizen"}
  let(:citizen_error_message) {"test citizen_status is not a valid citizen status"}

  describe ".new" do
    let(:valid_params) do
      {
        is_incarcerated: is_incarcerated,
        is_applicant: is_applicant,
        is_state_resident: is_state_resident,
        citizen_status: citizen_status,
        person: saved_person
      }
    end

    context "with no arguments" do
      let(:params) {{}}
      it "should not save" do
        expect(ConsumerRole.new(**params).save).to be_falsey
      end
    end

    context "with all valid arguments" do
      let(:consumer_role) {saved_person.build_consumer_role(valid_params)}

      it "should save" do
        expect(consumer_role.save).to be_truthy
      end

      context "and it is saved" do
        before do
          consumer_role.save
        end

        it "should be findable" do
          expect(ConsumerRole.find(consumer_role.id).id.to_s).to eq consumer_role.id.to_s
        end
      end
    end

    context "with no is_incarcerated" do
      let(:params) {valid_params.except(:is_incarcerated)}

      it "should fail validation " do
        expect(ConsumerRole.create(**params).errors[:is_incarcerated].any?).to be_truthy
      end
    end

    context "with no is_applicant" do
      let(:params) {valid_params.except(:is_applicant)}
      it "should fail validation" do
        expect(ConsumerRole.create(**params).errors[:is_applicant].any?).to be_truthy
      end
    end

    context "with no citizen_status" do
      let(:params) {valid_params.except(:citizen_status)}
      it "should fail validation" do
        expect(ConsumerRole.create(**params).errors[:citizen_status].any?).to be_truthy
      end
    end

    context "with improper citizen_status" do
      let(:params) {valid_params.deep_merge({citizen_status: "test citizen_status"})}
      it "should fail validation with improper citizen_status" do
        expect(ConsumerRole.create(**params).errors[:citizen_status].any?).to be_truthy
        expect(ConsumerRole.create(**params).errors[:citizen_status]).to eq [citizen_error_message]

      end
    end
  end

end
