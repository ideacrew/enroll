module BenefitMarkets
  class BenefitMarketsController < ApplicationController

  	before_filter :set_site_id, only: [:index]

  	def index
  		@benifit_markets = BenefitMarkets::BenefitMarket.where(site_id: @site_id)
  	end

  	private 

  	def set_site_id
        @site_id = params[:site_id]
  	end
  end
end
