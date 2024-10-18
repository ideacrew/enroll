require File.join(Rails.root, "app", "data_migrations", "permissions", "me_define_permissions")

#All hbx_roles can view families, employers, broker_agencies, brokers and general agencies
#The convention for a privilege group 'x' is  'modify_x', or view 'view_x'

namespace :me_permissions do
  desc 'define the permissions'
  MeDefinePermissions.define_task :initial_hbx => :environment
end

namespace :me_permissions do
  desc 'build test roles'
  MeDefinePermissions.define_task :build_test_roles => :environment
end

namespace :me_permissions do
  desc 'hbx admin can update ssn'
  MeDefinePermissions.define_task :hbx_admin_can_update_ssn => :environment
end

namespace :me_permissions do
  desc 'hbx admin can complete resident application'
  MeDefinePermissions.define_task :hbx_admin_can_complete_resident_application => :environment

  desc 'hbx admin can lock and unlock a user'
  MeDefinePermissions.define_task :hbx_admin_can_lock_unlock => :environment

  desc 'hbx admin can reset password a user'
  MeDefinePermissions.define_task :hbx_admin_can_reset_password => :environment
end

namespace :me_permissions do
  desc 'hbx admin can add sep'
  MeDefinePermissions.define_task :hbx_admin_can_add_sep => :environment
end

namespace :me_permissions do
  desc 'hbx admin can add pdc'
  MeDefinePermissions.define_task :hbx_admin_can_add_pdc => :environment
end

namespace :me_permissions do
  desc 'hbx admin can view username and email'
  MeDefinePermissions.define_task :hbx_admin_can_view_username_and_email => :environment
end

namespace :me_permissions do
  desc 'hbx admin can view login history'
  MeDefinePermissions.define_task :hbx_admin_can_view_login_history => :environment
end

namespace :me_permissions do
  desc 'hbx admin can send secure message'
  MeDefinePermissions.define_task :hbx_admin_can_access_age_off_excluded => :environment
end

#RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_change_fein
namespace :me_permissions do
  desc 'hbx system admin can change fein'
  MeDefinePermissions.define_task :hbx_admin_can_change_fein => :environment
end

# RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_force_publish
namespace :me_permissions do
  desc 'hbx admin can force publish'
  MeDefinePermissions.define_task :hbx_admin_can_force_publish => :environment
end

namespace :me_permissions do
  desc 'hbx admin can send secure message'
  MeDefinePermissions.define_task :hbx_admin_can_send_secure_message => :environment
end

# RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_extend_open_enrollment
namespace :me_permissions do
  desc 'hbx admin can extend open enrollment'
  MeDefinePermissions.define_task :hbx_admin_can_extend_open_enrollment => :environment
end

# RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_modify_plan_year
namespace :me_permissions do
  desc 'hbx admin can update plan years'
  MeDefinePermissions.define_task :hbx_admin_can_modify_plan_year => :environment
end

# RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_create_benefit_application
namespace :me_permissions do
  desc 'hbx admin can create benefit application'
  MeDefinePermissions.define_task :hbx_admin_can_create_benefit_application => :environment
end

# RAILS_ENV=production bundle exec rake permissions:hbx_admin_can_manage_qles
namespace :me_permissions do
  desc 'hbx admin can manage SEP types create, update & updation of ordinal position'
  MeDefinePermissions.define_task :hbx_admin_can_manage_qles => :environment
end

# RAILS_ENV=production bundle exec rake permissions:grant_super_admin_access user_email="<email address1>,<email address2>"
namespace :me_permissions do
  desc 'grant super admin access for given users'
  MeDefinePermissions.define_task :grant_super_admin_access => :environment
end

# RAILS_ENV=production bundle exec rake permissions:grant_hbx_tier3_access user_email="<email address1>,<email address2>"
namespace :me_permissions do
  desc 'grant hbx tier3 access for given users'
  MeDefinePermissions.define_task :grant_hbx_tier3_access => :environment
end

namespace :me_permissions do
  desc 'hbx admin can view application types of consumer'
  MeDefinePermissions.define_task :hbx_admin_can_view_application_types => :environment
end

namespace :me_permissions do
  desc 'hbx admin and csr view personal information page of consumer'
  MeDefinePermissions.define_task :hbx_admin_csr_view_personal_info_page => :environment
end

namespace :me_permissions do
  desc 'hbx admin can view new consumer application link tab'
  MeDefinePermissions.define_task :hbx_admin_access_new_consumer_application_sub_tab => :environment
end

