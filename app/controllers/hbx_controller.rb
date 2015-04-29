class HbxController < ApplicationController
  before_action :check_hbx_role, only: [:welcome]

  def welcome

  end

  private
    def check_hbx_role
      unless current_user.has_hbx_role?
        redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
      end
    end
end
