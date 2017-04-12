module IvlHelper
	delegate :individual_market_is_enabled?, to: :class
	
	def self.individual_market_is_enabled?
		Settings.aca.market_kinds.include?("individual")
	end
end
