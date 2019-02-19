# Rake task used to upload notices to employee accounts
# To run rake task: RAILS_ENV=production bundle exec rake migrations:upload_notice_to_employee_account hbx_id="7654321" notice_name="Special Enrollment Denial Notice" file_path="lib/special_enrollment_denial_notice.pdf"
require File.join(Rails.root, "app", "data_migrations", "upload_notice_to_employee_account")

namespace :migrations do
  desc "Uploading notices to employee account"
  UploadNoticeToEmployeeAccount.define_task :upload_notice_to_employee_account => :environment
end
