module AuditLog
  module Actions
    module Container
      mattr_accessor :allowed_class_types

      def add_allowed_class_type(klass)
        self.allowed_class_types << klass
      end

      def add_sub_action (action)
        if self.allowed_class_types.include?(action.class)
          self.sub_actions << action
        else
          errors.add(:sub_actions, "#{action.class} is not allowed for this action")
        end
      end

      def self.included(base)
        self.allowed_class_types = []
      end


    end
  end
end