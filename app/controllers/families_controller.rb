class FamiliesController < ApplicationController
  include Acapi::Notifiers

  before_action :set_family #, only: [:index, :show, :new, :create, :edit, :update]
  # before_action :check_hbx_staff_role, except: [:welcome]

  layout "two_column"

  def index
    # @q = params.permit(:q)[:q]
    # page_string = params.permit(:page)[:page]
    # page_no = page_string.blank? ? nil : page_string.to_i
    # @families = Family.search(@q).exists(employer_profile: true).page page_no
    @families = Family.all

  end

  def show
    # @family = Family.find(params[id])
  end

  def new
    @family = Family.new
  end

  def create
    @family = Family.new(family_params)

    respond_to do |format|
      if @family.save
        format.html { redirect_to insured_family_path @family, notice: 'Family was successfully created.' }
        format.json { render :show, status: :created, location: @family }
      else
        format.html { render :new }
        format.json { render json: @family.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @family = Family.find(params[id])
  end

  def update
    respond_to do |format|
      if @family.update(family_params)
        format.html { redirect_to exchanges_family_path @family, notice: 'Family was successfully updated.' }
        format.json { render :show, status: :ok, location: @family }
      else
        format.html { render :edit }
        format.json { render json: @family.errors, status: :unprocessable_entity }
      end
    end
  end

private
  # Use callbacks to share common setup or constraints between actions.
  def set_family
    set_current_person
    return if not @person.present?
    # @family = Family.find(params[:id])
    if @person.primary_family.present?
      @family = @person.primary_family
    else
      message = {}
      message[:message] = '@family was set to nil'
      message[:session_person_id] = session[:person_id]
      message[:user_id] = current_user.id
      message[:oim_id] = current_user.oim_id
      message[:url] = request.original_url
      log(message, :severity=>'error')
      redirect_to "/500.html"
    end
  end

  def family_params
    params[:family].permit(:family_attributes)
  end

  def check_hbx_staff_role
    unless current_user.has_hbx_staff_role?
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
    end
  end
end
