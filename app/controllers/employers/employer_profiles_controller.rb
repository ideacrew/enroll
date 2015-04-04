class Employers::EmployerProfilesController < ApplicationController
  before_filter :find_employer, only: [:show, :destroy]

  def index
    @employers = EmployerProfile.all.to_a
  end

  def my_account
  end

  def show
  end

  def new
    @employer = EmployerProfile.new
  end

  def create
    params["employer"]["entity_kind"] = EmployerProfile::ENTITY_KINDS.sample # temp hack for getting employer creation working.
    @employer = EmployerProfile.new(employer_params)

    respond_to do |format|
      if @employer.save
        format.html { redirect_to employers_employer_index_path, notice: 'Employer was successfully created.' }
        format.json { render json: @employer, status: :created, location: @employer }
      else
        format.html { render action: "new" }
        format.json { render json: @employer.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @employer.destroy

    respond_to do |format|
      format.html { redirect_to employers_employer_index_path, notice: "Employer successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

  def find_employer
    @employer = EmployerProfile.find(params[:id])
  end

  def employer_params
    params.require(:employer).permit(:legal_name, :fein, :entity_kind)
  end
end
