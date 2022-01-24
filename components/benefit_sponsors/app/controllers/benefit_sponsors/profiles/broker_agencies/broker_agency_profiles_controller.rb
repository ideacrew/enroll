# frozen_string_literal: true

require_dependency "benefit_sponsors/application_controller"

module BenefitSponsors
  module Profiles
    module BrokerAgencies
      class BrokerAgencyProfilesController < ::BenefitSponsors::ApplicationController
        # include Acapi::Notifiers
        include DataTablesAdapter
        include BenefitSponsors::Concerns::ProfileRegistration

        rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

        before_action :set_current_person, only: [:staff_index]
        before_action :check_and_download_commission_statement, only: [:download_commission_statement, :show_commission_statement]

        skip_before_action :verify_authenticity_token, only: :create

        layout 'single_column'

        EMPLOYER_DT_COLUMN_TO_FIELD_MAP = {
          "2" => "legal_name",
          "4" => "employer_profile.aasm_state",
          "5" => "employer_profile.plan_years.start_on"
        }.freeze

        def create
          json = request.body.read
          body_json = JSON.parse(json)
          result = ::BenefitSponsors::Services::BrokerRegistrationService.call(body_json["data"], current_user)
          respond_to do |format|
            if result.success?
              format.json { render :status => 201, json: { :message => "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed." } }
            else
              format.json { render :status => 422, :json => { errors: result.errors.to_h } }
            end
          end
        end

        def index
          authorize self
          @broker_agency_profiles = BenefitSponsors::Organizations::Organization.broker_agency_profiles.map(&:broker_agency_profile)
        end

        def show
          authorize self, :redirect_signup?
          set_flash_by_announcement
          @broker_agency_profile = ::BenefitSponsors::Organizations::BrokerAgencyProfile.find(params[:id])
          @provider = current_user.person
          @id = params[:id]
        end

        def staff_index
          authorize self
          @q = params.permit(:q)[:q]
          @staff = eligible_brokers
          @page_alphabets = page_alphabets(@staff, "last_name")
          page_no = cur_page_no(@page_alphabets.first)
          @staff = if @q.nil?
                     @staff.where(last_name: /^#{page_no}/i)
                   elsif @q.blank?
                     @staff.uniq.sort_by(&:last_name)
                   else
                     broker_profile_ids = BenefitSponsors::Organizations::Organization.where(legal_name: /^#{Regexp.escape(@q)}/i).map(&:profiles).flatten.map(&:id)
                     find_by_agency_name = @staff.where(:'broker_role.benefit_sponsors_broker_agency_profile_id'.in => broker_profile_ids)
                     find_by_last_name = @staff.where(last_name: /^#{Regexp.escape(@q)}/i)
                     find_by_first_name = @staff.where(first_name: /^#{Regexp.escape(@q)}/i)
                     unsorted_search = find_by_agency_name + find_by_last_name + find_by_first_name
                     unsorted_search.sort_by(&:last_name).uniq
                   end
        end

        # TODO: need to refactor for cases around SHOP broker agencies
        def family_datatable
          authorize self
          find_broker_agency_profile(BSON::ObjectId.from_string(params.permit(:id)[:id]))
          @display_family_link = if ::EnrollRegistry.feature_enabled?(:disable_family_link_in_broker_agency)
                                   current_user.has_hbx_staff_role? || !::EnrollRegistry[:disable_family_link_in_broker_agency].setting(:enable_after_time_period).item.cover?(TimeKeeper.date_of_record)
                                 else
                                   true
                                 end
          dt_query = extract_datatable_parameters

          query = BenefitSponsors::Queries::BrokerFamiliesQuery.new(dt_query.search_string, @broker_agency_profile.id, @broker_agency_profile.market_kind)
          @total_records = query.total_count
          @records_filtered = query.filtered_count
          @families = query.filtered_scope.skip(dt_query.skip).limit(dt_query.take).to_a
          primary_member_ids = @families.map do |fam|
            fam.primary_family_member.person_id
          end
          @primary_member_cache = {}
          Person.where(:_id => { "$in" => primary_member_ids }).each do |pers|
            @primary_member_cache[pers.id] = pers
          end

          @draw = dt_query.draw
        end

        def family_index
          authorize self
          find_broker_agency_profile(BSON::ObjectId.from_string(params.permit(:id)[:id]))
          @q = params.permit(:q)[:q]

          respond_to do |format|
            format.js {}
          end
        end

        def commission_statements
          permitted = params.permit(:id)
          @id = permitted[:id]
          if current_user.has_broker_agency_staff_role?
            id = BSON::ObjectId(params[:id]) || current_user.person.broker_role.benefit_sponsors_broker_agency_profile_id
            find_broker_agency_profile(id)
          elsif current_user.has_hbx_staff_role?
            find_broker_agency_profile(BSON::ObjectId.from_string(@id))
          else
            redirect_to new_profiles_registration_path
            return
          end
          documents = @broker_agency_profile.documents
          @statements = get_commission_statements(documents) if documents
          collect_and_sort_commission_statements
          respond_to do |format|
            format.js
          end
        end

        def show_commission_statement
          options = {}
          options[:filename] = @commission_statement.title
          options[:type] = 'application/pdf'
          options[:disposition] = 'inline'
          send_data Aws::S3Storage.find(@commission_statement.identifier), options
        end

        def download_commission_statement
          options = {}
          options[:content_type] = @commission_statement.type
          options[:filename] = @commission_statement.title
          send_data Aws::S3Storage.find(@commission_statement.identifier), options
        end

        def general_agency_index
          @broker_agency_profile = BenefitSponsors::Organizations::BrokerAgencyProfile.find(params[:id])
          @broker_role = current_user.person.broker_role || nil
          @general_agency_profiles = BenefitSponsors::Organizations::GeneralAgencyProfile.all_by_broker_role(@broker_role, approved_only: true)
        end

        def messages
          @sent_box = true
          # don't use current_user
          # messages are different for current_user is admin and broker account login
          @broker_agency_profile = ::BenefitSponsors::Organizations::BrokerAgencyProfile.find(params[:id])
          @broker_provider = @broker_agency_profile.primary_broker_role.person

          respond_to do |format|
            format.js {}
          end
        end

        def agency_messages; end

        def inbox
          @sent_box = true
          if params["id"].present?
            provider_id = params["id"]
            @broker_agency_provider = Person.find(provider_id)
            @broker_agency_profile = @broker_agency_provider.broker_role.broker_agency_profile
            authorize @broker_agency_profile, :access_to_broker_agency_profile?
          elsif params['profile_id'].present?
            provider_id = params['profile_id']
            @broker_agency_provider = find_broker_agency_profile(BSON::ObjectId(provider_id))
          end

          @folder = (params[:folder] || 'Inbox').capitalize

          @provider = (current_user.person._id.to_s == provider_id) ? current_user.person : @broker_agency_provider
        end

        def email_guide
          notice = "A copy of the Broker Registration Guide has been emailed to #{params[:email]}"
          flash[:notice] = notice
          UserMailer.broker_registration_guide(params).deliver_now
          render 'benefit_sponsors/profiles/registrations/confirmation', :layout => 'single_column'
        end

        private

        def check_and_download_commission_statement
          @broker_agency_profile = BenefitSponsors::Organizations::Profile.find(params[:id])
          authorize @broker_agency_profile, :access_to_broker_agency_profile?
          @commission_statement = @broker_agency_profile.documents.find(params[:statement_id])
        end

        def find_broker_agency_profile(id = nil)
          organizations = BenefitSponsors::Organizations::Organization.where(:"profiles._id" => id)
          @broker_agency_profile = organizations.first.broker_agency_profile if organizations.present?
          authorize @broker_agency_profile, :access_to_broker_agency_profile? if @broker_agency_profile
        end

        def user_not_authorized(exception)
          if exception.query == :redirect_signup?
            redirect_to main_app.new_user_registration_path
          elsif current_user&.has_broker_agency_staff_role?
            redirect_to profiles_broker_agencies_broker_agency_profile_path(:id => current_user.person.broker_agency_staff_roles.first.benefit_sponsors_broker_agency_profile_id)
          else
            redirect_to new_profiles_registration_path(:profile_type => :broker_agency)
          end
        end

        def send_general_agency_assign_msg(general_agency, employer_profile, status); end

        def eligible_brokers
          broker_profile_ids = BenefitSponsors::Organizations::Organization.broker_agency_profiles.approved_and_accepting_broker_agencies.broker_agencies_by_market_kind(['both', person_market_kind]).map(&:broker_agency_profile).pluck(:id)
          Person.where(:"broker_role.benefit_sponsors_broker_agency_profile_id".in => broker_profile_ids, :"broker_role.aasm_state" => "active")
        end

        def update_ga_for_employers(broker_agency_profile, old_default_ga = nil); end

        def person_market_kind
          if @person.has_active_consumer_role?
            "individual"
          elsif @person.has_active_employee_role?
            "shop"
          end
        end

        def check_general_agency_profile_permissions_assign; end

        def check_general_agency_profile_permissions_set_default; end

        def get_commission_statements(documents)
          commission_statements = []
          documents.each do |document|
            # grab only documents that are commission statements by checking the bucket in which they are placed
            commission_statements << document if document.identifier.include?("commission-statements")
          end
          commission_statements
        end

        def collect_and_sort_commission_statements(_sort_order = 'ASC')
          @statement_years = (Settings.aca.shop_market.broker_agency_profile.minimum_commission_statement_year..TimeKeeper.date_of_record.year).to_a.reverse
          @statements.sort_by!(&:date).reverse!
        end
      end
    end
  end
end