namespace :me_permissions do
  desc 'hbx admin and csr view new consumer application link tab'
  MeDefinePermissions.define_task :hbx_admin_can_access_new_consumer_application_sub_tab => :environment
end

namespace :me_permissions do
  desc 'hbx admin and csr view identity verification link tab'
  MeDefinePermissions.define_task :hbx_admin_can_access_identity_verification_sub_tab => :environment
end

namespace :me_permissions do
  desc 'hbx admin can view outstanding verification link tab'
  MeDefinePermissions.define_task :hbx_admin_can_access_outstanding_verification_sub_tab => :environment
end

namespace :me_permissions do
  desc 'hbx admin can access accept reject identity documents'
  MeDefinePermissions.define_task :hbx_admin_can_access_accept_reject_identity_documents => :environment
end

namespace :me_permissions do
  desc 'hbx admin and all csr access accept reject paper application documents'
  MeDefinePermissions.define_task :hbx_admin_can_access_accept_reject_paper_application_documents => :environment
end

namespace :me_permissions do
  desc 'hbx admin can delete identity and paper application documents'
  MeDefinePermissions.define_task :hbx_admin_can_delete_identity_application_documents => :environment
end

namespace :me_permissions do
  desc 'hbx admin can transition family members'
  MeDefinePermissions.define_task :hbx_admin_can_transition_family_members => :environment
end

namespace :me_permissions do
  desc 'hbx admin can access user account tab'
  MeDefinePermissions.define_task :hbx_admin_can_access_user_account_tab => :environment
end

namespace :me_permissions do
  desc 'hbx_admin_can_access_pay_now'
  MeDefinePermissions.define_task :hbx_admin_can_access_pay_now => :environment
end

# RAILS_ENV=production bundle exec rake me_permissions:assign_current_permissions
namespace :me_permissions do
  desc 'assign the most current permissions'
  MeDefinePermissions.define_task :assign_current_permissions => :environment
end

# RAILS_ENV=production bundle exec rake me_permissions:hbx_admin_can_change_username_and_email
namespace :me_permissions do
  desc 'assign the most current permissions'
  MeDefinePermissions.define_task :hbx_admin_can_change_username_and_email => :environment
end

#rake me_permissions:hbx_admin_can_reset_password

#rake me_permissions:hbx_admin_access_new_consumer_application_sub_tab
#rake me_permissions:hbx_admin_access_identity_verification_sub_tab
#rake me_permissions:hbx_admin_access_outstanding_verification_sub_tab

#RAILS_ENV=production bundle exec rake me_permissions:initial_hbx
#RAILS_ENV=production bundle exec rake me_permissions:migrate_hbx
#RAILS_ENV=production bundle exec rake me_permissions:hbx_admin_can_update_ssn
#RAILS_ENV=production bundle exec rake me_permissions:hbx_admin_can_complete_resident_application

#RAILS_ENV=production bundle exec rake me_permissions:hbx_admin_can_view_application_types
#RAILS_ENV=production bundle exec rake me_permissions:hbx_admin_csr_view_personal_info_page
#RAILS_ENV=production bundle exec rake me_permissions:hbx_admin_can_access_new_consumer_application_sub_tab
#RAILS_ENV=production bundle exec rake me_permissions:hbx_admin_can_access_identity_verification_sub_tab
#RAILS_ENV=production bundle exec rake me_permissions:hbx_admin_can_access_outstanding_verification_sub_tab
#RAILS_ENV=production bundle exec rake me_permissions:hbx_admin_can_access_accept_reject_identity_documents
#RAILS_ENV=production bundle exec rake me_permissions:hbx_admin_can_access_accept_reject_paper_application_documents
#RAILS_ENV=production bundle exec rake me_permissions:hbx_admin_can_delete_identity_application_documents
#RAILS_ENV=production bundle exec rake me_permissions:hbx_admin_can_modify_plan_year
#RAILS_ENV=production bundle exec rake me_permissions:hbx_admin_can_access_user_account_tab
#RAILS_ENV=production bundle exec rake me_permissions:hbx_admin_can_transition_family_members
#RAILS_ENV=production bundle exec rake me_permissions:hbx_admin_can_access_age_off_excluded
#rake me_permissions:hbx_admin_can_add_pdc

#rake me_permissions:initial_hbx
#rake me_permissions:migrate_hbx
#rake me_permissions:hbx_admin_can_update_ssn
#rake me_permissions:hbx_admin_can_complete_resident_application
#rake me_permissions:hbx_admin_can_access_pay_now

#bundle exec rake me_permissions:hbx_admin_can_send_secure_message
