require "rails_helper"

describe HbxProfilePolicy do
  subject { described_class }
  let(:hbx_profile){ hbx_staff_person.hbx_staff_role.hbx_profile }
  let(:permission) { FactoryBot.create(:permission, modify_family: true)}
  let(:hbx_staff_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
  let(:assister_person) { FactoryBot.create(:person, :with_assister_role) }
  let(:csr_person) { FactoryBot.create(:person, :with_csr_role) }
  let(:employee_person) { FactoryBot.create(:person, :with_employee_role)}
  let(:hbx_staff_role) { hbx_staff_person.hbx_staff_role }

  before do
    allow(hbx_staff_role).to receive(:permission).and_return permission
  end

  permissions :show? do
    it "grants access when hbx_staff" do
      expect(subject).to permit(FactoryBot.build(:user, :hbx_staff, person: hbx_staff_person), HbxProfile)
    end

    it "denies access when employee" do
      expect(subject).not_to permit(FactoryBot.build(:user, :employee, person: employee_person), HbxProfile)
    end

    it "denies access when normal user" do
      expect(subject).not_to permit(User.new, HbxProfile)
    end
  end

  permissions :can_view_or_change_translations? do
    let!(:super_admin_user) { FactoryBot.create(:user, :with_hbx_staff_role, person: super_admin_person) }
    let!(:super_admin_permission) { FactoryBot.create(:permission, :super_admin) }
    let!(:super_admin_person) { FactoryBot.create(:person) }
    let!(:hbx_profile) { FactoryBot.create(:hbx_profile) }
    let!(:hbx_super_admin_staff_role) do
      HbxStaffRole.create!(person: super_admin_person, permission_id: super_admin_permission.id, subrole: super_admin_subrole, hbx_profile_id: hbx_profile.id)
    end
    let(:super_admin_subrole) { 'super_admin' }
    it "grants access to super admin staff" do
      expect(subject).to permit(super_admin_user, HbxProfile)
    end

    it "denies access when csr" do
      expect(subject).not_to permit(FactoryBot.build(:user, :csr, person: csr_person), HbxProfile)
    end

    it "denies access when assister" do
      expect(subject).not_to permit(FactoryBot.build(:user, :assister, person: assister_person), HbxProfile)
    end

    it "denies access when employee" do
      expect(subject).not_to permit(FactoryBot.build(:user, :employee, person: employee_person), HbxProfile)
    end

    it "denies access when normal user" do
      expect(subject).not_to permit(User.new, HbxProfile)
    end
  end

  permissions :index? do
    it "grants access when hbx_staff" do
      expect(subject).to permit(FactoryBot.build(:user, :hbx_staff, person: hbx_staff_person), HbxProfile)
    end

    it "denies access when csr" do
      expect(subject).not_to permit(FactoryBot.build(:user, :csr, person: csr_person), HbxProfile)
    end

    it "denies access when normal user" do
      expect(subject).not_to permit(User.new, HbxProfile)
    end
  end

  permissions :edit? do
    it "denies access when csr" do
      expect(subject).not_to permit(FactoryBot.build(:user, :csr, person: csr_person), HbxProfile)
    end

    it "denies access when normal user" do
      expect(subject).not_to permit(User.new, HbxProfile)
    end

    context "when hbx_staff" do
      let(:user) { FactoryBot.create(:user, :hbx_staff, person: hbx_staff_person) }

      it "grants access" do
        expect(subject).to permit(user, hbx_profile)
      end

      it "denies access" do
        expect(subject).not_to permit(user, HbxProfile.new)
      end
    end
  end

  describe "given an HbxStaffRole with permissions" do
    let(:person){FactoryBot.create(:person, user: user)}
    let(:user){FactoryBot.create(:user)}
    let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person)}
    let(:policy){HbxProfilePolicy.new(user,hbx_profile)}
    let(:hbx_profile) {FactoryBot.create(:hbx_profile)}

    it 'hbx_staff' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_staff))
      expect(policy.modify_admin_tabs?).to be true
      expect(policy.view_admin_tabs?).to be true
      expect(policy.send_broker_agency_message?).to be true
      expect(policy.approve_broker?).to be true
      expect(policy.approve_ga?).to be true
      expect(policy.view_the_configuration_tab?).to be false
      expect(policy.can_submit_time_travel_request?).to be false
      expect(policy.can_access_accept_reject_identity_documents?).to be false
      expect(policy.can_access_accept_reject_paper_application_documents?).to be false
      expect(policy.can_delete_identity_application_documents?).to be false
      expect(policy.can_access_age_off_excluded?).to be true
      expect(policy.can_send_secure_message?).to be false
      expect(policy.can_edit_osse_eligibility?).to be true
    end

    it 'hbx_read_only' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_read_only))
      expect(policy.modify_admin_tabs?).to be false
      expect(policy.view_admin_tabs?).to be true
      expect(policy.send_broker_agency_message?).to be false
      expect(policy.approve_broker?).to be false
      expect(policy.approve_ga?).to be false
      expect(policy.view_the_configuration_tab?).to be false
      expect(policy.can_submit_time_travel_request?).to be false
      expect(policy.can_access_accept_reject_identity_documents?).to be false
      expect(policy.can_access_accept_reject_paper_application_documents?).to be false
      expect(policy.can_delete_identity_application_documents?).to be false
      expect(policy.can_access_age_off_excluded?).to be false
      expect(policy.can_send_secure_message?).to be false
      expect(policy.can_edit_osse_eligibility?).to be false
    end

    it 'hbx_csr_supervisor' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_csr_supervisor))
      expect(policy.modify_admin_tabs?).to be false
      expect(policy.view_admin_tabs?).to be false
      expect(policy.send_broker_agency_message?).to be false
      expect(policy.approve_broker?).to be false
      expect(policy.approve_ga?).to be false
      expect(policy.view_the_configuration_tab?).to be false
      expect(policy.can_submit_time_travel_request?).to be false
      expect(policy.can_access_accept_reject_identity_documents?).to be false
      expect(policy.can_access_accept_reject_paper_application_documents?).to be false
      expect(policy.can_delete_identity_application_documents?).to be false
      expect(policy.can_access_age_off_excluded?).to be true
      expect(policy.can_send_secure_message?).to be false
      expect(policy.can_edit_osse_eligibility?).to be false
    end

    it 'hbx_csr_tier2' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_csr_tier2))
      expect(policy.modify_admin_tabs?).to be false
      expect(policy.view_admin_tabs?).to be false
      expect(policy.send_broker_agency_message?).to be false
      expect(policy.approve_broker?).to be false
      expect(policy.approve_ga?).to be false
      expect(policy.view_the_configuration_tab?).to be false
      expect(policy.can_submit_time_travel_request?).to be false
      expect(policy.can_access_accept_reject_identity_documents?).to be false
      expect(policy.can_access_accept_reject_paper_application_documents?).to be false
      expect(policy.can_delete_identity_application_documents?).to be false
      expect(policy.can_access_age_off_excluded?).to be true
      expect(policy.can_send_secure_message?).to be false
      expect(policy.can_edit_osse_eligibility?).to be false
    end

    it 'csr_tier1' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_csr_tier1))
      expect(policy.modify_admin_tabs?).to be false
      expect(policy.view_admin_tabs?).to be false
      expect(policy.send_broker_agency_message?).to be false
      expect(policy.approve_broker?).to be false
      expect(policy.approve_ga?).to be false
      expect(policy.view_the_configuration_tab?).to be false
      expect(policy.can_submit_time_travel_request?).to be false
      expect(policy.can_access_age_off_excluded?).to be true
      expect(policy.can_send_secure_message?).to be false
      expect(policy.can_edit_osse_eligibility?).to be false
    end

    it 'super_admin' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :super_admin))
      expect(policy.modify_admin_tabs?).to be true
      expect(policy.view_admin_tabs?).to be true
      expect(policy.send_broker_agency_message?).to be true
      expect(policy.approve_broker?).to be true
      expect(policy.approve_ga?).to be true
      expect(policy.can_modify_plan_year?).to be true
      expect(policy.can_access_age_off_excluded?).to be true
      expect(policy.can_send_secure_message?).to be true
      expect(policy.can_edit_osse_eligibility?).to be true
    end

    it 'hbx_tier3' do
      allow(hbx_staff_role).to receive(:permission).and_return(FactoryBot.create(:permission, :hbx_tier3))
      expect(policy.can_send_secure_message?).to be true
      expect(policy.can_edit_osse_eligibility?).to be true
    end
  end

  describe "given no staff role" do
    let(:person) { FactoryBot.create(:person, user: user) }
    let(:user) { FactoryBot.create(:user) }
    let(:policy) { HbxProfilePolicy.new(user,hbx_profile) }
    let(:hbx_profile) { FactoryBot.create(:hbx_profile) }

    before :each do
      person
    end

    it "is prohibited from modifying admin tabs" do
      expect(policy.modify_admin_tabs?).to be false
    end

    it "is prohibited from viewing admin tabs" do
      expect(policy.view_admin_tabs?).to be false
    end

    it "is prohibited from sending broker agency messages" do
      expect(policy.send_broker_agency_message?).to be false
    end

    it "is prohibited from approving brokers" do
      expect(policy.approve_broker?).to be false
    end

    it "is prohibited from approving GAs" do
      expect(policy.approve_ga?).to be false
      expect(policy.can_access_accept_reject_identity_documents?).to be false
      expect(policy.can_access_accept_reject_paper_application_documents?).to be false
      expect(policy.can_delete_identity_application_documents?).to be false
    end

    it "is prohibited from extending open enrollment" do
      expect(policy.can_extend_open_enrollment?).to be false
    end

    it "is prohibited from extending creating benefit applications" do
      expect(policy.can_create_benefit_application?).to be false
    end

    it "is prohibited from changing feins" do
      expect(policy.can_change_fein?).to be false
    end

    it "is prohibited from force publishing" do
      expect(policy.can_force_publish?).to be false
    end

    it "is prohibited from viewing config tab" do
      expect(policy.view_the_configuration_tab?).to be false
    end

    it "is prohibited from time traveling" do
      expect(policy.can_submit_time_travel_request?).to be false
    end
  end

  context '.can_create_benefit_application?' do
    let!(:user10)                  { FactoryBot.create(:user) }
    let!(:person)                  { FactoryBot.create(:person, :with_hbx_staff_role, user: user10) }

    subject                        { HbxProfilePolicy.new(user10, nil) }


    (Permission::PERMISSION_KINDS - ['super_admin', 'hbx_tier3']).each do |kind|
      context "for permissions which doesn't allow the user" do
        let(:bad_permission) { FactoryBot.create(:permission, kind.to_sym) }

        it 'should return false' do
          person.hbx_staff_role.update_attributes!(permission_id: bad_permission.id)
          expect(subject.can_create_benefit_application?).to eq false
        end
      end
    end

    ['super_admin', 'hbx_tier3'].each do |kind|
      context "for permissions which doesn't allow the user" do
        let(:good_permission) { FactoryBot.create(:permission, kind.to_sym) }

        it 'should return true' do
          person.hbx_staff_role.update_attributes!(permission_id: good_permission.id)
          expect(subject.can_create_benefit_application?).to eq true
          expect(subject.can_submit_time_travel_request?).to eq false
        end
      end
    end

    context 'super admin can view config tab?' do
      let!(:user10)                  { FactoryBot.create(:user) }
      let!(:person)                  { FactoryBot.create(:person, :with_hbx_staff_role, user: user10) }

      subject                        { HbxProfilePolicy.new(user10, nil) }

      ['super_admin'].each do |kind|
        context "for permissions which doesn't allow the user" do
          let(:good_permission) { FactoryBot.create(:permission, kind.to_sym) }

          it 'should return true' do
            person.hbx_staff_role.update_attributes!(permission_id: good_permission.id)
            expect(subject.can_create_benefit_application?).to eq true
            expect(subject.can_submit_time_travel_request?).to eq false
            expect(subject.view_the_configuration_tab?).to eq true
          end
        end
      end
    end
  end

  describe 'instance methods' do
    subject { described_class.new(user, HbxProfile) }

    shared_examples_for 'access without role' do |def_name, result|
      let(:user) do
        double(
          User,
          identity_verified?: false,
          person: double(hbx_staff_role: nil, consumer_role: nil, csr_role: nil, broker_role: nil, active_general_agency_staff_roles: [], broker_agency_staff_roles: nil, resident_role: nil, primary_family: nil)
        )
      end

      it "#{def_name} returns #{result}" do
        expect(subject.send(def_name)).to eq result
      end
    end

    it_behaves_like 'access without role', :oe_extendable_applications?
    it_behaves_like 'access without role', :oe_extended_applications?
    it_behaves_like 'access without role', :edit_open_enrollment?
    it_behaves_like 'access without role', :extend_open_enrollment?
    it_behaves_like 'access without role', :close_extended_open_enrollment?
    it_behaves_like 'access without role', :new_benefit_application?
    it_behaves_like 'access without role', :create_benefit_application?
    it_behaves_like 'access without role', :edit_fein?
    it_behaves_like 'access without role', :update_fein?
    it_behaves_like 'access without role', :binder_paid?
    it_behaves_like 'access without role', :new_secure_message?
    it_behaves_like 'access without role', :create_send_secure_message?
    it_behaves_like 'access without role', :disable_ssn_requirement?
    it_behaves_like 'access without role', :generate_invoice?
    it_behaves_like 'access without role', :edit_force_publish?
    it_behaves_like 'access without role', :force_publish?
    it_behaves_like 'access without role', :employer_invoice?, false
    it_behaves_like 'access without role', :employer_datatable?, false
    it_behaves_like 'access without role', :index?, false
    it_behaves_like 'access without role', :staff_index?, false
    it_behaves_like 'access without role', :assister_index?, false
    it_behaves_like 'access without role', :family_index?, false
    it_behaves_like 'access without role', :family_index_dt?, false
    it_behaves_like 'access without role', :identity_verification?, false
    it_behaves_like 'access without role', :user_account_index?
    it_behaves_like 'access without role', :outstanding_verification_dt?, false
    it_behaves_like 'access without role', :hide_form?
    it_behaves_like 'access without role', :add_sep_form?
    it_behaves_like 'access without role', :show_sep_history?
    it_behaves_like 'access without role', :get_user_info?, false
    it_behaves_like 'access without role', :update_effective_date?
    it_behaves_like 'access without role', :calculate_sep_dates?
    it_behaves_like 'access without role', :add_new_sep?
    it_behaves_like 'access without role', :cancel_enrollment?
    it_behaves_like 'access without role', :update_cancel_enrollment?
    it_behaves_like 'access without role', :terminate_enrollment?
    it_behaves_like 'access without role', :update_terminate_enrollment?
    it_behaves_like 'access without role', :drop_enrollment_member?
    it_behaves_like 'access without role', :update_enrollment_member_drop?
    it_behaves_like 'access without role', :view_enrollment_to_update_end_date?
    it_behaves_like 'access without role', :update_enrollment_terminated_on_date?
    it_behaves_like 'access without role', :broker_agency_index?, false
    it_behaves_like 'access without role', :general_agency_index?, false
    it_behaves_like 'access without role', :configuration?
    it_behaves_like 'access without role', :view_terminated_hbx_enrollments?, false
    it_behaves_like 'access without role', :reinstate_enrollment?
    it_behaves_like 'access without role', :edit_dob_ssn?
    it_behaves_like 'access without role', :verify_dob_change?
    it_behaves_like 'access without role', :update_dob_ssn?
    it_behaves_like 'access without role', :new_eligibility?
    it_behaves_like 'access without role', :process_eligibility?
    it_behaves_like 'access without role', :create_eligibility?
    it_behaves_like 'access without role', :show?, false
    it_behaves_like 'access without role', :inbox?, false
    it_behaves_like 'access without role', :set_date?
    it_behaves_like 'access without role', :aptc_csr_family_index?, false
    it_behaves_like 'access without role', :update_setting?
    it_behaves_like 'access without role', :confirm_lock?
    it_behaves_like 'access without role', :lockable?
    it_behaves_like 'access without role', :reset_password?
    it_behaves_like 'access without role', :confirm_reset_password?
    it_behaves_like 'access without role', :change_username_and_email?
    it_behaves_like 'access without role', :confirm_change_username_and_email?
    it_behaves_like 'access without role', :login_history?

    shared_examples_for 'with role and permission' do |def_name, permission_name, permission_val, result|
      let(:user) do
        double(
          User,
          identity_verified?: false,
          person: double(hbx_staff_role: staff_role, consumer_role: nil, csr_role: nil, broker_role: nil, active_general_agency_staff_roles: [], broker_agency_staff_roles: nil, resident_role: nil, primary_family: nil)
        )
      end
      let(:staff_role) { double(permission: permission) }
      let(:permission) { double(:permission) }

      before do
        allow(permission).to receive(permission_name).and_return permission_val if permission_name
      end

      it "returns #{def_name} as #{result} when #{permission_name} is #{permission_val}" do
        expect(subject.send(def_name)).to eq result
      end
    end

    it_behaves_like 'with role and permission', :oe_extendable_applications?, :can_extend_open_enrollment, true, true
    it_behaves_like 'with role and permission', :oe_extendable_applications?, :can_extend_open_enrollment, false, false

    it_behaves_like 'with role and permission', :oe_extended_applications?, :can_extend_open_enrollment, true, true
    it_behaves_like 'with role and permission', :oe_extended_applications?, :can_extend_open_enrollment, false, false

    it_behaves_like 'with role and permission', :edit_open_enrollment?, :can_extend_open_enrollment, true, true
    it_behaves_like 'with role and permission', :edit_open_enrollment?, :can_extend_open_enrollment, false, false

    it_behaves_like 'with role and permission', :extend_open_enrollment?, :can_extend_open_enrollment, true, true
    it_behaves_like 'with role and permission', :extend_open_enrollment?, :can_extend_open_enrollment, false, false

    it_behaves_like 'with role and permission', :close_extended_open_enrollment?, :can_extend_open_enrollment, true, true
    it_behaves_like 'with role and permission', :close_extended_open_enrollment?, :can_extend_open_enrollment, false, false

    it_behaves_like 'with role and permission', :new_benefit_application?, :can_create_benefit_application, true, true
    it_behaves_like 'with role and permission', :new_benefit_application?, :can_create_benefit_application, false, false

    it_behaves_like 'with role and permission', :create_benefit_application?, :can_create_benefit_application, true, true
    it_behaves_like 'with role and permission', :create_benefit_application?, :can_create_benefit_application, false, false

    it_behaves_like 'with role and permission', :edit_fein?, :can_change_fein, true, true
    it_behaves_like 'with role and permission', :edit_fein?, :can_change_fein, false, false

    it_behaves_like 'with role and permission', :update_fein?, :can_change_fein, true, true
    it_behaves_like 'with role and permission', :update_fein?, :can_change_fein, false, false

    it_behaves_like 'with role and permission', :binder_paid?, :modify_admin_tabs, true, true
    it_behaves_like 'with role and permission', :binder_paid?, :modify_admin_tabs, false, false

    it_behaves_like 'with role and permission', :new_secure_message?, :can_send_secure_message, true, true
    it_behaves_like 'with role and permission', :new_secure_message?, :can_send_secure_message, false, false

    it_behaves_like 'with role and permission', :create_send_secure_message?, :can_send_secure_message, true, true
    it_behaves_like 'with role and permission', :create_send_secure_message?, :can_send_secure_message, false, false

    it_behaves_like 'with role and permission', :disable_ssn_requirement?, :can_update_ssn, true, true
    it_behaves_like 'with role and permission', :disable_ssn_requirement?, :can_update_ssn, false, false

    it_behaves_like 'with role and permission', :generate_invoice?, :modify_employer, true, true
    it_behaves_like 'with role and permission', :generate_invoice?, :modify_employer, false, false

    it_behaves_like 'with role and permission', :edit_force_publish?, :can_force_publish, true, true
    it_behaves_like 'with role and permission', :edit_force_publish?, :can_force_publish, false, false

    it_behaves_like 'with role and permission', :force_publish?, :can_force_publish, true, true
    it_behaves_like 'with role and permission', :force_publish?, :can_force_publish, false, false

    it_behaves_like 'with role and permission', :employer_invoice?, :modify_family, false, false
    it_behaves_like 'with role and permission', :employer_invoice?, :modify_family, true, true

    it_behaves_like 'with role and permission', :employer_datatable?, :modify_family, false, false
    it_behaves_like 'with role and permission', :employer_datatable?, :modify_family, true, true

    it_behaves_like 'with role and permission', :index?, :modify_family, false, false
    it_behaves_like 'with role and permission', :index?, :modify_family, true, true

    it_behaves_like 'with role and permission', :staff_index?, :modify_family, false, false
    it_behaves_like 'with role and permission', :staff_index?, :modify_family, true, true

    it_behaves_like 'with role and permission', :assister_index?, :modify_family, false, false
    it_behaves_like 'with role and permission', :assister_index?, :modify_family, true, true

    it_behaves_like 'with role and permission', :family_index?, :modify_family, false, false
    it_behaves_like 'with role and permission', :family_index?, :modify_family, true, true

    it_behaves_like 'with role and permission', :family_index_dt?, :modify_family, false, false
    it_behaves_like 'with role and permission', :family_index_dt?, :modify_family, true, true

    it_behaves_like 'with role and permission', :identity_verification?, :modify_family, false, false
    it_behaves_like 'with role and permission', :identity_verification?, :modify_family, true, true

    it_behaves_like 'with role and permission', :user_account_index?, :can_access_user_account_tab, true, true
    it_behaves_like 'with role and permission', :user_account_index?, :can_access_user_account_tab, false, false

    it_behaves_like 'with role and permission', :outstanding_verification_dt?, :modify_family, false, false
    it_behaves_like 'with role and permission', :outstanding_verification_dt?, :modify_family, true, true

    it_behaves_like 'with role and permission', :hide_form?, :can_add_sep, true, true
    it_behaves_like 'with role and permission', :hide_form?, :can_add_sep, false, false

    it_behaves_like 'with role and permission', :add_sep_form?, :can_add_sep, true, true
    it_behaves_like 'with role and permission', :add_sep_form?, :can_add_sep, false, false

    it_behaves_like 'with role and permission', :show_sep_history?, :can_view_sep_history, true, true
    it_behaves_like 'with role and permission', :show_sep_history?, :can_view_sep_history, false, false

    it_behaves_like 'with role and permission', :get_user_info?, :modify_family, false, false
    it_behaves_like 'with role and permission', :get_user_info?, :modify_family, true, true

    it_behaves_like 'with role and permission', :update_effective_date?, :can_add_sep, true, true
    it_behaves_like 'with role and permission', :update_effective_date?, :can_add_sep, false, false

    it_behaves_like 'with role and permission', :calculate_sep_dates?, :can_add_sep, true, true
    it_behaves_like 'with role and permission', :calculate_sep_dates?, :can_add_sep, false, false

    it_behaves_like 'with role and permission', :add_new_sep?, :can_add_sep, true, true
    it_behaves_like 'with role and permission', :add_new_sep?, :can_add_sep, false, false

    it_behaves_like 'with role and permission', :cancel_enrollment?, :can_cancel_enrollment, true, true
    it_behaves_like 'with role and permission', :cancel_enrollment?, :can_cancel_enrollment, false, false

    it_behaves_like 'with role and permission', :update_cancel_enrollment?, :can_cancel_enrollment, true, true
    it_behaves_like 'with role and permission', :update_cancel_enrollment?, :can_cancel_enrollment, false, false

    it_behaves_like 'with role and permission', :terminate_enrollment?, :can_terminate_enrollment, true, true
    it_behaves_like 'with role and permission', :terminate_enrollment?, :can_terminate_enrollment, false, false

    it_behaves_like 'with role and permission', :update_terminate_enrollment?, :can_terminate_enrollment, true, true
    it_behaves_like 'with role and permission', :update_terminate_enrollment?, :can_terminate_enrollment, false, false

    it_behaves_like 'with role and permission', :drop_enrollment_member?, :can_drop_enrollment_members, true, true
    it_behaves_like 'with role and permission', :drop_enrollment_member?, :can_drop_enrollment_members, false, false

    it_behaves_like 'with role and permission', :update_enrollment_member_drop?, :can_drop_enrollment_members, true, true
    it_behaves_like 'with role and permission', :update_enrollment_member_drop?, :can_drop_enrollment_members, false, false

    it_behaves_like 'with role and permission', :view_enrollment_to_update_end_date?, :change_enrollment_end_date, true, true
    it_behaves_like 'with role and permission', :view_enrollment_to_update_end_date?, :change_enrollment_end_date, false, false

    it_behaves_like 'with role and permission', :update_enrollment_terminated_on_date?, :change_enrollment_end_date, true, true
    it_behaves_like 'with role and permission', :update_enrollment_terminated_on_date?, :change_enrollment_end_date, false, false

    it_behaves_like 'with role and permission', :broker_agency_index?, :modify_family, false, false
    it_behaves_like 'with role and permission', :broker_agency_index?, :modify_family, true, true

    it_behaves_like 'with role and permission', :general_agency_index?, :modify_family, false, false
    it_behaves_like 'with role and permission', :general_agency_index?, :modify_family, true, true

    it_behaves_like 'with role and permission', :configuration?, :view_the_configuration_tab, true, true
    it_behaves_like 'with role and permission', :configuration?, :view_the_configuration_tab, false, false

    it_behaves_like 'with role and permission', :view_terminated_hbx_enrollments?, :modify_family, false, false
    it_behaves_like 'with role and permission', :view_terminated_hbx_enrollments?, :modify_family, true, true

    it_behaves_like 'with role and permission', :reinstate_enrollment?, :can_reinstate_enrollment, true, true
    it_behaves_like 'with role and permission', :reinstate_enrollment?, :can_reinstate_enrollment, false, false

    it_behaves_like 'with role and permission', :edit_dob_ssn?, :can_update_ssn, true, true
    it_behaves_like 'with role and permission', :edit_dob_ssn?, :can_update_ssn, false, false

    it_behaves_like 'with role and permission', :verify_dob_change?, :can_update_ssn, true, true
    it_behaves_like 'with role and permission', :verify_dob_change?, :can_update_ssn, false, false

    it_behaves_like 'with role and permission', :update_dob_ssn?, :can_update_ssn, true, true
    it_behaves_like 'with role and permission', :update_dob_ssn?, :can_update_ssn, false, false

    it_behaves_like 'with role and permission', :new_eligibility?, :can_add_pdc, true, true
    it_behaves_like 'with role and permission', :new_eligibility?, :can_add_pdc, false, false

    it_behaves_like 'with role and permission', :process_eligibility?, :can_add_pdc, true, true
    it_behaves_like 'with role and permission', :process_eligibility?, :can_add_pdc, false, false

    it_behaves_like 'with role and permission', :create_eligibility?, :can_add_pdc, true, true
    it_behaves_like 'with role and permission', :create_eligibility?, :can_add_pdc, false, false

    it_behaves_like 'with role and permission', :show?, :modify_family, false, false
    it_behaves_like 'with role and permission', :show?, :modify_family, true, true

    it_behaves_like 'with role and permission', :inbox?, :modify_family, false, false
    it_behaves_like 'with role and permission', :inbox?, :modify_family, true, true

    it_behaves_like 'with role and permission', :set_date?, :can_submit_time_travel_request, true, true
    it_behaves_like 'with role and permission', :set_date?, :can_submit_time_travel_request, false, false

    it_behaves_like 'with role and permission', :aptc_csr_family_index?, :modify_family, false, false
    it_behaves_like 'with role and permission', :aptc_csr_family_index?, :modify_family, true, true

    it_behaves_like 'with role and permission', :update_setting?, :modify_admin_tabs, true, true
    it_behaves_like 'with role and permission', :update_setting?, :modify_admin_tabs, false, false

    it_behaves_like 'with role and permission', :confirm_lock?, :can_lock_unlock, true, true
    it_behaves_like 'with role and permission', :confirm_lock?, :can_lock_unlock, false, false

    it_behaves_like 'with role and permission', :lockable?, :can_lock_unlock, true, true
    it_behaves_like 'with role and permission', :lockable?, :can_lock_unlock, false, false

    it_behaves_like 'with role and permission', :reset_password?, :can_reset_password, true, true
    it_behaves_like 'with role and permission', :reset_password?, :can_reset_password, false, false

    it_behaves_like 'with role and permission', :confirm_reset_password?, :can_reset_password, true, true
    it_behaves_like 'with role and permission', :confirm_reset_password?, :can_reset_password, false, false

    it_behaves_like 'with role and permission', :change_username_and_email?, :can_change_username_and_email, true, true
    it_behaves_like 'with role and permission', :change_username_and_email?, :can_change_username_and_email, false, false

    it_behaves_like 'with role and permission', :confirm_change_username_and_email?, :can_change_username_and_email, true, true
    it_behaves_like 'with role and permission', :confirm_change_username_and_email?, :can_change_username_and_email, false, false

    it_behaves_like 'with role and permission', :login_history?, :view_login_history, true, true
    it_behaves_like 'with role and permission', :login_history?, :view_login_history, false, false
  end
