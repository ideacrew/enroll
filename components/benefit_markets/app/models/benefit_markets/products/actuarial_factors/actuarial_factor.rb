module BenefitMarkets
	module Products
		module ActuarialFactors
			class ActuarialFactor
				include Mongoid::Document
				field :active_year, type: Integer
				field :default_factor_value, type: Float
				field :carrier_profile_id, type: BSON::ObjectId

				field :max_integer_factor_key, type: Integer

				embeds_many :actuarial_factor_entries, class_name: "::BenefitMarkets::Products::ActuarialFactors::ActuarialFactorEntry"

				validates_presence_of :carrier_profile_id, :allow_blank => false
				validates_numericality_of :default_factor_value, :allow_blank => false
				validates_numericality_of :active_year, :allow_blank => false

				def lookup(key)
					entry = actuarial_factor_entries.detect { |rfe| rfe.factor_key == key }
					entry.nil? ? default_factor_value : entry.factor_value
				end
			end
		end
	end
end
