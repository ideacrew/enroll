class Permission
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps

  PERMISSION_KINDS = ["hbx_staff", "hbx_read_only", "hbx_csr_supervisor", "hbx_csr_tier1", "hbx_csr_tier2", "hbx_tier3", "developer", "super_admin"].freeze

  field :name, type: String

  field :modify_family, type: Boolean, default: false
  field :modify_employer, type: Boolean, default: false
  field :revert_application, type: Boolean, default: false
  field :list_enrollments, type: Boolean, default: false
  field :send_broker_agency_message, type: Boolean, default: false
  field :approve_broker, type: Boolean, default: false
  field :approve_ga, type: Boolean, default: false
  field :modify_admin_tabs, type: Boolean, default: false
  field :view_admin_tabs, type: Boolean, default: false
  field :can_update_ssn, type: Boolean, default: false
  field :can_complete_resident_application, type: Boolean, default: false
  field :can_add_sep, default: false
  field :can_view_username_and_email, type: Boolean, default: false
  field :can_extend_open_enrollment, type: Boolean, default: false
  field :can_create_benefit_application, type: Boolean, default: false
  field :can_change_fein, type: Boolean, default: false
  field :can_force_publish, type: Boolean, default: false
  field :can_edit_aptc, type: Boolean, default: false
  field :can_view_sep_history, type: Boolean, default: false
  field :can_reinstate_enrollment, type: Boolean, default: false
  field :can_cancel_enrollment, type: Boolean, default: false
  field :can_terminate_enrollment, type: Boolean, default: false
  field :change_enrollment_end_date, type: Boolean, default: false
  field :can_change_username_and_email, type: Boolean, default: false
  field :can_drop_enrollment_members, type: Boolean, default: false
  field :can_edit_osse_eligibility, type: Boolean, default: false
  field :can_edit_broker_agency_profile, type: Boolean, default: false

  class << self
    def hbx_staff
      Permission.where(name: 'hbx_staff').first
    end

    def super_admin
      Permission.where(name: 'super_admin').first
    end

    def hbx_csr_tier1
      Permission.where(name: 'hbx_csr_tier1').first
    end

    def hbx_read_only
      Permission.where(name: 'hbx_read_only').first
    end
  end
end
