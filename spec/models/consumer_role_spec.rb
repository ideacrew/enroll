require 'rails_helper'

describe ConsumerRole, dbclean: :after_each do
  it { should delegate_method(:hbx_id).to :person }
  it { should delegate_method(:ssn).to :person }
  it { should delegate_method(:dob).to :person }
  it { should delegate_method(:gender).to :person }

  it { should delegate_method(:is_incarcerated).to :person }

  it { should delegate_method(:race).to :person }
  it { should delegate_method(:ethnicity).to :person }
  it { should delegate_method(:is_disabled).to :person }

  it { should validate_presence_of :gender }
  it { should validate_presence_of :ssn }
  it { should validate_presence_of :dob }

  let(:address)       {FactoryGirl.build(:address)}
  let(:saved_person)  {FactoryGirl.create(:person, gender: "male", dob: "10/10/1974", ssn: "123456789")}

  let(:is_applicant)          { true }
  let(:citizen_error_message) { "test citizen_status is not a valid citizen status" }

  describe ".new" do
    let(:valid_params) do
      {
        is_applicant: is_applicant,
        person: saved_person
      }
    end

    context "with no person" do
      let(:params) {valid_params.except(:person)}

      it "should raise" do
        expect(ConsumerRole.new(**params).valid?).to be_falsey
      end
    end

    context "with all valid arguments" do
      let(:consumer_role) { saved_person.build_consumer_role(valid_params) }

      it "should save" do
        expect(consumer_role.save).to be_truthy
      end

      context "and it is saved" do
        before do
          consumer_role.save
        end

        it "should be findable" do
          expect(ConsumerRole.find(consumer_role.id).id).to eq consumer_role.id
        end

        context "and the consumer's should not have a identity_verified identity" do

          it "identity state should be unidentity_verified" do
            expect(consumer_role.aasm_state).to eq "identity_unverified"
          end

          context "and a recognized authority verifies the consumer's identity" do
            before do
              consumer_role.identity_final_decision_code = "ACC"
              consumer_role.identity_response_code = "xyz321abc"
              consumer_role.verify_identity
            end

            it "identity state should transition to identity verified status" do
              expect(consumer_role.aasm_state).to eq "identity_verified"
            end
          end

          context "and a recognized authority is unable to verify the consumer's identity" do
            before do
              consumer_role.identity_final_decision_code = "REF"
              consumer_role.identity_response_code = "xyz321abc"
              consumer_role.verify_identity
            end

            it "identity state should transition to followup pending status" do
              expect(consumer_role.aasm_state).to eq "identity_followup_pending"
            end

            context "and authority is subsequently able to verify consumer's identity" do
              before do
                consumer_role.identity_final_decision_code = "ACC"
                consumer_role.identity_response_code = "xyz321abc"
                consumer_role.verify_identity
              end

              it "identity state should transition to identity verified status" do
                expect(consumer_role.aasm_state).to eq "identity_verified"
              end
            end
          end

          context "and the identity verification status is imported from a trusted source" do
            context "and trusted source doesn't pass sufficient verification content" do
              before do
                consumer_role.identity_final_decision_code = ""
                consumer_role.identity_response_code = ""
              end

              it "identity state should stay in identity_unverified status" do
                expect(consumer_role.may_import_identity?).to be_falsey
              end
            end

            context "and the consumer's identity is identity_verified" do
              before do
                consumer_role.identity_final_decision_code = "ACC"
                consumer_role.identity_response_code = "xyz321abc"
                consumer_role.import_identity
              end

              it "identity state should transition to identity verified status" do
                expect(consumer_role.aasm_state).to eq "identity_verified"
              end
            end

            context "and the consumer's identity isn't identity verified" do
              before do
                consumer_role.identity_final_decision_code = "REF"
                consumer_role.identity_response_code = "xyz321abc"
                consumer_role.import_identity
              end

              it "identity state should transition to followup pending status" do
                expect(consumer_role.aasm_state).to eq "identity_followup_pending"
              end
            end

          end
        end

      end
    end

    # context "with no is_incarcerated" do
    #   let(:params) {valid_params.except(:is_incarcerated)}

    #   it "should fail validation " do
    #     expect(ConsumerRole.create(**params).errors[:is_incarcerated].any?).to be_truthy
    #   end
    # end

    # context "with no is_applicant" do
    #   let(:params) {valid_params.except(:is_applicant)}
    #   it "should fail validation" do
    #     expect(ConsumerRole.create(**params).errors[:is_applicant].any?).to be_truthy
    #   end
    # end

    # context "with no citizen_status" do
    #   let(:params) {valid_params.except(:citizen_status)}
    #   it "should fail validation" do
    #     expect(ConsumerRole.create(**params).errors[:citizen_status].any?).to be_truthy
    #   end
    # end

    # context "with improper citizen_status" do
    #   let(:params) {valid_params.deep_merge({citizen_status: "test citizen_status"})}
    #   it "should fail validation with improper citizen_status" do
    #     expect(ConsumerRole.create(**params).errors[:citizen_status].any?).to be_truthy
    #     expect(ConsumerRole.create(**params).errors[:citizen_status]).to eq [citizen_error_message]

    #   end
    # end
  end

end
