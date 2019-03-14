require File.join(Rails.root, "lib/migration_task")

class DefinePermissions < MigrationTask
#All hbx_roles can view families, employers, broker_agencies, brokers and general agencies
#The convention for a privilege group 'x' is  'modify_x', or view 'view_x'

  def initial_hbx
    Permission.where(name: /^hbx/).delete_all
  	Permission.create(name: 'hbx_staff', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
  	  send_broker_agency_message: true, approve_broker: true, approve_ga: true,
  	  modify_admin_tabs: true, view_admin_tabs: true, can_view_username_and_email:true, can_lock_unlock:true, can_reset_password:true)
    Permission.create(name: 'hbx_read_only', modify_family: true, list_enrollments: true, view_admin_tabs: true)
  	Permission.create(name: 'hbx_csr_supervisor', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true)
  	Permission.create(name: 'hbx_tier3', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
  	  send_broker_agency_message: true, approve_broker: true, approve_ga: true,
  	  modify_admin_tabs: true, view_admin_tabs: true, can_view_username_and_email:true, can_lock_unlock:true, can_reset_password:true, can_create_plan_year:true)
  	Permission.create(name: 'hbx_csr_tier2', modify_family: true, modify_employer: true)
    Permission.create(name: 'hbx_csr_tier1', modify_family: true)
    Permission.create(name: 'developer', list_enrollments: true, view_admin_tabs: true)
    Permission.create(name: 'super_admin', modify_family: true, modify_employer: true, revert_application: true, list_enrollments: true,
                      send_broker_agency_message: true, approve_broker: true, approve_ga: true,
                      modify_admin_tabs: true, view_admin_tabs: true, can_view_username_and_email:true, can_lock_unlock:true, can_reset_password:true, can_add_sep:true, can_create_plan_year:true)
  	permission = Permission.hbx_staff
    Person.where(hbx_staff_role: {:$exists => true}).all.each{|p|p.hbx_staff_role.update_attributes(permission_id: permission.id, subrole:'hbx_staff')}
  end

  def build_test_roles
    User.where(email: /themanda.*dc.gov/).delete_all
    Person.where(last_name: /^amanda\d+$/).delete_all
    a=10000000
    u1 = User.create( email: 'themanda.staff@dc.gov', password: 'P@55word', password_confirmation: 'P@55word', oim_id: "ex#{rand(5999999)+a}")
    u2 = User.create( email: 'themanda.readonly@dc.gov', password: 'P@55word', password_confirmation: 'P@55word',  oim_id: "ex#{rand(5999999)+a}")
    u3 = User.create( email: 'themanda.csr_supervisor@dc.gov', password: 'P@55word', password_confirmation: 'P@55word', oim_id: "ex#{rand(5999999)+a}")
    u4 = User.create( email: 'themanda.csr_tier1@dc.gov', password: 'P@55word', password_confirmation: 'P@55word',  oim_id: "ex#{rand(5999999)+a}")
    u5 = User.create( email: 'themanda.csr_tier2@dc.gov', password: 'P@55word', password_confirmation: 'P@55word', oim_id: "ex#{rand(5999999)+a}")
    u6 = User.create( email: 'developer@dc.gov', password: 'P@55word', password_confirmation: 'P@55word', oim_id: "ex#{rand(5999999)+a}")
    u7 = User.create( email: 'themanda.tier3@dc.gov', password: 'P@55word', password_confirmation: 'P@55word', oim_id: "ex#{rand(5999999)+a}")
    u8 = User.create( email: 'themanda.super_admin@dc.gov', password: 'P@55word', password_confirmation: 'P@55word', oim_id: "ex#{rand(5999999)+a}")
    org = Organization.new(legal_name:'Test Org 2050',fein:'123450986')
    hbx_profile = HbxProfile.all.first
    hbx_profile_id = hbx_profile.id
    p1 = Person.create( first_name: 'staff', last_name: "amanda#{rand(1000000)}", user: u1, dob: Date.new(1990,1,1))
    p2 = Person.create( first_name: 'read_only', last_name: "amanda#{rand(1000000)}", user: u2, dob: Date.new(1990,1,1))
    p3 = Person.create( first_name: 'supervisor', last_name: "amanda#{rand(1000000)}", user: u3, dob: Date.new(1990,1,1))
    p4 = Person.create( first_name: 'tier1', last_name: "amanda#{rand(1000000)}", user: u4, dob: Date.new(1990,1,1))
    p5 = Person.create( first_name: 'tier2', last_name: "amanda#{rand(1000000)}", user: u5, dob: Date.new(1990,1,1))
    p6 = Person.create( first_name: 'developer', last_name: "developer#{rand(1000000)}", user: u6, dob: Date.new(1990,1,1))
    p7 = Person.create( first_name: 'tier3', last_name: "amanda#{rand(1000000)}", user: u7, dob: Date.new(1990,1,1))
    p8 = Person.create( first_name: 'super_admin', last_name: "amanda#{rand(1000000)}", user: u8, dob: Date.new(1990,1,1))
    HbxStaffRole.create!( person: p1, permission_id: Permission.hbx_staff.id, subrole: 'hbx_staff', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!( person: p2, permission_id: Permission.hbx_read_only.id, subrole: 'hbx_read_only', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!(  person: p3, permission_id: Permission.hbx_csr_supervisor.id, subrole: 'hbx_csr_supervisor', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!( person: p4, permission_id: Permission.hbx_csr_tier1.id, subrole: 'hbx_csr_tier1', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!( person: p5, permission_id: Permission.hbx_csr_tier2.id, subrole: 'hbx_csr_tier2', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!( person: p6, permission_id: Permission.hbx_csr_tier2.id, subrole: 'developer', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!( person: p7, permission_id: Permission.hbx_tier3.id, subrole: 'hbx_tier3', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!(person:p8, permission_id: Permission.super_admin.id, subrole: 'super_admin', hbx_profile_id: hbx_profile_id)
  end

  def hbx_admin_can_update_ssn
    Permission.hbx_staff.update_attributes!(can_update_ssn: true)
  end

  def hbx_admin_csr_view_personal_info_page
    Permission.hbx_staff.update_attributes!(view_personal_info_page: true)
    Permission.hbx_csr_supervisor.update_attributes!(view_personal_info_page: true)
    Permission.hbx_csr_tier2.update_attributes!(view_personal_info_page: true)
    Permission.hbx_csr_tier1.update_attributes!(view_personal_info_page: true)
  end

  def hbx_admin_can_complete_resident_application
    Permission.hbx_staff.update_attributes!(can_complete_resident_application: true)
  end

  def hbx_admin_can_add_sep
    Permission.hbx_staff.update_attributes!(can_add_sep: true)
  end

  def hbx_admin_can_add_pdc
    Permission.hbx_staff.update_attributes!(can_add_pdc: true)
  end

  def hbx_admin_can_view_username_and_email
    Permission.hbx_staff.update_attributes!(can_view_username_and_email: true)
    Permission.hbx_read_only.update_attributes!(can_view_username_and_email: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_view_username_and_email: true)
    Permission.hbx_csr_tier1.update_attributes!(can_view_username_and_email: true)
    Permission.hbx_csr_tier2.update_attributes!(can_view_username_and_email: true)
  end

  def hbx_admin_can_view_application_types
    Permission.hbx_staff.update_attributes!(can_view_application_types: true)
  end

  def hbx_admin_can_access_new_consumer_application_sub_tab
    Permission.hbx_staff.update_attributes!(can_access_new_consumer_application_sub_tab: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_access_new_consumer_application_sub_tab: true)
    Permission.hbx_csr_tier1.update_attributes!(can_access_new_consumer_application_sub_tab: true)
    Permission.hbx_csr_tier2.update_attributes!(can_access_new_consumer_application_sub_tab: true)
  end

  def hbx_admin_can_access_identity_verification_sub_tab
    Permission.hbx_staff.update_attributes!(can_access_identity_verification_sub_tab: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_access_identity_verification_sub_tab: true)
    Permission.hbx_csr_tier1.update_attributes!(can_access_identity_verification_sub_tab: true)
    Permission.hbx_csr_tier2.update_attributes!(can_access_identity_verification_sub_tab: true)
  end

  def hbx_admin_can_access_outstanding_verification_sub_tab
    Permission.hbx_staff.update_attributes!(can_access_outstanding_verification_sub_tab: true)
  end

  def hbx_admin_can_access_accept_reject_identity_documents
    Permission.hbx_staff.update_attributes!(can_access_accept_reject_identity_documents: true)
  end

  def hbx_admin_can_access_accept_reject_paper_application_documents
    Permission.hbx_staff.update_attributes!(can_access_accept_reject_paper_application_documents: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_access_accept_reject_paper_application_documents: true)
    Permission.hbx_csr_tier1.update_attributes!(can_access_accept_reject_paper_application_documents: true)
    Permission.hbx_csr_tier2.update_attributes!(can_access_accept_reject_paper_application_documents: true)
  end

  def hbx_admin_can_delete_identity_application_documents
    Permission.hbx_staff.update_attributes!(can_delete_identity_application_documents: true)
  end

  def hbx_admin_can_access_pay_now
    Permission.hbx_staff.update_attributes!(can_access_pay_now: true)
    Permission.hbx_csr_supervisor.update_attributes!(can_access_pay_now: true)
    Permission.hbx_csr_tier1.update_attributes!(can_access_pay_now: true)
    Permission.hbx_csr_tier2.update_attributes!(can_access_pay_now: true)
  end

  def hbx_admin_can_transition_family_members
   Permission.hbx_staff.update_attributes!(can_transition_family_members: true)
  end

  def hbx_admin_can_access_user_account_tab
    Permission.hbx_staff.update_attributes!(can_access_user_account_tab: true)
    Permission.hbx_tier3.update_attributes!(can_access_user_account_tab: true)
  end

  def hbx_admin_can_create_plan_year
   Permission.super_admin.update_attributes(can_create_plan_year: true)
   Permission.hbx_tier3.update_attributes(can_create_plan_year: true)
  end

  def grant_super_admin_access
    raise "User Email Argument expected!!"if ENV['user_email'].blank?

    user_emails = ENV['user_email'].split(',')
    hbx_profile = HbxProfile.all.first
    users = User.where(:email.in => user_emails)
    users.each do |user|
      HbxStaffRole.create!( person: user.person, permission_id: Permission.super_admin.id, subrole: 'super_admin', hbx_profile_id: hbx_profile.id)
    end
  end
end
