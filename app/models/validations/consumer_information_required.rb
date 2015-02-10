module Validations
  module ConsumerInformationRequired
    def self.included(klass)
      klass.class_eval do
        include Validations::ConsumerInformation
        validates_presence_of :ssn, :dob, :gender
      end
    end
  end
end
