module Forms
  module FeinField
    def self.included(base)
      base.class_eval do
        attr_reader :fein

        def fein=(new_fein)
          if !new_fein.blank?
            @fein = new_fein.to_s.gsub(/\D/, '')
          end
        end
      end
    end
  end
end
