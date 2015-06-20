module Forms
  module NpnField
    def self.included(base)
      base.class_eval do
        attr_reader :npn

        def npn=(new_npn)
          if !new_np.blank?
            @npn = new_npn.to_s.gsub(/\D/, '')
          end
        end
      end
    end
  end
end