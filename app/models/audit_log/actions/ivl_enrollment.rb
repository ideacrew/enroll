module AuditLog
    module Actions
      #THIS IS AN EXAMPLE ; I DONT HAVE REQUERIMENTS FOR THIS YET
      class IvlEnrollment < AuditLog::Entry
        include AuditLog::Actions::Container
          def initialize
              super
              self.action_name = "ilv_enrollment"
              #example of allowing a sub action (first two doesnt exists yet)
            #   add_allowed_class_type(AuditLog::Actions::Ridp)
            #   add_allowed_class_type(AuditLog::Actions::Vlp)
              add_allowed_class_type(AuditLog::Actions::H4ccElegibility)
          end
      end
    end
  end