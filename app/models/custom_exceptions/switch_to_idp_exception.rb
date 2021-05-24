# frozen_string_literal: true

# Custom class for handling IDP error
class SwitchToIdpException < StandardError
  # This will display greater details of the exception
  def initialize(msg = "Unable to switch to IDP", exception_type = "SwitchToIdpException")
    @exception_type = exception_type
    super(msg)
  end
end