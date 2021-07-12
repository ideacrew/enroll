# frozen_string_literal: true

module HbxAdminWorld
  def hbx_admin(*traits)
    p_staff = Permission.create(name: 'hbx_staff', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
                                send_broker_agency_message: true, approve_broker: true, approve_ga: true, modify_admin_tabs: true, view_admin_tabs: true, can_update_ssn: true,
                                can_complete_resident_application: true,can_add_sep: true, can_view_username_and_email: true, can_view_application_types: true, view_personal_info_page: true,
                                can_access_new_consumer_application_sub_tab: true, can_access_outstanding_verification_sub_tab: true, can_access_identity_verification_sub_tab: true,
                                can_send_secure_message: true,
                                can_access_accept_reject_paper_application_documents: true, can_delete_identity_application_documents: true, can_access_accept_reject_identity_documents: true)
    attributes = traits.extract_options!
    @hbx_admin ||= FactoryBot.create :user, *traits, attributes
    hbx_profile = FactoryBot.create :hbx_profile
    FactoryBot.create :hbx_staff_role, person: @hbx_admin.person, hbx_profile: hbx_profile, permission_id: p_staff.id
    @hbx_admin
  end

  def hbx_admin_with_subrole(subrole)
    @u1 = User.create(email: 'hbx_admin_role@dc.gov', password: 'P@55word', password_confirmation: 'P@55word', oim_id: 'hbx_admin_role@dc.gov', roles: ["hbx_staff"])
    hbx_profile_id = FactoryBot.create(:hbx_profile).id
    p1 = Person.create(first_name: 'staff', last_name: "amanda#{rand(1_000_000)}", user: @u1)
    permission_hbx_staff = FactoryBot.create(:permission, subrole.to_sym)
    HbxStaffRole.create!(person: p1, permission_id: permission_hbx_staff.id, subrole: subrole, hbx_profile_id: hbx_profile_id)
  end
end
World(HbxAdminWorld)

Given(/^an HBX admin exists$/) do
  hbx_admin :with_family, :hbx_staff
end

Given(/^the HBX admin is logged in$/) do
  login_as hbx_admin
end

Given(/^a Hbx admin with hbx_staff role exists$/) do
  hbx_admin_with_subrole 'hbx_staff'
end

Given(/^a Hbx admin with hbx_tier3 role exists$/) do
  hbx_admin_with_subrole 'hbx_tier3'
end

Given(/^a Hbx admin with hbx_read_only role exists$/) do
  hbx_admin_with_subrole 'hbx_read_only'
end

Given(/^a Hbx admin with hbx_csr_supervisor role exists$/) do
  hbx_admin_with_subrole 'hbx_csr_supervisor'
end

Given(/^a Hbx admin with hbx_csr_tier1 role exists$/) do
  hbx_admin_with_subrole 'hbx_csr_tier1'
end

Given(/^a Hbx admin with hbx_csr_tier2 role exists$/) do
  hbx_admin_with_subrole 'hbx_csr_tier2'
end

Given(/^a Hbx admin logs on to Portal$/) do
  visit "/users/sign_in"
  fill_in SignIn.username, :with => @u1.oim_id
  fill_in SignIn.password, :with => @u1.password
  find(SignIn.sign_in_btn).click
  visit exchanges_hbx_profiles_root_path
end
