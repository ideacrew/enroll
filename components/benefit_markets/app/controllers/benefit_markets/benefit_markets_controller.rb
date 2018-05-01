module BenefitMarkets
  class BenefitMarketsController < ApplicationController
    layout 'benefit_markets/application'
    before_filter :set_site_id

    def index
      @benefit_markets = BenefitMarkets::BenefitMarket.where(site_id: @site_id)
    end

    def new
      @benefit_market = ::BenefitMarkets::Forms::BenefitMarket.for_new
    end

    def create
      # pundit can I do this here
      @benifit_market = BenefitMarkets::Forms::BenefitMarket.for_create params[:benifit_market]

      if @benifit_market.save
        redirect_to benifit_markets_path
      else
        render 'new'
      end
    end

    def edit
      @benefit_market = BenefitMarkets::Forms::BenefitMarket.for_edit params[:id]
    end

    def update
      @benifit_market = BenefitMarkets::Forms::BenefitMarket.for_update params[:id]

      if @benifit_market.update_attributes params[:benifit_market]
        redirect_to benifit_markets_path
      else
        render 'edit'
      end
    end

    def destroy
      @benifit_market = BenefitMarkets::BenefitMarket.find params[:id]
      @benifit_market.owner_organization.destroy
      @benifit_market.destroy

      redirect_to benifit_markets_path
    end

    private

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

    def find_hbx_admin_user
      fail NotAuthorizedError unless current_user.has_hbx_staff_role?
      # redirect_to root_url
    end
  end
end
