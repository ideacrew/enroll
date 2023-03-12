# frozen_string_literal: true

module AuditLog
    # A data model for a unitary transaction
    module Subject
      extend ActiveSupport::Concern
  
      included do
        has_many :audit_logs, class_name: "::AuditLog::Entry", inverse_of: :auditable, as: :auditable
      end
    end
  end
  