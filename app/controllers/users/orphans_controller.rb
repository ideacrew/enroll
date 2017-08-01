class Users::OrphansController < ApplicationController
  before_action :check_agent_role
  before_action :set_orphan, only: [:show, :destroy]

  layout "two_column"

  def index
    @orphans = User.orphans
  end

  def show
  end

  def destroy
    @orphan.destroy
    respond_to do |format|
      format.html { redirect_to exchanges_hbx_profiles_path, notice: 'Orphan user account was successfully deleted.' }
      format.json { head :no_content }
    end
  end

private
  def check_agent_role
    unless current_user.has_hbx_staff_role?
      redirect_to root_path, :flash => { :error => "You must be an HBX Administrator" }
    end
  end

    # Use callbacks to share common setup or constraints between actions.
    def set_orphan
      @orphan = User.find(params[:id])
    end

end
