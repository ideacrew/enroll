require "rails_helper"

describe CensusEmployeePolicy, dbclean: :after_each do
  subject { described_class }
  let(:employer_profile){ FactoryBot.create(:employer_profile)}
  let(:person) { FactoryBot.create(:person) }
  let(:admin_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
  let(:broker_person) { FactoryBot.create(:person, :with_broker_role) }

  before do 
    allow_any_instance_of(CensusEmployee).to receive(:generate_and_deliver_checkbook_url).and_return(true)
  end

  permissions :delink? do
    context "already linked" do
      let(:employee) { FactoryBot.build(:census_employee, employer_profile_id: employer_profile.id, aasm_state: "employee_role_linked") }

      context "with perosn with appropriate roles" do
        it "grants access when hbx_staff" do
          expect(subject).to permit(FactoryBot.create(:user, :hbx_staff, person: admin_person), employee)
        end

        it "grants access when broker" do
          expect(subject).to permit(FactoryBot.create(:user, :broker, person: broker_person), employee)
        end

        it "grants access when broker_agency_staff" do
          expect(subject).to permit(FactoryBot.create(:user, :broker_agency_staff, person: broker_person), employee)
        end
      end

      it "denies access when normal user" do
        expect(subject).not_to permit(FactoryBot.create(:user), employee)
      end
    end

    context "not linked" do
      let(:employee) { FactoryBot.create(:census_employee, employer_profile_id: employer_profile.id, aasm_state: "eligible") }

      it "denies access when hbx_staff" do
        expect(subject).not_to permit(FactoryBot.create(:user, :hbx_staff, person: admin_person), employee)
      end

      it "denies access when broker" do
        expect(subject).not_to permit(FactoryBot.create(:user, :broker, person: broker_person), employee)
      end

      it "denies access when broker_agency_staff" do
        expect(subject).not_to permit(FactoryBot.create(:user, :broker_agency_staff, person: broker_person), employee)
      end

      it "denies access when normal user" do
        expect(subject).not_to permit(FactoryBot.create(:user, person: person), employee)
      end
    end
  end

  permissions :update? do
    let(:employee) { FactoryBot.create(:census_employee, employer_profile_id: employer_profile.id, aasm_state: "eligible") }

    context "when is hbx_staff user" do
      let(:user) { FactoryBot.create(:user, :hbx_staff, person: admin_person) }

      it "grants access when change dob" do
        employee.dob = TimeKeeper.date_of_record
        expect(subject).to permit(user, employee)
      end

      it "grants access when change ssn" do
        employee.ssn = "123321456"
        expect(subject).to permit(user, employee)
      end
    end

    context "when is normal user" do
      let(:user) { FactoryBot.create(:user) }

      it "denies access when change dob" do
        employee.dob = TimeKeeper.date_of_record
        expect(subject).not_to permit(user, employee)
      end

      it "denies access when change ssn" do
        employee.ssn = "123321456"
        expect(subject).not_to permit(user, employee)
      end
    end

    context "when is broker user" do
      let(:user) { FactoryBot.create(:user, :broker, person: person) }

      context "current user is broker of employer_profile" do
        before :each do
          allow(employer_profile).to receive(:active_broker).and_return person
          allow(employee).to receive(:employer_profile).and_return employer_profile
        end

        it "grants access when change dob" do
          employee.dob = TimeKeeper.date_of_record
          expect(subject).to permit(user, employee)
        end

        it "grants access when change ssn" do
          employee.ssn = "123321456"
          expect(subject).to permit(user, employee)
        end
      end

      context "current user is not broker of employer_profile" do
        before :each do
          allow(employer_profile).to receive(:active_broker).and_return FactoryBot.build(:person)
          allow(employee).to receive(:employer_profile).and_return employer_profile
        end

        it "denies access when change dob" do
          employee.dob = TimeKeeper.date_of_record
          expect(subject).not_to permit(user, employee)
        end

        it "denies access when change ssn" do
          employee.ssn = "123321456"
          expect(subject).not_to permit(user, employee)
        end
      end
    end

    context "when is employer_staff user" do
      let(:user) { FactoryBot.create(:user, :employer_staff) }

      context "not linked" do
        before do
          allow(employee).to receive(:eligible?).and_return(true)
        end

        context "when employee is staff of current user" do
          let(:employer_staff_role) {double(benefit_sponsor_employer_profile_id: employer_profile.id)}
          let(:employer_staff_roles) { [employer_staff_role] }
          before :each do
            allow(person).to receive(:employer_staff_roles).and_return employer_staff_roles
            allow(user).to receive(:person).and_return person
            allow(employee).to receive(:benefit_sponsors_employer_profile_id).and_return employer_profile.id
          end

          it "grants access when change dob" do
            employee.dob = TimeKeeper.date_of_record
            expect(subject).to permit(user, employee)
          end

          it "grants access when change ssn" do
            employee.ssn = "123321456"
            expect(subject).to permit(user, employee)
          end
        end

        context "when employee is not staff of current user" do
          let(:employer_staff_role) {double(benefit_sponsor_employer_profile_id: EmployerProfile.new.id)}
          let(:employer_staff_roles) { [employer_staff_role] }
          before :each do
            allow(person).to receive(:employer_staff_roles).and_return employer_staff_roles
            allow(user).to receive(:person).and_return person
            allow(employee).to receive(:benefit_sponsors_employer_profile_id).and_return employer_profile.id
          end

          it "denies access when change dob" do
            employee.dob = TimeKeeper.date_of_record
            expect(subject).not_to permit(user, employee)
          end

          it "denies access when change ssn" do
            employee.ssn = "123321456"
            expect(subject).not_to permit(user, employee)
          end
        end
      end

      context "has linked" do
        before do
          allow(employee).to receive(:eligible?).and_return(false)
        end

        context "when employee is staff of current user" do
          let(:employer_staff_role) {double(benefit_sponsor_employer_profile_id: employer_profile.id)}
          let(:employer_staff_roles) { [employer_staff_role] }
          before :each do
            allow(person).to receive(:employer_staff_roles).and_return employer_staff_roles
            allow(user).to receive(:person).and_return person
            allow(employee).to receive(:benefit_sponsors_employer_profile_id).and_return employer_profile.id
          end

          it "grants access when change dob" do
            employee.dob = TimeKeeper.date_of_record
            expect(subject).to permit(user, employee)
          end

          it "grants access when change ssn" do
            employee.ssn = "123321456"
            expect(subject).to permit(user, employee)
          end
        end

        context "when employee is not staff of current user" do
          let(:employer_staff_role) {double(benefit_sponsor_employer_profile_id: EmployerProfile.new.id)}
          let(:employer_staff_roles) { [employer_staff_role] }
          before :each do
            allow(person).to receive(:employer_staff_roles).and_return employer_staff_roles
            allow(user).to receive(:person).and_return person
            allow(employee).to receive(:benefit_sponsors_employer_profile_id).and_return employer_profile.id
          end

          it "denies access when change dob" do
            employee.dob = TimeKeeper.date_of_record
            expect(subject).not_to permit(user, employee)
          end

          it "denies access when change ssn" do
            employee.ssn = "123321456"
            expect(subject).not_to permit(user, employee)
          end
        end
      end
    end
    context "when is general agency user", dbclean: :after_each do
      let(:user) { FactoryBot.create(:user, :general_agency_staff, person: person) }
      context "current user is broker of employer_profile" do

        let!(:employee) { FactoryBot.create(:census_employee, benefit_sponsors_employer_profile_id: bs_employer_profile.id, aasm_state: "eligible", employer_profile_id: '', benefit_sponsorship: benefit_sponsorship) }
        let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
        let(:start_on) { TimeKeeper.date_of_record }
        let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site) }
        let!(:bs_employer_profile)    { organization.employer_profile }
        let!(:benefit_sponsorship) do
          bs = bs_employer_profile.add_benefit_sponsorship
          bs.save
          bs
        end

        let(:broker_agency) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site)}
        let(:broker_agency_profile)  { broker_agency.broker_agency_profile }

        let(:general_agency) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, :with_site) }
        let(:general_agency_profile) { general_agency.profiles.first }

        let!(:plan_design_organization) { FactoryBot.create(:sponsored_benefits_plan_design_organization, sponsor_profile_id: bs_employer_profile.id) }
        let!(:general_agency_account) { plan_design_organization.general_agency_accounts.create(general_agency_profile: general_agency_profile, start_on: start_on, broker_role_id: broker_agency_profile.primary_broker_role.id) }

        let(:person) { FactoryBot.create(:person) }
        let!(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, person: person)}

        it "grants access when change dob" do
          employee.dob = TimeKeeper.date_of_record
          expect(subject).to permit(user, employee)
        end

        it "grants access when change ssn" do
          employee.ssn = "879876"
          expect(subject).to permit(user, employee)
        end
      end

      context "current user is not broker of general agency role" do
        let(:user) { FactoryBot.create(:user, person: person) }
        it "denies access when change dob" do
          employee.dob = TimeKeeper.date_of_record
          expect(subject).not_to permit(user, employee)
        end

        it "denies access when change ssn" do
          employee.ssn = "123321456"
          expect(subject).not_to permit(user, employee)
        end
      end
    end
  end
end
