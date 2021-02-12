module Authenticator
  extend ActiveSupport::Concern

  included do
    before_action :verify_access
  end

  private

  def verify_access
    ::EnrollRegistry[:aca_shop_market].enabled? ? true : not_found
  end

  def not_found
    raise 'Not Found'
  end
end