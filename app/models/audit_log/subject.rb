# frozen_string_literal: true

module AuditLog
    # A data model for tracking changes to auditable models.
    module Subject
      extend ActiveSupport::Concern
  
      included do
        has_many :audit_logs, class_name: "::AuditLog::Entry", inverse_of: :auditable, as: :auditable
      end
    end
  end
  