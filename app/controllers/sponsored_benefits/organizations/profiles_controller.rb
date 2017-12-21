require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class Organizations::ProfilesController < ApplicationController
    include Acapi::Notifiers
    include Config::AcaConcern
    include DataTablesAdapter
    include Config::BrokerAgencyHelper

    before_action :find_broker_agency_profile, only: [:employers, :new]

    def employers
      ::Effective::Datatables::BrokerAgencyEmployerDatatable.profile_id = @broker_agency_profile._id
      @datatable = ::Effective::Datatables::BrokerAgencyEmployerDatatable.new
    end

    def new
      @organization = ::Forms::EmployerProfile.new
      get_sic_codes
    end

    def create
      broker_agency_profile = ::BrokerAgencyProfile.find(params[:broker_agency_id])
      sic_code = params[:organization][:profile][:sic_code]
      pdo = Organizations::PlanDesignOrganization.create(organization_params)
      pdo.owner_profile_id = broker_agency_profile.id
      pdo.profile = Organizations::AcaShopCcaEmployerProfile.new({sic_code: sic_code})
      broker_agency_profile.plan_design_organizations << pdo
      broker_agency_profile.save!

      flash[:notice] = 'Prospect Employer Created'
      redirect_to main_app.broker_agencies_profiles_path
    end

    def edit
    end

    def update
    end

  private
    helper_method :active_tab

    def active_tab
      "employers-tab"
    end
    
    def find_broker_agency_profile
      @broker_agency_profile = ::BrokerAgencyProfile.find(params[:profile_id])
      #authorize @broker_agency_profile, :access_to_broker_agency_profile?
    end

    def organization_params
      params[:organization].delete :profile
      params.require(:organization).permit(
        :entity_kind, :dba, :legal_name, :contact_method,
        :profile_attributes => [:sic_code],
        :office_locations_attributes => [
          {:address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip, :county]},
          {:phone_attributes => [:kind, :area_code, :number, :extension]},
          {:email_attributes => [:kind, :address]},
          :is_primary
        ]
      )
    end

    def get_sic_codes
      @grouped_options = {}
      ::SicCode.all.group_by(&:industry_group_label).each do |industry_group_label, sic_codes|
        @grouped_options[industry_group_label] = sic_codes.collect{|sc| ["#{sc.sic_label} - #{sc.sic_code}", sc.sic_code]}
      end
    end
  end
end
