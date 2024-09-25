class HbxAdminController < ApplicationController
  include Config::SiteConcern

  def registry
    authorize EnrollRegistry, :show?
  end
end
