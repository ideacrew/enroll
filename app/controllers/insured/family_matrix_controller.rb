class Insured::FamilyMatrixController < ApplicationController
	

	before_action :set_current_person, :set_family

	def index
    @type = (params[:employee_role_id].present? && params[:employee_role_id] != 'None') ? "employee" : "consumer"

    if (params[:resident_role_id].present? && params[:resident_role_id])
      @type = "resident"
      @resident_role = ResidentRole.find(params[:resident_role_id])
      @family.hire_broker_agency(current_user.person.broker_role.try(:id))
      redirect_to resident_index_insured_family_members_path(:resident_role_id => @person.resident_role.id, :change_plan => params[:change_plan], :qle_date => params[:qle_date], :qle_id => params[:qle_id], :effective_on_kind => params[:effective_on_kind], :qle_reason_choice => params[:qle_reason_choice], :commit => params[:commit])
    end

    if @type == "employee"
      emp_role_id = params.require(:employee_role_id)
      @employee_role = @person.employee_roles.detect { |emp_role| emp_role.id.to_s == emp_role_id.to_s }
    elsif @type == "consumer"
      @consumer_role = @person.consumer_role
      @family.hire_broker_agency(current_user.person.broker_role.try(:id))
    end
    @change_plan = params[:change_plan].present? ? 'change_by_qle' : ''
    @change_plan_date = params[:qle_date].present? ? params[:qle_date] : ''

    @matrix = @family.build_relationship_matrix
    @missing_relationships = @family.find_missing_relationships(@matrix)
    @relationship_kinds = PersonRelationship::Relationships
	end

  def create
    predecessor = @family.family_members.where(id: params[:predecessor_id]).first
    successor = @family.family_members.where(id: params[:successor_id]).first
    predecessor.add_relationship(successor, params[:kind])
    @family.reload
    @matrix = @family.build_relationship_matrix
    @missing_relationships = @family.find_missing_relationships(@matrix)
    @relationship_kinds = PersonRelationship::Relationships
    respond_to do |format|
      format.html {
        if @missing_relationships.blank?
          redirect_to params[:redirect_url]
        else
          redirect_to insured_family_matrix_index_path, notice: 'Relationship was successfully updated.'
        end
      }
      format.js
    end
  end

	private
	def set_family
		@family = @person.try(:primary_family)
	end
end
