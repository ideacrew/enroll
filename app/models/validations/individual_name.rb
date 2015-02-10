module Validations
  module IndividualName
    def self.included(klass)
      klass.class_eval do
        validates_presence_of :first_name
        validates_presence_of :last_name
      end
    end
  end
end
