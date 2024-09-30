class HbxAdminController < ApplicationController
  include Config::SiteConcern

  before_action :enable_bs4_layout if EnrollRegistry.feature_enabled?(:bs4_admin_flow)

  layout 'progress' if EnrollRegistry.feature_enabled?(:bs4_admin_flow)

  def registry
    authorize EnrollRegistry, :show?
  end
end
