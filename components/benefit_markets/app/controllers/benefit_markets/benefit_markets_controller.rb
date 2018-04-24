module BenefitMarkets
  class BenefitMarketsController < ::BenefitMarkets::ApplicationController
    include Pundit

  	before_filter :set_site_id, only: [:index]

  	def index
      @benifit_markets = BenefitMarkets::BenefitMarket.where(site_id: @site_id)
  	end

    def new
      @benefit_market = ::BenefitMarkets::BenefitMarketForm.for_new(params.require(:benefit_market_kind))
      authorize @benefit_market
    end

    def create
      @benefit_market = ::BenefitMarkets::BenefitMarketForm.for_create(market_params)
      authorize @benefit_market
      if @benefit_market.save
        redirect_to benefit_markets_url(@benefit_market.show_page_model)
      else
        render "new"
      end
    end

    def edit
      @benefit_market = ::BenefitMarkets::BenefitMarketForm.for_edit(params.require(:id))
      authorize @benefit_market
    end

    def update
      @benefit_market = ::BenefitMarkets::BenefitMarketForm.for_update(params.require(:id))
      authorize @benefit_market
      if @benefit_market.update_attributes(market_params)
        redirect_to benefit_markets_url(@benefit_market.show_page_model)
      else
        render "edit"
      end
    end

    def show
      @benefit_market = ::BenefitMarkets::BenefitMarket.find(params.require(:id))
      authorize @benefit_market
    end

    private
=======
  	private
>>>>>>> Refs 23321 Modified Routes and view

  	def set_site_id
      @site_id = params[:site_id]
  	end

    def market_params
      params.require(:benefit_market).permit(
        :site_urn,
        :kind,
        :title,
        :description
      )
    end
  end
end
