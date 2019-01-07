require 'rails_helper'

module BenefitSponsors
  RSpec.describe ::BenefitSponsors::Services::StaffRoleService, type: :model, :dbclean => :after_each do
    let!(:security_question)  { FactoryBot.create_default :security_question }

    let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:employer_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)        { employer_organization.employer_profile }

    let!(:broker_organization)                  { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }

    let(:broker_agency_profile) { broker_organization.broker_agency_profile }


    # let!(:employer_profile) {benefit_sponsor.employer_profile}
    let!(:active_employer_staff_role) {FactoryGirl.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
    let!(:person) { FactoryGirl.create(:person, employer_staff_roles:[active_employer_staff_role]) }
    let!(:broker_agency_staff_role) {FactoryGirl.build(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id)}
    let!(:active_employer_staff_role) {FactoryGirl.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
    let!(:broker_person) { FactoryGirl.create(:person) }
    let(:user) { FactoryGirl.create(:user, :person => person)}

    describe ".find_profile" do

      context "Employer profile" do
        let(:staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: employer_profile.id)
        }

        it 'should return employer profile' do
          expect(subject.find_profile(staff_role_form)).to eq employer_profile
        end
      end

      context "Broker Agency profile" do
        let(:staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: broker_agency_profile.id,
            profile_type: "broker_agency_staff")
        }

        it 'should return employer profile' do
          expect(subject.find_profile(staff_role_form)).to eq broker_agency_profile
        end
      end
    end

    describe ".add_profile_representative!", dbclean: :after_each do

      context "adding staff role with non existing person" do

        let(:invalid_add_staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: employer_profile.id,
            first_name:'new_staff_first_name',
            last_name:'new_staff_first_name',
            dob:TimeKeeper.date_of_record)
        }

        it 'should not add staff role for profile' do
          expect(subject.add_profile_representative!(invalid_add_staff_role_form)).to eq [false,"Person does not exist on the HBX Exchange"]
        end
      end

      context "adding staff role with existing person" do

        let!(:new_person) { FactoryBot.create(:person) }
        let!(:add_staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: employer_profile.id,
            first_name:new_person.first_name,
            last_name:new_person.last_name,
            dob:Date.new(1972,04,04).to_s)
        }

        it 'should add staff role for profile' do
          expect(subject.add_profile_representative!(add_staff_role_form)).to eq [true, new_person]
        end
      end

      context "adding broker staff role for new person" do
          let!(:new_person) { FactoryGirl.create(:person) }
          let(:staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
              profile_id: broker_agency_profile.id,
              profile_type: "broker_agency_staff",
              first_name: new_person.first_name,
              last_name: new_person.last_name,
              dob: new_person.dob.to_s,
              email: "steve@gmail.com")
          }

          it 'should add broker staff role for broker agency profile' do
            expect(subject.add_profile_representative!(staff_role_form)).to eq [true, new_person]
          end
      end

      context "adding person to broker agency in which he is already a staff" do
        before do
          person.broker_agency_staff_roles << broker_agency_staff_role
        end
        let(:staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: broker_agency_profile.id,
            profile_type: "broker_agency_staff",
            first_name: person.first_name,
            last_name: person.last_name,
            dob: person.dob.to_s,
            email: "steve@gmail.com")
        }

        it 'should not add broker staff role' do
          expect(subject.add_profile_representative!(staff_role_form)).to eq [false, "you are already associated with this Broker Agency"]
        end
      end
    end

    describe ".deactivate_profile_representative!", dbclean: :after_each do

      context "employer profile with one staff role." do

        let!(:deactivate_staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: employer_profile.id,
            first_name:person.first_name,
            last_name:person.last_name,
            dob:person.dob.to_s,
            person_id:person.id)
        }

        it 'should not deactivate only staff role' do
          expect(subject.deactivate_profile_representative!(deactivate_staff_role_form)).to eq [false,"Please add another staff role before deleting this role"]
        end
      end

      context "employer profile more than one staff role." do

        let!(:another_person_active_employer_staff_role) {FactoryBot.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
        let!(:another_person) { FactoryBot.create(:person, employer_staff_roles:[another_person_active_employer_staff_role]) }
        let!(:deactivate_staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: employer_profile.id,
            first_name:another_person.first_name,
            last_name:another_person.last_name,
            dob:another_person.dob.to_s,
            person_id:another_person.id)
        }

        it 'should deactivate staff role' do
          expect(subject.deactivate_profile_representative!(deactivate_staff_role_form)).to eq [true,"Employee Staff Role is inactive"]
        end
      end
    end

    describe ".approve_profile_representative!", dbclean: :after_each do

      context "staff role with applicant status" do

        let!(:another_person_active_employer_staff_role) {FactoryBot.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_applicant', benefit_sponsor_employer_profile_id: employer_profile.id)}
        let!(:another_person) { FactoryBot.create(:person, employer_staff_roles:[another_person_active_employer_staff_role]) }
        let!(:approve_staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: employer_profile.id,
            first_name:another_person.first_name,
            last_name:another_person.last_name,
            dob:another_person.dob.to_s,
            person_id:another_person.id)
        }

        it 'should approve staff role' do
          expect(subject.approve_profile_representative!(approve_staff_role_form)).to eq [true,"Role is approved"]
          another_person_active_employer_staff_role.reload
          expect(another_person_active_employer_staff_role.aasm_state).to eq "is_active"
        end
      end

      context "staff role with is_closed status" do

        let!(:another_person_active_employer_staff_role) {FactoryBot.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_closed', benefit_sponsor_employer_profile_id: employer_profile.id)}
        let!(:another_person) { FactoryBot.create(:person, employer_staff_roles:[another_person_active_employer_staff_role]) }
        let!(:approve_staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: employer_profile.id,
            first_name:another_person.first_name,
            last_name:another_person.last_name,
            dob:another_person.dob.to_s,
            person_id:another_person.id)
        }

        it 'should not approve staff role' do
          expect(subject.approve_profile_representative!(approve_staff_role_form)).to eq [false, "Please contact HBX Admin to report this error"]
        end
      end

    end

    describe ".match_or_create_person", dbclean: :after_each do
      context 'when more than 1 person matched' do
        before :each do
          2.times { FactoryGirl.create(:person, first_name: "steve", last_name: "smith", dob: "10/10/1974") }
        end

        let(:staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: broker_agency_profile.id,
            profile_type: "broker_agency_staff",
            first_name: "steve",
            last_name: "smith",
            dob: "10/10/1974")
        }
        it "should raise an exception" do
          expect(subject.match_or_create_person(staff_role_form)).to eq [false, "too many people match the criteria provided for your identity.  Please contact HBX."]
        end
      end

      context 'when no person matched' do
        let(:staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: broker_agency_profile.id,
            profile_type: "broker_agency_staff",
            first_name: "steve",
            last_name: "smith",
            dob: "10/10/1974",
            email: "steve@gmail.com")
        }
        it "should build a new person" do
          expect(subject.match_or_create_person(staff_role_form)).to eq true
          expect(subject.person.first_name).to eq "steve"
        end
      end

      context 'when only one person matched' do
        let(:staff_role_form) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(
            profile_id: broker_agency_profile.id,
            profile_type: "broker_agency_staff",
            first_name: person.first_name,
            last_name: person.last_name,
            dob: person.dob,
            email: "steve@gmail.com")
        }
        it "form should assign person to exisiting person" do
          expect(subject.match_or_create_person(staff_role_form)).to eq true
          expect(subject.person.first_name).to eq person.first_name
        end
      end
    end
  end
end
