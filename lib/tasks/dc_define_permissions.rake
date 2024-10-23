require File.join(Rails.root, "app", "data_migrations", "permissions", "dc_define_permissions")

#All hbx_roles can view families, employers, broker_agencies, brokers and general agencies
#The convention for a privilege group 'x' is  'modify_x', or view 'view_x'
#These rakes applies for both sites DC & MA as permissions applies for both sites

namespace :dc_permissions do
  desc 'define the permissions'
  DcDefinePermissions.define_task :initial_hbx => :environment
end

namespace :dc_permissions do
  desc 'build test roles'
  DcDefinePermissions.define_task :build_test_roles => :environment
end

namespace :dc_permissions do
  desc 'hbx admin can update ssn'
  DcDefinePermissions.define_task :hbx_admin_can_update_ssn => :environment
end

namespace :dc_permissions do
  desc 'hbx admin can complete resident application'
  DcDefinePermissions.define_task :hbx_admin_can_complete_resident_application => :environment

  desc 'hbx admin can lock and unlock a user'
  DcDefinePermissions.define_task :hbx_admin_can_lock_unlock => :environment

  desc 'hbx admin can reset password a user'
  DcDefinePermissions.define_task :hbx_admin_can_reset_password => :environment
end

namespace :dc_permissions do
  desc 'hbx admin can add sep'
  DcDefinePermissions.define_task :hbx_admin_can_add_sep => :environment
end

namespace :dc_permissions do
  desc 'hbx admin can add pdc'
  DcDefinePermissions.define_task :hbx_admin_can_add_pdc => :environment
end

namespace :dc_permissions do
  desc 'hbx admin can view username and email'
  DcDefinePermissions.define_task :hbx_admin_can_view_username_and_email => :environment
end

namespace :dc_permissions do
  desc 'hbx admin can view login history'
  DcDefinePermissions.define_task :hbx_admin_can_view_login_history => :environment
end

namespace :dc_permissions do
  desc 'hbx admin can send secure message'
  DcDefinePermissions.define_task :hbx_admin_can_access_age_off_excluded => :environment
end

#RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_change_fein
namespace :dc_permissions do
  desc 'hbx system admin can change fein'
  DcDefinePermissions.define_task :hbx_admin_can_change_fein => :environment
end

# RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_force_publish
namespace :dc_permissions do
  desc 'hbx admin can force publish'
  DcDefinePermissions.define_task :hbx_admin_can_force_publish => :environment
end

namespace :dc_permissions do
  desc 'hbx admin can send secure message'
  DcDefinePermissions.define_task :hbx_admin_can_send_secure_message => :environment
end

# RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_extend_open_enrollment
namespace :dc_permissions do
  desc 'hbx admin can extend open enrollment'
  DcDefinePermissions.define_task :hbx_admin_can_extend_open_enrollment => :environment
end

# RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_modify_plan_year
namespace :dc_permissions do
  desc 'hbx admin can update plan years'
  DcDefinePermissions.define_task :hbx_admin_can_modify_plan_year => :environment
end

# RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_create_benefit_application
namespace :dc_permissions do
  desc 'hbx admin can create benefit application'
  DcDefinePermissions.define_task :hbx_admin_can_create_benefit_application => :environment
end

# RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_manage_qles
namespace :dc_permissions do
  desc 'hbx admin can manage SEP types create, update & updation of ordinal position'
  DcDefinePermissions.define_task :hbx_admin_can_manage_qles => :environment
end

# RAILS_ENV=production bundle exec rake permissions:grant_super_admin_access user_email="<email address1>,<email address2>"
namespace :dc_permissions do
  desc 'grant super admin access for given users'
  DcDefinePermissions.define_task :grant_super_admin_access => :environment
end

# RAILS_ENV=production bundle exec rake permissions:grant_hbx_tier3_access user_email="<email address1>,<email address2>"
namespace :dc_permissions do
  desc 'grant hbx tier3 access for given users'
  DcDefinePermissions.define_task :grant_hbx_tier3_access => :environment
end

namespace :dc_permissions do
  desc 'hbx admin can view application types of consumer'
  DcDefinePermissions.define_task :hbx_admin_can_view_application_types => :environment
end

namespace :dc_permissions do
  desc 'hbx admin and csr view personal information page of consumer'
  DcDefinePermissions.define_task :hbx_admin_csr_view_personal_info_page => :environment
end

namespace :dc_permissions do
  desc 'hbx admin can view new consumer application link tab'
  DcDefinePermissions.define_task :hbx_admin_access_new_consumer_application_sub_tab => :environment
end

namespace :dc_permissions do
  desc 'hbx admin and csr view new consumer application link tab'
  DcDefinePermissions.define_task :hbx_admin_can_access_new_consumer_application_sub_tab => :environment
end

namespace :dc_permissions do
  desc 'hbx admin and csr view identity verification link tab'
  DcDefinePermissions.define_task :hbx_admin_can_access_identity_verification_sub_tab => :environment
