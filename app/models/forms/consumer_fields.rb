module Forms
  module ConsumerFields
    def self.included(base)
      base.class_eval do
        attr_accessor :race, :ethnicity, :language_code
        attr_accessor :is_incarcerated, :is_disabled, :is_tobacco_user
      end
    end
  end
end