end

RSpec.describe HbxProfilePolicy, "given an unlinked user" do
  let(:user) do
    instance_double(
      User,
      :person => nil
    )
  end

  let(:subject) { described_class.new(user, nil) }

  it "is not authorized to calculate_aptc_csr" do
    expect(subject.calculate_aptc_csr?).to be_falsey
  end

  it "is not authorized to edit_aptc_csr" do
    expect(subject.edit_aptc_csr?).to be_falsey
  end
end

RSpec.describe HbxProfilePolicy, "given a linked, non-admin user" do
  let(:person) do
    instance_double(
      Person,
      :hbx_staff_role => nil
    )
  end
  let(:user) do
    instance_double(
      User,
      :person => person
    )
  end

  let(:subject) { described_class.new(user, nil) }

  it "is not authorized to calculate_aptc_csr" do
    expect(subject.calculate_aptc_csr?).to be_falsey
  end

  it "is not authorized to edit_aptc_csr" do
    expect(subject.edit_aptc_csr?).to be_falsey
  end
end

RSpec.describe HbxProfilePolicy, "given a linked, admin user without the #can_edit_aptc permission" do
  let(:permission) do
    instance_double(
      Permission,
      :can_edit_aptc => false
    )
  end
  let(:hbx_staff_role) do
    instance_double(
      HbxStaffRole,
      :permission => permission
    )
  end
  let(:person) do
    instance_double(
      Person,
      :hbx_staff_role => hbx_staff_role
    )
  end
  let(:user) do
    instance_double(
      User,
      :identity_verified? => false,
      :person => person
    )
  end

  let(:subject) { described_class.new(user, nil) }

  it "is not authorized to calculate_aptc_csr" do
    expect(subject.calculate_aptc_csr?).to be_falsey
  end

  it "is not authorized to edit_aptc_csr" do
    expect(subject.edit_aptc_csr?).to be_falsey
  end
end

RSpec.describe HbxProfilePolicy, "given a linked, admin user with the #can_edit_aptc permission" do
  let(:permission) do
    instance_double(
      Permission,
      :can_edit_aptc => true
    )
  end
  let(:hbx_staff_role) do
    instance_double(
      HbxStaffRole,
      :permission => permission
    )
  end
  let(:person) do
    instance_double(
      Person,
      :hbx_staff_role => hbx_staff_role
    )
  end
  let(:user) do
    instance_double(
      User,
      :identity_verified? => false,
      :person => person
    )
  end

  let(:subject) { described_class.new(user, nil) }

  it "is authorized to calculate_aptc_csr" do
    expect(subject.calculate_aptc_csr?).to be_truthy
  end

  it "is authorized to edit_aptc_csr" do
    expect(subject.edit_aptc_csr?).to be_truthy
  end
end