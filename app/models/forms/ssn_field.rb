module Forms
  module SsnField
    def self.included(base)
      base.class_eval do
        attr_reader :ssn, :no_ssn

        def ssn=(new_ssn)
          if !new_ssn.blank?
            @ssn = new_ssn.to_s.gsub(/\D/, '')
          end
        end

        def no_ssn=(no_ssn)
          @no_ssn = no_ssn
        end
      end
    end
  end
end
