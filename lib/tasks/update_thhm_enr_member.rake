# frozen_string_literal: true

# Rake task to update TaxHouseholdMembersEnrollmentMembers of TaxHouseholdEnrollment which have correct TaxHouseholdMemberId but invalid HbxEnrollmentMemberId
# To run rake task: RAILS_ENV=production bundle exec rake migrations:update_thhm_enr_member

# To run this for a specific set of HbxEnrollments
# To run rake task: RAILS_ENV=production bundle exec rake migrations:update_thhm_enr_member enrollment_hbx_ids='1234, 2345'

require File.join(Rails.root, 'app', 'data_migrations', 'update_thhm_enr_member')

namespace :migrations do
  desc 'Update TaxHouseholdMemberEnrollmentMember to fix HbxEnrollmentMemberId'
  UpdateThhmEnrMember.define_task :update_thhm_enr_member => :environment
end
