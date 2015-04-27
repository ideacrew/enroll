module Forms
  module SsnField
    def self.included(base)
      base.class_eval do
        attr_reader :ssn

        def ssn=(new_ssn)
          if !new_ssn.blank?
            @ssn = new_ssn.to_s.gsub(/\D/, '')
          end
        end
      end
    end
  end
end
