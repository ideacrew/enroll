# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
require File.join(Rails.root, "lib/migration_task")

# It defines Maine(ME) permissions for hbx_staff
class MeDefinePermissions < MigrationTask
#All hbx_roles can view families, employers, broker_agencies, brokers and general agencies
#The convention for a privilege group 'x' is  'modify_x', or view 'view_x'


  def can_add_sep
    ENV['CAN_ADD_SEP'] || false
  end

  def can_update_ssn
    ENV['CAN_UPDATE_SSN'] || false
  end

  def csr_hbx_permissions
    Permission
      .find_or_initialize_by(name: 'hbx_csr_tier1')
      .update_attributes!(modify_family: true, modify_employer: false, revert_application: false, list_enrollments: true, can_add_sep: can_add_sep,
                          send_broker_agency_message: false, approve_broker: false, approve_ga: false, modify_admin_tabs: false, view_admin_tabs: true,
                          view_the_configuration_tab: false, can_submit_time_travel_request: false, can_access_age_off_excluded: true, manage_agency_staff: false,
                          can_update_ssn: can_update_ssn, can_lock_unlock: false, can_complete_resident_application: true, can_add_pdc: false, can_view_username_and_email: true,
                          can_transition_family_members: true, can_access_user_account_tab: true, view_login_history: false, can_reset_password: false,
                          can_view_application_types: true, view_personal_info_page: true, can_access_new_consumer_application_sub_tab: true,
                          can_access_identity_verification_sub_tab: false, can_access_accept_reject_identity_documents: false, view_agency_staff: true,
                          can_access_accept_reject_paper_application_documents: false, can_delete_identity_application_documents: false, can_access_pay_now: false,
                          can_modify_plan_year: false, can_change_fein: false, can_access_outstanding_verification_sub_tab: false, can_send_secure_message: false,
                          can_manage_qles: false, can_edit_aptc: false, can_view_sep_history: true, can_reinstate_enrollment: false, can_cancel_enrollment: false,
                          can_terminate_enrollment: false, change_enrollment_end_date: false, can_change_username_and_email: false, can_drop_enrollment_members: false, can_call_hub: true, can_edit_broker_agency_profile: true)
    Permission
      .find_or_initialize_by(name: 'hbx_csr_tier2')
      .update_attributes!(modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true, can_send_secure_message: false, can_add_sep: true,
                          send_broker_agency_message: true, approve_broker: false, approve_ga: false, modify_admin_tabs: false, view_admin_tabs: true,
                          view_the_configuration_tab: false, can_submit_time_travel_request: false, can_access_age_off_excluded: true, can_access_pay_now: false,
                          can_update_ssn: false, can_lock_unlock: false, can_complete_resident_application: true, can_add_pdc: false, can_view_username_and_email: true,
                          can_transition_family_members: true, can_access_user_account_tab: true, view_login_history: false, can_reset_password: false, can_change_username_and_email: false,
                          can_view_application_types: true, view_personal_info_page: true, can_access_new_consumer_application_sub_tab: true, can_modify_plan_year: false,
                          can_change_fein: false, can_manage_qles: false, view_agency_staff: true, manage_agency_staff: false, can_edit_aptc: false, can_view_sep_history: true,
                          can_reinstate_enrollment: false, can_cancel_enrollment: false, can_terminate_enrollment: false, change_enrollment_end_date: false,
                          can_drop_enrollment_members: false, can_call_hub: true, can_edit_broker_agency_profile: true)
    Permission
      .find_or_initialize_by(name: 'hbx_csr_supervisor')
      .update_attributes!(modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true, can_access_pay_now: false,
                          send_broker_agency_message: true, approve_broker: false, approve_ga: false, modify_admin_tabs: false, view_admin_tabs: true,
                          view_the_configuration_tab: false, can_submit_time_travel_request: false, can_access_age_off_excluded: true, can_change_username_and_email: false,
                          can_update_ssn: false, can_lock_unlock: false, can_complete_resident_application: true, can_add_pdc: false, can_view_username_and_email: true,
                          can_transition_family_members: true, can_access_user_account_tab: true, view_login_history: false, can_reset_password: false,
                          can_view_application_types: true, view_personal_info_page: true, can_access_new_consumer_application_sub_tab: true, can_modify_plan_year: false,
                          can_change_fein: false, can_manage_qles: false, view_agency_staff: true, manage_agency_staff: false, can_edit_aptc: false,
                          can_view_sep_history: true, can_reinstate_enrollment: false, can_cancel_enrollment: true, can_terminate_enrollment: true,
                          change_enrollment_end_date: false, can_drop_enrollment_members: false, can_call_hub: true, can_edit_broker_agency_profile: true)
  end

  def initial_hbx
    csr_hbx_permissions
    Permission
      .find_or_initialize_by(name: 'hbx_staff')
      .update_attributes!(modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
                          send_broker_agency_message: true, approve_broker: true, approve_ga: true, can_update_ssn: true, can_complete_resident_application: true,
                          can_add_sep: true, can_lock_unlock: false, can_view_username_and_email: true, can_reset_password: false, modify_admin_tabs: true,
                          view_admin_tabs: true,  view_the_configuration_tab: true, can_submit_time_travel_request: false, can_change_username_and_email: false,
                          view_agency_staff: true, manage_agency_staff: true, can_access_pay_now: true, can_access_age_off_excluded: true,
                          can_add_pdc: true, can_transition_family_members: true, can_access_user_account_tab: true, view_login_history: false,
                          can_view_application_types: true, view_personal_info_page: true, can_access_new_consumer_application_sub_tab: true, can_edit_aptc: true,
                          can_view_sep_history: true, can_reinstate_enrollment: true, can_cancel_enrollment: true, can_terminate_enrollment: true,
                          change_enrollment_end_date: true, can_drop_enrollment_members: true, can_call_hub: true, can_edit_broker_agency_profile: true)
    Permission
      .find_or_initialize_by(name: 'super_admin')
      .update_attributes!(modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true, can_change_username_and_email: true,
                          send_broker_agency_message: true, approve_broker: true, approve_ga: true, can_update_ssn: true, can_complete_resident_application: true,
                          can_add_sep: true, can_lock_unlock: true, can_view_username_and_email: true, can_reset_password: true, modify_admin_tabs: true,
                          view_admin_tabs: true, can_extend_open_enrollment: true, view_the_configuration_tab: true, can_submit_time_travel_request: false,
                          view_agency_staff: true, manage_agency_staff: true, can_send_secure_message: true, can_manage_qles: true, can_access_pay_now: true,
                          can_access_age_off_excluded: true, can_add_pdc: true, can_transition_family_members: true, can_access_user_account_tab: true,
                          view_login_history: true, can_view_application_types: true, view_personal_info_page: true, can_access_new_consumer_application_sub_tab: true,
                          can_edit_aptc: true, can_view_sep_history: true, can_reinstate_enrollment: true, can_cancel_enrollment: true, can_terminate_enrollment: true,
                          change_enrollment_end_date: true, can_drop_enrollment_members: true, can_call_hub: true, can_edit_broker_agency_profile: true)
    other_permissions
  end

  def other_permissions
    Permission
      .find_or_initialize_by(name: 'hbx_tier3')
      .update_attributes!(modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true, can_change_username_and_email: false,
                          send_broker_agency_message: true, approve_broker: true, approve_ga: true, can_lock_unlock: false, modify_admin_tabs: true,
                          view_admin_tabs: true,  view_the_configuration_tab: true, can_submit_time_travel_request: false, view_agency_staff: true,
                          manage_agency_staff: true, can_send_secure_message: true, can_manage_qles: true, can_access_pay_now: true, can_access_age_off_excluded: true,
                          view_login_history: false, can_reset_password: false, can_edit_aptc: true, can_view_sep_history: true, can_reinstate_enrollment: true,
                          can_cancel_enrollment: true, can_terminate_enrollment: true, change_enrollment_end_date: true, can_access_user_account_tab: true,
                          can_drop_enrollment_members: false, can_call_hub: true, can_edit_broker_agency_profile: true)
    Permission
      .find_or_initialize_by(name: 'developer')
      .update_attributes!(modify_family: false, modify_employer: false, revert_application: false, list_enrollments: true, can_access_user_account_tab: true,
                          send_broker_agency_message: false, approve_broker: false, approve_ga: false, modify_admin_tabs: false, view_admin_tabs: true,
                          view_the_configuration_tab: true, can_submit_time_travel_request: false, can_edit_aptc: false,can_view_sep_history: true,
                          can_drop_enrollment_members: false, can_call_hub: true, view_agency_staff: true)
    Permission
      .find_or_initialize_by(name: 'hbx_read_only')
      .update_attributes!(modify_family: true, modify_employer: false, revert_application: false, list_enrollments: true, can_access_user_account_tab: true,
                          send_broker_agency_message: false, approve_broker: false, approve_ga: false, modify_admin_tabs: false, view_admin_tabs: true,
                          view_the_configuration_tab: true, can_submit_time_travel_request: false, can_edit_aptc: true, can_view_sep_history: true,
                          can_drop_enrollment_members: false, can_call_hub: true, view_agency_staff: true)
  end

  def assign_current_permissions
    initial_hbx
    hbx_admin_can_update_ssn
    hbx_admin_can_access_user_account_tab
    hbx_admin_can_view_login_history
    hbx_admin_csr_view_personal_info_page
    hbx_admin_can_complete_resident_application
    hbx_admin_can_add_sep
    hbx_admin_can_lock_unlock
    hbx_admin_can_add_pdc
    hbx_admin_can_view_username_and_email
    hbx_admin_can_reset_password
    hbx_admin_can_change_fein
    hbx_admin_can_force_publish
    hbx_admin_can_send_secure_message
    hbx_admin_can_modify_plan_year
    hbx_admin_can_extend_open_enrollment
    hbx_admin_can_create_benefit_application
    hbx_admin_can_view_application_types
    hbx_admin_can_access_new_consumer_application_sub_tab
    hbx_admin_can_access_identity_verification_sub_tab
    hbx_admin_can_access_outstanding_verification_sub_tab
    hbx_admin_can_access_accept_reject_identity_documents
    hbx_admin_can_access_accept_reject_paper_application_documents
    hbx_admin_can_transition_family_members
    hbx_admin_can_delete_identity_application_documents
    hbx_admin_can_access_pay_now
    hbx_admin_can_access_age_off_excluded
    hbx_admin_can_manage_qles
    hbx_admin_can_change_username_and_email
    hbx_admin_can_view_notice_templates
    hbx_admin_can_edit_notice_templates
    hbx_admin_can_view_agency_staff
  end

  def build_test_roles
    User.where(email: /themanda.*dc.gov/).delete_all
    Person.where(last_name: /^amanda\d+$/).delete_all
    a = 10_000_000
    user1 = User.create(email: 'themanda.staff@dc.gov', password: 'P@55word1234', password_confirmation: 'P@55word1234', oim_id: "ex#{rand(5_999_999) + a}")
    user2 = User.create(email: 'themanda.readonly@dc.gov', password: 'P@55word1234', password_confirmation: 'P@55word1234',  oim_id: "ex#{rand(5_999_999) + a}")
    user3 = User.create(email: 'themanda.csr_supervisor@dc.gov', password: 'P@55word1234', password_confirmation: 'P@55word1234', oim_id: "ex#{rand(5_999_999) + a}")
    user4 = User.create(email: 'themanda.csr_tier1@dc.gov', password: 'P@55word1234', password_confirmation: 'P@55word1234',  oim_id: "ex#{rand(5_999_999) + a}")
    user5 = User.create(email: 'themanda.csr_tier2@dc.gov', password: 'P@55word1234', password_confirmation: 'P@55word1234', oim_id: "ex#{rand(5_999_999) + a}")
    user6 = User.create(email: 'developer@dc.gov', password: 'P@55word1234', password_confirmation: 'P@55word1234', oim_id: "ex#{rand(5_999_999) + a}")
    user7 = User.create(email: 'themanda.csr_tier3@dc.gov', password: 'P@55word1234', password_confirmation: 'P@55word1234', oim_id: "ex#{rand(5_999_999) + a}")
    user8 = User.create(email: 'themanda.super_admin@dc.gov', password: 'P@55word1234', password_confirmation: 'P@55word1234', oim_id: "ex#{rand(5_999_999) + a}")
    state_abbreviation = EnrollRegistry[:enroll_app].setting(:state_abbreviation).item
    hbx_profile_id = HbxProfile.all.detect { |profile| profile&.us_state_abbreviation == state_abbreviation }&.id&.to_s || HbxProfile.all&.last&.id&.to_s
    build_test_person_hbxstaff_set1(user1, user2, user3, user4, hbx_profile_id)
    build_test_person_hbxstaff_set2(user5, user6, user7, user8, hbx_profile_id)
  end

  def build_test_person_hbxstaff_set1(user1, user2, user3, user4, hbx_profile_id)
    p1 = Person.create(first_name: 'staff', last_name: "amanda#{rand(1_000_000)}", user: user1)
    p2 = Person.create(first_name: 'read_only', last_name: "amanda#{rand(1_000_000)}", user: user2)
    p3 = Person.create(first_name: 'supervisor', last_name: "amanda#{rand(1_000_000)}", user: user3)
    p4 = Person.create(first_name: 'tier1', last_name: "amanda#{rand(1_000_000)}", user: user4)
    return if hbx_profile_id.nil?
    HbxStaffRole.create!(person: p1, permission_id: Permission.hbx_staff.id, subrole: 'hbx_staff', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!(person: p2, permission_id: Permission.hbx_read_only.id, subrole: 'hbx_read_only', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!(person: p3, permission_id: Permission.hbx_csr_supervisor.id, subrole: 'hbx_csr_supervisor', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!(person: p4, permission_id: Permission.hbx_csr_tier1.id, subrole: 'hbx_csr_tier1', hbx_profile_id: hbx_profile_id)
  end

  def build_test_person_hbxstaff_set2(user5, user6, user7, user8, hbx_profile_id)
    p5 = Person.create(first_name: 'tier2', last_name: "amanda#{rand(1_000_000)}", user: user5)
    p6 = Person.create(first_name: 'developer', last_name: "developer#{rand(1_000_000)}", user: user6)
    p7 = Person.create(first_name: 'tier3', last_name: "amanda#{rand(1_000_000)}", user: user7)
    p8 = Person.create(first_name: 'super_admin', last_name: "amanda#{rand(1_000_000)}", user: user8)
    return puts("No HBX profile loaded into the database. Test users have been created, but please manually create an HBX Profile for them.") if hbx_profile_id.nil?
    puts "Creating HBX staff roles for test users." unless Rails.env.test?
    HbxStaffRole.create!(person: p5, permission_id: Permission.hbx_csr_tier2.id, subrole: 'hbx_csr_tier2', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!(person: p6, permission_id: Permission.developer.id, subrole: 'developer', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!(person: p7, permission_id: Permission.hbx_tier3.id, subrole: 'hbx_tier3', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!(person: p8, permission_id: Permission.super_admin.id, subrole: 'super_admin', hbx_profile_id: hbx_profile_id)
  end

  def hbx_admin_can_update_ssn
    Permission.hbx_staff.update_attributes!(can_update_ssn: true)
    Permission.super_admin.update_attributes!(can_update_ssn: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_update_ssn: can_update_ssn)
    Permission.hbx_csr_tier2.update_attributes!(can_update_ssn: can_update_ssn)
    Permission.hbx_csr_tier1.update_attributes!(can_update_ssn: can_update_ssn)
    Permission.hbx_tier3.update_attributes!(can_update_ssn: true)
  end

  def hbx_admin_can_access_user_account_tab
    Permission.hbx_staff.update_attributes!(can_access_user_account_tab: true)
    Permission.super_admin.update_attributes!(can_access_user_account_tab: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_access_user_account_tab: true)
    Permission.hbx_csr_tier2.update_attributes!(can_access_user_account_tab: true)
    Permission.hbx_csr_tier1.update_attributes!(can_access_user_account_tab: true)
    Permission.hbx_tier3.update_attributes!(can_access_user_account_tab: true)
    Permission.developer.update_attributes!(can_access_user_account_tab: true)
    Permission.hbx_read_only.update_attributes!(can_access_user_account_tab: true)
  end

  def hbx_admin_can_access_age_off_excluded
    Permission.hbx_staff.update_attributes!(can_access_age_off_excluded: true)
    Permission.super_admin.update_attributes!(can_access_age_off_excluded: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_access_age_off_excluded: true)
    Permission.hbx_csr_tier2.update_attributes!(can_access_age_off_excluded: true)
    Permission.hbx_csr_tier1.update_attributes!(can_access_age_off_excluded: true)
    Permission.hbx_tier3.update_attributes!(can_access_age_off_excluded: true)
  end

  def hbx_admin_can_view_login_history
    Permission.hbx_staff.update_attributes!(view_login_history: false)
    Permission.super_admin.update_attributes!(view_login_history: true)
    Permission.hbx_csr_supervisor.update_attributes!(view_login_history: false)
    Permission.hbx_csr_tier2.update_attributes!(view_login_history: false)
    Permission.hbx_csr_tier1.update_attributes!(view_login_history: false)
    Permission.hbx_tier3.update_attributes!(view_login_history: false)
  end

  def hbx_admin_csr_view_personal_info_page
    Permission.hbx_staff.update_attributes!(view_personal_info_page: true)
    Permission.super_admin.update_attributes!(view_personal_info_page: true)
    Permission.hbx_csr_supervisor.update_attributes!(view_personal_info_page: true)
    Permission.hbx_csr_tier2.update_attributes!(view_personal_info_page: true)
    Permission.hbx_csr_tier1.update_attributes!(view_personal_info_page: true)
    Permission.hbx_tier3.update_attributes!(view_personal_info_page: true)
  end

  def hbx_admin_can_complete_resident_application
    Permission.hbx_staff.update_attributes!(can_complete_resident_application: true)
    Permission.super_admin.update_attributes!(can_complete_resident_application: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_complete_resident_application: true)
    Permission.hbx_csr_tier2.update_attributes!(can_complete_resident_application: true)
    Permission.hbx_csr_tier1.update_attributes!(can_complete_resident_application: true)
    Permission.hbx_tier3.update_attributes!(can_complete_resident_application: true)
  end

  def hbx_admin_can_add_sep
    Permission.hbx_staff.update_attributes!(can_add_sep: true)
    Permission.super_admin.update_attributes!(can_add_sep: true)
    Permission.hbx_csr_tier2.update_attributes!(can_add_sep: can_add_sep)
    Permission.hbx_csr_supervisor.update_attributes!(can_add_sep: can_add_sep)
    Permission.hbx_tier3.update_attributes!(can_add_sep: true)
    Permission.hbx_csr_tier1.update_attributes!(can_add_sep: can_add_sep)
  end

  def hbx_admin_can_lock_unlock
    Permission.hbx_staff.update_attributes(can_lock_unlock: false)
    Permission.super_admin.update_attributes(can_lock_unlock: true)
    Permission.hbx_csr_supervisor.update_attributes(can_lock_unlock: false)
    Permission.hbx_csr_tier2.update_attributes(can_lock_unlock: false)
    Permission.hbx_csr_tier1.update_attributes(can_lock_unlock: false)
    Permission.hbx_tier3.update_attributes(can_lock_unlock: false)
  end

  def hbx_admin_can_add_pdc
    Permission.hbx_staff.update_attributes!(can_add_pdc: true)
    Permission.super_admin.update_attributes!(can_add_pdc: true)
    Permission.hbx_tier3.update_attributes!(can_add_pdc: true)
  end

  def hbx_admin_can_view_username_and_email
    Permission.hbx_staff.update_attributes!(can_view_username_and_email: true)
    Permission.super_admin.update_attributes!(can_view_username_and_email: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_view_username_and_email: true)
    Permission.hbx_csr_tier1.update_attributes!(can_view_username_and_email: true)
    Permission.hbx_csr_tier2.update_attributes!(can_view_username_and_email: true)
    Permission.hbx_tier3.update_attributes!(can_view_username_and_email: true)
    Permission.hbx_read_only.update_attributes!(can_view_username_and_email: true)
  end

  def hbx_admin_can_reset_password
    Permission.hbx_staff.update_attributes(can_reset_password: false)
    Permission.super_admin.update_attributes(can_reset_password: true)
    Permission.hbx_csr_supervisor.update_attributes(can_reset_password: false)
    Permission.hbx_csr_tier2.update_attributes(can_reset_password: false)
    Permission.hbx_csr_tier1.update_attributes(can_reset_password: false)
    Permission.hbx_tier3.update_attributes(can_reset_password: false)
  end

  def hbx_admin_can_change_fein
    Permission.super_admin.update_attributes(can_change_fein: true)
    Permission.hbx_staff.update_attributes(can_change_fein: true)
    Permission.hbx_tier3.update_attributes(can_change_fein: true)
  end

  def hbx_admin_can_force_publish
    Permission.super_admin.update_attributes(can_force_publish: true)
    Permission.hbx_staff.update_attributes(can_force_publish: true)
    Permission.hbx_tier3.update_attributes(can_force_publish: true)
  end

  def hbx_admin_can_send_secure_message
    Permission.super_admin.update_attributes(can_send_secure_message: true)
    Permission.hbx_staff.update_attributes(can_send_secure_message: true)
    Permission.hbx_csr_supervisor.update_attributes(can_send_secure_message: false)
    Permission.hbx_csr_tier2.update_attributes(can_send_secure_message: false)
    Permission.hbx_tier3.update_attributes(can_send_secure_message: true)
  end

  def hbx_admin_can_modify_plan_year
    Permission.super_admin.update_attributes(can_modify_plan_year: true)
    Permission.hbx_staff.update_attributes(can_modify_plan_year: true)
    Permission.hbx_tier3.update_attributes(can_modify_plan_year: true)
  end

  def hbx_admin_can_extend_open_enrollment
    Permission.super_admin.update_attributes!(can_extend_open_enrollment: true)
    Permission.hbx_tier3.update_attributes(can_extend_open_enrollment: true)
  end

  def hbx_admin_can_create_benefit_application
    Permission.super_admin.update_attributes(can_create_benefit_application: true)
    Permission.hbx_staff.update_attributes(can_create_benefit_application: true)
    Permission.hbx_tier3.update_attributes(can_create_benefit_application: true)
  end

  def hbx_admin_can_manage_qles
    Permission.super_admin.update_attributes(can_manage_qles: true)
    Permission.hbx_staff.update_attributes(can_manage_qles: true)
    Permission.hbx_tier3.update_attributes(can_manage_qles: true)
  end

  def grant_super_admin_access
    raise "User Email Argument expected!!" if ENV['user_email'].blank?
    user_emails = ENV['user_email'].split(',')
    hbx_organization = BenefitSponsors::Organizations::Organization.hbx_profiles.first
    users = User.where(:email.in => user_emails)
    users.each do |user|
      HbxStaffRole.create!(person: user.person, permission_id: Permission.super_admin.id, subrole: 'super_admin', hbx_profile_id: HbxProfile.current_hbx.id, benefit_sponsor_hbx_profile_id: hbx_organization.hbx_profile.id)
    end
  end

  def hbx_admin_can_view_application_types
    Permission.hbx_staff.update_attributes!(can_view_application_types: true)
    Permission.super_admin.update_attributes!(can_view_application_types: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_view_application_types: true)
    Permission.hbx_csr_tier1.update_attributes!(can_view_application_types: true)
    Permission.hbx_csr_tier2.update_attributes!(can_view_application_types: true)
    Permission.hbx_tier3.update_attributes!(can_view_application_types: true)
  end

  def hbx_admin_can_access_new_consumer_application_sub_tab
    Permission.hbx_staff.update_attributes!(can_access_new_consumer_application_sub_tab: true)
    Permission.super_admin.update_attributes!(can_access_new_consumer_application_sub_tab: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_access_new_consumer_application_sub_tab: true)
    Permission.hbx_csr_tier1.update_attributes!(can_access_new_consumer_application_sub_tab: true)
    Permission.hbx_csr_tier2.update_attributes!(can_access_new_consumer_application_sub_tab: true)
    Permission.hbx_tier3.update_attributes!(can_access_new_consumer_application_sub_tab: true)
  end

  def hbx_admin_can_access_identity_verification_sub_tab
    Permission.hbx_staff.update_attributes!(can_access_identity_verification_sub_tab: true)
    Permission.super_admin.update_attributes!(can_access_identity_verification_sub_tab: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_access_identity_verification_sub_tab: true)
    Permission.hbx_csr_tier2.update_attributes!(can_access_identity_verification_sub_tab: true)
    Permission.hbx_tier3.update_attributes!(can_access_identity_verification_sub_tab: true)
  end

  def hbx_admin_can_access_outstanding_verification_sub_tab
    Permission.hbx_staff.update_attributes!(can_access_outstanding_verification_sub_tab: true)
    Permission.super_admin.update_attributes!(can_access_outstanding_verification_sub_tab: true)
    Permission.hbx_csr_tier2.update_attributes!(can_access_outstanding_verification_sub_tab: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_access_outstanding_verification_sub_tab: true)
    Permission.hbx_tier3.update_attributes!(can_access_outstanding_verification_sub_tab: true)
  end

  def hbx_admin_can_access_accept_reject_identity_documents
    Permission.hbx_staff.update_attributes!(can_access_accept_reject_identity_documents: true)
    Permission.super_admin.update_attributes!(can_access_accept_reject_identity_documents: true)
    Permission.hbx_csr_tier2.update_attributes!(can_access_accept_reject_identity_documents: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_access_accept_reject_identity_documents: true)
    Permission.hbx_tier3.update_attributes!(can_access_accept_reject_identity_documents: true)
  end

  def hbx_admin_can_access_accept_reject_paper_application_documents
    Permission.hbx_staff.update_attributes!(can_access_accept_reject_paper_application_documents: true)
    Permission.super_admin.update_attributes!(can_access_accept_reject_paper_application_documents: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_access_accept_reject_paper_application_documents: true)
    Permission.hbx_csr_tier2.update_attributes!(can_access_accept_reject_paper_application_documents: true)
    Permission.hbx_tier3.update_attributes!(can_access_accept_reject_paper_application_documents: true)
  end

  def hbx_admin_can_transition_family_members
    Permission.hbx_staff.update_attributes!(can_transition_family_members: true)
    Permission.super_admin.update_attributes!(can_transition_family_members: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_transition_family_members: true)
    Permission.hbx_csr_tier2.update_attributes!(can_transition_family_members: true)
    Permission.hbx_csr_tier1.update_attributes!(can_transition_family_members: true)
    Permission.hbx_tier3.update_attributes!(can_transition_family_members: true)
  end

  def hbx_admin_can_delete_identity_application_documents
    Permission.hbx_staff.update_attributes!(can_delete_identity_application_documents: true)
    Permission.super_admin.update_attributes!(can_delete_identity_application_documents: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_delete_identity_application_documents: true)
    Permission.hbx_csr_tier2.update_attributes!(can_delete_identity_application_documents: true)
    Permission.hbx_tier3.update_attributes!(can_delete_identity_application_documents: true)
  end

  def hbx_admin_can_access_pay_now
    Permission.hbx_staff.update_attributes!(can_access_pay_now: true)
    Permission.super_admin.update_attributes!(can_access_pay_now: true)
    Permission.hbx_tier3.update_attributes!(can_access_pay_now: true)
  end

  def hbx_admin_can_change_username_and_email
    Permission.hbx_staff.update_attributes!(can_change_username_and_email: false)
    Permission.super_admin.update_attributes!(can_change_username_and_email: true)
    Permission.hbx_tier3.update_attributes!(can_change_username_and_email: false)
    Permission.hbx_csr_supervisor.update_attributes!(can_change_username_and_email: false)
    Permission.hbx_csr_tier1.update_attributes!(can_change_username_and_email: false)
    Permission.hbx_csr_tier2.update_attributes!(can_change_username_and_email: false)
  end

  def hbx_admin_can_view_notice_templates
    Permission.super_admin.update_attributes!(can_view_notice_templates: true)
    Permission.hbx_staff.update_attributes!(can_view_notice_templates: true)
    Permission.hbx_tier3.update_attributes!(can_view_notice_templates: true)
  end

  def hbx_admin_can_edit_notice_templates
    Permission.super_admin.update_attributes!(can_edit_notice_templates: true)
    Permission.hbx_staff.update_attributes!(can_edit_notice_templates: true)
    Permission.hbx_tier3.update_attributes!(can_edit_notice_templates: true)
  end

  def hbx_admin_can_view_agency_staff
    Permission.hbx_csr_tier1.update_attributes!(view_agency_staff: true)
    Permission.hbx_csr_tier2.update_attributes!(view_agency_staff: true)
    Permission.hbx_csr_supervisor.update_attributes!(view_agency_staff: true)
    Permission.developer.update_attributes!(view_agency_staff: true)
    Permission.hbx_read_only.update_attributes!(view_agency_staff: true)
  end
end
# rubocop:enable Metrics/ClassLength
