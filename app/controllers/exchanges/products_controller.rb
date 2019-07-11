# frozen_string_literal: true

module Exchanges
  class ProductsController < HbxProfilesController
    before_action :check_hbx_staff_role
  end
end