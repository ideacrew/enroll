require_dependency "benefit_sponsors/application_controller"

module BenefitSponsors
  module Profiles
    module GeneralAgencies
      class GeneralAgencyProfilesController < ::BenefitSponsors::ApplicationController
        # include Acapi::Notifiers
        include DataTablesAdapter
        include BenefitSponsors::Concerns::ProfileRegistration

        rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

        # before_action :set_current_person, only: [:staff_index]
        # before_action :check_and_download_commission_statement, only: [:download_commission_statement, :show_commission_statement]
        before_action :find_general_agency_profile, only: [:employers, :family_index]
        before_action :find_general_agency_staff, only: [:edit_staff, :update_staff]

        layout 'single_column'

        # EMPLOYER_DT_COLUMN_TO_FIELD_MAP = {
        #   "2"     => "legal_name",
        #   "4"     => "employer_profile.aasm_state",
        #   "5"     => "employer_profile.plan_years.start_on"
        # }

        # def index
        #   #TODO authorize
        #   # authorize self
        #   @general_agency_profiles = BenefitSponsors::Organizations::Organization.general_agency_profiles.map(&:general_agency_profile)
        # end

        def show
          authorize self, :redirect_signup?
          set_flash_by_announcement
          @general_agency_profile = ::BenefitSponsors::Organizations::GeneralAgencyProfile.find(params[:id])
          @provider = current_user.person
        end

        def staffs
          authorize self, :redirect_signup?
          @general_agency_profile = ::BenefitSponsors::Organizations::GeneralAgencyProfile.find(params[:format])
          @staffs = @general_agency_profile.general_agency_staff_roles
        end

        # def staff_index
        #   # authorize self
        #   @q = params.permit(:q)[:q]
        #   @staff = eligible_brokers
        #   @page_alphabets = page_alphabets(@staff, "last_name")
        #   page_no = cur_page_no(@page_alphabets.first)
        #   if @q.nil?
        #     @staff = @staff.where(last_name: /^#{page_no}/i)
        #   else
        #     @staff = @staff.where(last_name: /^#{@q}/i)
        #   end
        # end

        def edit_staff
          authorize self, :redirect_signup?
          respond_to do |format|
            format.js
            format.html
          end
        end

        def update_staff
          authorize self, :redirect_signup?
          if params['approve']
            @staff.approve!
            flash[:notice] = "Staff approved successfully."
          elsif params['deny']
            @staff.deny!
            flash[:notice] = "Staff deny."
          elsif params['decertify']
            @staff.decertify!
            flash[:notice] = "Staff decertify."
          end
          send_secure_message_to_general_agency(@staff) if @staff.active?

          redirect_to benefit_sponsors.profiles_general_agencies_general_agency_profile_path(@staff.general_agency_profile)
        end

        def redirect_to_show(general_agency_profile_id)
          redirect_to benefit_sponsors.profiles_general_agencies_general_agency_profile_path(id: general_agency_profile_id)
        end

        # TODO need to refactor for cases around SHOP broker agencies
        # def family_datatable
        #   authorize self
        #   find_broker_agency_profile(BSON::ObjectId.from_string(params.permit(:id)[:id]))
        #   dt_query = extract_datatable_parameters
        #
        #   query = BenefitSponsors::Queries::BrokerFamiliesQuery.new(dt_query.search_string, @broker_agency_profile.id)
        #   @total_records = query.total_count
        #   @records_filtered = query.filtered_count
        #   @families = query.filtered_scope.skip(dt_query.skip).limit(dt_query.take).to_a
        #   primary_member_ids = @families.map do |fam|
        #     fam.primary_family_member.person_id
        #   end
        #   @primary_member_cache = {}
        #   Person.where(:_id => { "$in" => primary_member_ids }).each do |pers|
        #     @primary_member_cache[pers.id] = pers
        #   end
        #
        #   @draw = dt_query.draw
        # end

        def families
          authorize self
          @datatable = Effective::Datatables::BenefitSponsorsGeneralAgencyFamilyDataTable.new({id: params[:id]})
        end

        # def messages
        #   @sent_box = true
        #   # don't use current_user
        #   # messages are different for current_user is admin and broker account login
        #   @broker_agency_profile = ::BenefitSponsors::Organizations::BrokerAgencyProfile.find(params[:id])
        #   @broker_provider = @broker_agency_profile.primary_broker_role.person
        #
        #   respond_to do |format|
        #     format.js {}
        #   end
        # end
        #
        # def agency_messages
        # end
        #
        # def inbox
        #   @sent_box = true
        #   id = params["id"]||params['profile_id']
        #   @broker_agency_provider = find_broker_agency_profile(BSON::ObjectId(id))
        #   @folder = (params[:folder] || 'Inbox').capitalize
        #   if current_user.person._id.to_s == id
        #     @provider = current_user.person
        #   else
        #     @provider = @broker_agency_provider
        #   end
        # end

        private

        def send_secure_message_to_general_agency(staff_role)
          hbx_admin = HbxProfile.all.first
          general_agency = staff_role.general_agency_profile

          subject = "Received new general agency - #{staff_role.person.full_name}"
          body = "<br><p>Following are staff details<br>Staff Name : #{staff_role.person.full_name}<br>Staff NPN  : #{staff_role.npn}</p>"
          secure_message(hbx_admin, general_agency, subject, body)
        end

        def secure_message(from_provider, to_provider, subject, body)
          message_params = {
            sender_id: from_provider.id,
            parent_message_id: to_provider.id,
            from: from_provider.legal_name,
            to: to_provider.legal_name,
            subject: subject,
            body: body
          }

          create_secure_message(message_params, to_provider, :inbox)
          create_secure_message(message_params, from_provider, :sent)
        end

        def create_secure_message(message_params, inbox_provider, folder)
          message = Message.new(message_params)
          message.folder =  Message::FOLDER_TYPES[folder]
          msg_box = inbox_provider.inbox
          msg_box.post_message(message)
          msg_box.save
        end

        def find_general_agency_profile(id = nil)
          organizations = BenefitSponsors::Organizations::Organization.where(:"profiles._id" => id)
          @general_agency_profile = organizations.first.general_agency_profile if organizations.present?
          # authorize @general_agency_profile, :access_to_broker_agency_profile?
        end

        def find_general_agency_staff
          @staff = GeneralAgencyStaffRole.find(params[:id])
        end

        def user_not_authorized(exception)
          if exception.query == :redirect_signup?
            redirect_to main_app.new_user_registration_path
          elsif current_user.has_general_agency_staff_role?
            redirect_to profiles_broker_agencies_broker_agency_profile_path(:id => current_user.person.broker_agency_staff_roles.first.benefit_sponsors_broker_agency_profile_id)
          else
            redirect_to benefit_sponsors.new_profiles_registration_path(:profile_type => :general_agency)
          end
        end
      end
    end
  end
end
