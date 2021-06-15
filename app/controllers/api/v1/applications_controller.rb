class Api::V1::ApplicationsController < Api::V1::ApiBaseController

    before_action :authenticate_user!
  
    def index
      query = Queries::UserDatatableQuery.new
      authorize query
      render json: query.to_json()
    end
  
    #gonna turn these into create, update, delete

    def create
      
    end

    def terminate
      permitted = params.permit(:person_id, :role_id)
      terminate_user = Operations::TerminateAgencyStaff.new(permitted[:person_id], permitted[:role_id])
      authorize terminate_user, :terminate_agency_staff?
      case terminate_agency_staff.call
      when :ok
        render json: { status: "success" }, status: :ok
      when :person_not_found
        render json: { status: "error", message: "Person could not be found" }, status: :bad_request
      when :no_role_found
        render json: { status: "error", message: "Unable to find role" }, status: :bad_request
      else
        render json: { status: "error", message: "Unknown error" }, status: :internal_server_error
      end
    end

    # def update_person
    #   operation = Operations::UpdateStaff.new(update_person_params)
    #   authorize operation, :update_staff?
    #   case operation.update_person
    #   when :ok
    #     render json: { status: "success" }, status: :ok
    #   when :person_not_found
    #     render json: { status: "error", message: "Person not found" }, status: :bad_request
    #   when :information_missing
    #     render json: { status: "error", message: "Required properties missing" }, status: :bad_request
    #   when :matching_record_found
    #     render json: { status: "error", message: "Given details match another record" }, status: :conflict
    #   when :invalid_dob
    #     render json: { status: "error", message: "Date of birth invalid" }, status: :bad_request
    #   else
    #     render json: { status: "error", message: "Unknown error" }, status: :internal_server_error
    #   end
    # end
  
    # def update_person_params
    #   params.permit(:person_id, :dob, :first_name, :last_name)
    # end

  end
  