module BenefitSponsors
  # Sites Controller
  class SitesController < ApplicationController
    def index
      @sites = BenefitSponsors::Site.all
    end

    def new
      @site = BenefitSponsors::Forms::Site.new current_user
    end

    def create
      # pundit can I do this here
      @site = BenefitSponsors::Forms::Site.new current_user, params[:site]

      if @site.save
        redirect_to sites_path
      else
        render 'new'
      end
    end

    def edit
      @site = BenefitSponsors::Forms::Site.new current_user, id: params[:id]
    end

    def update
      @site = BenefitSponsors::Forms::Site.new current_user, id: params[:id]

      if @site.save params[:site]
        redirect_to :index
      else
        render 'edit'
      end
    end

    def destroy
      @site = BenefitSponsors::Site.find params[:id]
      @site.destroy

      redirect_to 'index'
    end

    private

    def find_hbx_admin_user
      fail NotAuthorizedError unless current_user.has_hbx_staff_role?
      # redirect_to root_url
    end
  end
end
