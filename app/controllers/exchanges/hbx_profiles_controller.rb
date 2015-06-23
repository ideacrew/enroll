class Exchanges::HbxProfilesController < ApplicationController
  before_action :check_hbx_staff_role, except: [:welcome]
  before_action :set_hbx_profile, only: [:edit, :update, :destroy]

  # GET /exchanges/hbx_profiles
  # GET /exchanges/hbx_profiles.json
  def index
    @organizations = Organization.exists(hbx_profile: true)
    @hbx_profiles = @organizations.map {|o| o.hbx_profile}
  end

  def employer_index
    @q = params.permit(:q)[:q]
    @orgs = Organization.search(@q).exists(employer_profile: true)
    @page_alphabets = page_alphabets(@orgs, "legal_name")
    page_no = cur_page_no(@page_alphabets.first)
    @organizations = @orgs.where("legal_name" => /^#{page_no}/i)

    @employer_profiles = @organizations.map {|o| o.employer_profile}

    respond_to do |format|
      format.html { render "employers/employer_profiles/index" }
      format.js {}
    end
  end

  def family_index
    @q = params.permit(:q)[:q]
    page_string = params.permit(:families_page)[:families_page]
    page_no = page_string.blank? ? nil : page_string.to_i
    unless @q.present?
      @families = Family.page page_no
      @total = Family.count
    else
      total_families = Person.search(@q).map(&:families).flatten.uniq
      @total = total_families.count
      @families = Kaminari.paginate_array(total_families).page page_no
    end
    respond_to do |format|
      format.html { render "insured/families/index" }
      format.js {}
    end
  end

  def broker_agency_index
    @broker_agency_profiles = BrokerAgencyProfile.all

    respond_to do |format|
      format.html { render "broker_agencies/profiles/index" }
      format.js {}
    end
  end

  def broker_index
    @brokers = BrokerRole.all

    respond_to do |format|
      format.html { render "broker_index" }
      format.js {}
    end
  end

  def issuer_index
    @issuers = CarrierProfile.all


    respond_to do |format|
      format.html { render "issuer_index" }
      format.js {}
    end
  end

  def product_index

    respond_to do |format|
      format.html { render "product_index" }
      format.js {}
    end
  end

  def configuration

    respond_to do |format|
      format.html { render "configuration_index" }
      format.js {}
    end
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

  # GET /exchanges/hbx_profiles/1/inbox
  def inbox
    if HbxPortal.count > 0
      @hbx_portal = HbxPortal.try(params[:id]) || HbxPortal.first
    else
      @hbx_portal = HbxPortal.new
      @hbx_portal.save
      m = Message.new
      m.subject = 'Portal test message'
      m.sender_id=current_user.id
      @hbx_portal.inbox.messages << m
      @hbx_portal.inbox.messages << m
      @hbx_portal.save
    end

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

  def set_date
    TimeKeeper.set_date_of_record(params[:time_keeper][:date_of_record])
    TimeKeeper.instance.push_date_of_record
    redirect_to exchanges_hbx_profiles_root_path
  end


private
  # Use callbacks to share common setup or constraints between actions.
  def set_hbx_profile
    @hbx_profile = HbxProfile.find(params[:id])
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