end

namespace :dc_permissions do
  desc 'hbx admin can view outstanding verification link tab'
  DcDefinePermissions.define_task :hbx_admin_can_access_outstanding_verification_sub_tab => :environment
end

namespace :dc_permissions do
  desc 'hbx admin can access accept reject identity documents'
  DcDefinePermissions.define_task :hbx_admin_can_access_accept_reject_identity_documents => :environment
end

namespace :dc_permissions do
  desc 'hbx admin and all csr access accept reject paper application documents'
  DcDefinePermissions.define_task :hbx_admin_can_access_accept_reject_paper_application_documents => :environment
end

namespace :dc_permissions do
  desc 'hbx admin can delete identity and paper application documents'
  DcDefinePermissions.define_task :hbx_admin_can_delete_identity_application_documents => :environment
end

namespace :dc_permissions do
  desc 'hbx admin can transition family members'
  DcDefinePermissions.define_task :hbx_admin_can_transition_family_members => :environment
end

namespace :dc_permissions do
  desc 'hbx admin can access user account tab'
  DcDefinePermissions.define_task :hbx_admin_can_access_user_account_tab => :environment
end

namespace :dc_permissions do
  desc 'hbx_admin_can_access_pay_now'
  DcDefinePermissions.define_task :hbx_admin_can_access_pay_now => :environment
end

# RAILS_ENV=production bundle exec rake dc_permissions:assign_current_permissions
namespace :dc_permissions do
  desc 'assign the most current permissions'
  DcDefinePermissions.define_task :assign_current_permissions => :environment
end

# RAILS_ENV=production bundle exec rake dc_permissions:hbx_admin_can_change_username_and_email
namespace :dc_permissions do
  desc 'assign the most current permissions'
  DcDefinePermissions.define_task :hbx_admin_can_change_username_and_email => :environment
end

namespace :dc_permissions do
  desc 'hbx admin can edit osse eligibility'
  DcDefinePermissions.define_task :hbx_admin_can_edit_osse_eligibility => :environment
end

namespace :dc_permissions do
  desc 'hbx admin can view audit log'
  DcDefinePermissions.define_task :hbx_admin_can_view_audit_log => :environment
end


#rake dc_permissions:hbx_admin_can_reset_password

#rake dc_permissions:hbx_admin_access_new_consumer_application_sub_tab
#rake dc_permissions:hbx_admin_access_identity_verification_sub_tab
#rake dc_permissions:hbx_admin_access_outstanding_verification_sub_tab

#RAILS_ENV=production bundle exec rake dc_permissions:initial_hbx
#RAILS_ENV=production bundle exec rake dc_permissions:migrate_hbx
#RAILS_ENV=production bundle exec rake dc_permissions:hbx_admin_can_update_ssn
#RAILS_ENV=production bundle exec rake dc_permissions:hbx_admin_can_complete_resident_application

#RAILS_ENV=production bundle exec rake dc_permissions:hbx_admin_can_view_application_types
#RAILS_ENV=production bundle exec rake dc_permissions:hbx_admin_csr_view_personal_info_page
#RAILS_ENV=production bundle exec rake dc_permissions:hbx_admin_can_access_new_consumer_application_sub_tab
#RAILS_ENV=production bundle exec rake dc_permissions:hbx_admin_can_access_identity_verification_sub_tab
#RAILS_ENV=production bundle exec rake dc_permissions:hbx_admin_can_access_outstanding_verification_sub_tab
#RAILS_ENV=production bundle exec rake dc_permissions:hbx_admin_can_access_accept_reject_identity_documents
#RAILS_ENV=production bundle exec rake dc_permissions:hbx_admin_can_access_accept_reject_paper_application_documents
#RAILS_ENV=production bundle exec rake dc_permissions:hbx_admin_can_delete_identity_application_documents
#RAILS_ENV=production bundle exec rake dc_permissions:hbx_admin_can_modify_plan_year
#RAILS_ENV=production bundle exec rake dc_permissions:hbx_admin_can_access_user_account_tab
#RAILS_ENV=production bundle exec rake dc_permissions:hbx_admin_can_transition_family_members
#RAILS_ENV=production bundle exec rake dc_permissions:hbx_admin_can_access_age_off_excluded
#RAILS_ENV=production bundle exec rake dc_permissions:hbx_admin_can_edit_osse_eligibility
#RAILS_ENV=production bundle exec rake dc_permissions:hbx_admin_can_view_audit_log

#rake dc_permissions:hbx_admin_can_add_pdc

#rake dc_permissions:initial_hbx
#rake dc_permissions:migrate_hbx
#rake dc_permissions:hbx_admin_can_update_ssn
#rake dc_permissions:hbx_admin_can_complete_resident_application
#rake dc_permissions:hbx_admin_can_access_pay_now

#bundle exec rake dc_permissions:hbx_admin_can_send_secure_message
