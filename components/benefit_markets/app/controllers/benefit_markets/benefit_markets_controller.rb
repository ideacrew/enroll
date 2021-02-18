module BenefitMarkets
  class BenefitMarketsController < ApplicationController
    layout 'benefit_markets/application.html.slim'
    before_action :set_site_id
    before_action :permit_params, only: [:create]
    

    def index
      @benefit_markets = BenefitMarkets::BenefitMarket.where(site_id: @site_id)
    end

    def new
      @benefit_market = ::BenefitMarkets::Forms::BenefitMarket.for_new
    end

    def create
      # pundit can I do this here
      @benefit_market = BenefitMarkets::Forms::BenefitMarket.for_create params.merge(site_id: @site_id)
      if @benefit_market.save
        redirect_to site_benefit_markets_path(site_id: @site_id)
      else
        render 'new'
      end
    end

    def edit
      @benefit_market = BenefitMarkets::Forms::BenefitMarket.for_edit params[:id]
    end

    def update
      @benefit_market = BenefitMarkets::Forms::BenefitMarket.for_update params[:id]
      if @benefit_market.update_attributes market_params
        redirect_to site_benefit_markets_path(site_id: @benefit_market.site_id)
      else
        render 'edit'
      end
    end

    def destroy
      @benefit_market = BenefitMarkets::BenefitMarket.find params[:id]
      @benefit_market.destroy

      redirect_to site_benefit_markets_path(site_id: params[:site_id])
    end

    private

    def set_site_id
      @site_id = params[:site_id]
    end

    def permit_params
      self.params = params.require(:benefit_market).permit(:site_urn, :kind, :title, :description,
                                                           :aca_individual_configuration => {},
                                                           :aca_shop_configuration => {})
    end

    def market_params
      params.require(:benefit_market).permit(
        :site_urn,
        :kind,
        :title,
        :description,
        :aca_individual_configuration,
        :aca_shop_configuration,
      )
    end

    def find_hbx_admin_user
      fail NotAuthorizedError unless current_user.has_hbx_staff_role?
      # redirect_to root_url
    end
  end
end
