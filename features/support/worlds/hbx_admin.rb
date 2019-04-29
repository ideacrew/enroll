module HbxAdminWorld
  def hbx_admin(*traits)
    p_staff=Permission.create(name: 'hbx_staff', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
      send_broker_agency_message: true, approve_broker: true, approve_ga: true, modify_admin_tabs: true, view_admin_tabs: true, can_update_ssn: true, 
      can_complete_resident_application: true,can_add_sep: true, can_view_username_and_email: true, can_view_application_types: true, view_personal_info_page: true, 
      can_access_new_consumer_application_sub_tab: true, can_access_outstanding_verification_sub_tab: true, can_access_identity_verification_sub_tab: true, 
      can_access_accept_reject_paper_application_documents: true, can_delete_identity_application_documents: true, can_access_accept_reject_identity_documents: true)
    attributes = traits.extract_options!
    @hbx_admin ||= FactoryBot.create :user, *traits, attributes
    hbx_profile = FactoryBot.create :hbx_profile
    FactoryBot.create :hbx_staff_role, person: @hbx_admin.person, hbx_profile: hbx_profile, permission_id: p_staff.id
    @hbx_admin
  end
end
World(HbxAdminWorld)

Given(/^an HBX admin exists$/) do
  hbx_admin :with_family, :hbx_staff
end

Given(/^the HBX admin is logged in$/) do
  login_as hbx_admin, scope: :user
end
