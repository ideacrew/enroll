class Employers::EmployerAttestationsController < Employers::EmployersController

  before_action :find_employer, except: [:autocomplete_organization_legal_name, :index, :new]
  before_action :check_hbx_staff_role, only: [:update]

  autocomplete :organization, :legal_name, :full => true, :scopes => [:all_employer_profiles]

  def show

  end

  def new
    @document = Document.new
    respond_to do |format|
      format.js
    end
  end

  def create
  end

  def update

  end
end
