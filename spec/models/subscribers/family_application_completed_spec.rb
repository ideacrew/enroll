require "rails_helper"

describe Subscribers::FamilyApplicationCompleted do
  it "should subscribe to the correct event" do
    expect(Subscribers::FamilyApplicationCompleted.subscription_details).to eq ["acapi.info.events.family.application_completed"]
  end

  describe "given an xml" do
    let(:message) { { "body" => xml } }
    let(:hbx_profile_organization) { double("HbxProfile", benefit_sponsorship:  double(current_benefit_coverage_period: double(slcsp: Plan.new.id)))}

    context "with valid single member in payload" do
      let(:xml) { File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_sample.xml")) }

      context "with no person matched to user and no primary family associated with the person" do
        it "log both the errors" do
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to match(/No person found for user/)
            expect(arg2).to eq({:severity => 'error'})
          end
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to match(/Failed to find primary family for users person/)
            expect(arg2).to eq({:severity => 'error'})
          end
          subject.call(nil, nil, nil, nil, message)
        end
      end

      context "with no person matched to user and no primary family associated with the person" do
        let(:person) { FactoryGirl.create(:person) }

        before do
          allow(Person).to receive(:where).and_return([person])
        end

        it "log the error" do
          expect(subject).to receive(:log) do |arg1, arg2|
            expect(arg1).to match(/Failed to find primary family for users person/)
            expect(arg2).to eq({:severity => 'error'})
          end
          subject.call(nil, nil, nil, nil, message)
        end
      end

      context "with a valid single person family" do
        let(:person) { FactoryGirl.create(:person) }
        let(:family) { Family.new.build_from_person(person) }
        let(:consumer_role) { FactoryGirl.create(:consumer_role, person: person) }

        before do
          family.save!
          allow(HbxProfile).to receive(:current_hbx).and_return(hbx_profile_organization)
          allow(person).to receive(:consumer_role).and_return(consumer_role)
          allow(Person).to receive(:where).and_return([person])
          allow(Organization).to receive(:where).and_return([hbx_profile_organization])
        end

        after do
          family.e_case_id = nil
          family.save!
        end

        it "shouldn't log any errors" do
          expect(subject).not_to receive(:log)
          subject.call(nil, nil, nil, nil, message)
        end

        context "it runs with the same e_case_id/integrated_case_id" do

          it "should log a save error on the unqiue field of e_case_id on family " do
            subject.call(nil, nil, nil, nil, message)
            expect(subject).to receive(:log) do |arg1, arg2|
              expect(arg1).to match(/Integrated case id already exists in another family/)
              expect(arg2).to eq({:severity => 'error'})
            end
            subject.call(nil, nil, nil, nil, message)
          end
        end
      end

      context "with the xml person built by EnrollmentFactory family logging no errors" do
        let(:user) { FactoryGirl.create(:user) }
        let(:parser) { Parsers::Xml::Cv::VerifiedFamilyParser.new.parse(File.read(Rails.root.join("spec", "test_data", "verified_family_payloads", "valid_verified_family_sample.xml"))).first }
        let(:primary) { parser.family_members.detect{ |fm| fm.id == parser.primary_family_member_id } }
        let(:person) { consumer_role.person }
        let(:ua_params) do
          {
            addresses: [],
            phones: [],
            emails: [],
            person: {
              "first_name" => primary.person.name_first,
              "last_name" => primary.person.name_last,
              "middle_name" => primary.person.name_middle,
              "name_pfx" => primary.person.name_pfx,
              "name_sfx" => primary.person.name_sfx,
              "dob" => primary.person_demographics.birth_date,
              "ssn" => primary.person_demographics.ssn,
              "no_ssn" => "",
              "gender" => primary.person_demographics.sex.split('#').last
            }
          }
        end

        let(:consumer_role) { Factories::EnrollmentFactory.construct_consumer_role(ua_params,user) }
        let(:tax_household) { person.primary_family.active_household.tax_households.first }

        before do
          person.save!
          expect(subject).not_to receive(:log)
          allow(HbxProfile).to receive(:current_hbx).and_return(hbx_profile_organization)
          subject.call(nil, nil, nil, nil, message)
        end

        it "builds a default taxhousehold with primary person as primary applicant and updates consumer role to fully vlp verified" do
          expect(tax_household).to be_truthy
          expect(tax_household.primary_applicant.family_member.person).to eq person
          expect(tax_household.allocated_aptc).to eq 20
          expect(tax_household.is_eligibility_determined).to be_truthy
          consumer_role.reload
          expect(consumer_role.fully_verified?).to be_truthy
          expect(consumer_role.vlp_authority).to eq "curam"
          expect(consumer_role.residency_determined_at).to eq primary.created_at
          expect(consumer_role.citizen_status).to eq primary.verifications.citizen_status.split('#').last
          expect(consumer_role.is_state_resident).to eq primary.verifications.is_lawfully_present
          expect(consumer_role.is_incarcerated).to eq primary.person_demographics.is_incarcerated
          person.reload
          expect(person.addresses).to be_truthy
        end
      end

    end
  end
end
