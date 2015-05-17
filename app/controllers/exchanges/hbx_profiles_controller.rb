class Exchanges::HbxProfilesController < ApplicationController
  before_action :set_hbx_profile, only: [:show, :edit, :update, :destroy]
  before_action :check_hbx_staff_role, except: [:welcome]

  # GET /exchanges/hbx_profiles
  # GET /exchanges/hbx_profiles.json
  def index
    @organizations = Organization.exists(hbx_profile: true)
    @hbx_profiles = @organizations.map {|o| o.hbx_profile}
  end

  def employer_index
    @q = params.permit(:q)[:q]
    page_string = params.permit(:page)[:page]
    page_no = page_string.blank? ? nil : page_string.to_i
    @organizations = Organization.search(@q).exists(employer_profile: true).page page_no
    @employer_profiles = @organizations.map {|o| o.employer_profile}

    render "employers/employer_profiles/index"
  end

  def family_index
    @families = Family.all

    render "insured/families/index"
  end

  # GET /exchanges/hbx_profiles/1
  # GET /exchanges/hbx_profiles/1.json
  def show
  end

  # GET /exchanges/hbx_profiles/new
  def new
    @organization = Organization.new
    @hbx_profile = @organization.build_hbx_profile
  end

  # GET /exchanges/hbx_profiles/1/edit
  def edit
  end

  # POST /exchanges/hbx_profiles
  # POST /exchanges/hbx_profiles.json
  def create
    @organization = Organization.new(organization_params)
    @hbx_profile = @organization.build_hbx_profile(hbx_profile_params.except(:organization))

    respond_to do |format|
      if @hbx_profile.save
        format.html { redirect_to exchanges_hbx_profile_path @hbx_profile, notice: 'HBX Profile was successfully created.' }
        format.json { render :show, status: :created, location: @hbx_profile }
      else
        format.html { render :new }
        format.json { render json: @hbx_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /exchanges/hbx_profiles/1
  # PATCH/PUT /exchanges/hbx_profiles/1.json
  def update
    respond_to do |format|
      if @hbx_profile.update(hbx_profile_params)
        format.html { redirect_to exchanges_hbx_profile_path @hbx_profile, notice: 'HBX Profile was successfully updated.' }
        format.json { render :show, status: :ok, location: @hbx_profile }
      else
        format.html { render :edit }
        format.json { render json: @hbx_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /exchanges/hbx_profiles/1
  # DELETE /exchanges/hbx_profiles/1.json
  def destroy
    @hbx_profile.destroy
    respond_to do |format|
      format.html { redirect_to hbx_profiles_url, notice: 'HBX Profile was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

private
  # Use callbacks to share common setup or constraints between actions.
  def set_hbx_profile
    @hbx_profile = Organization.exists(hbx_profile: true).where(hbx_profile: params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def organization_params
    params[:hbx_profile][:organization].permit(:organization_attributes)
  end

  def hbx_profile_params
    params[:hbx_profile].permit(:hbx_profile_attributes)
  end

  def check_hbx_staff_role
    unless current_user.has_hbx_staff_role?
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
    end
  end

end
