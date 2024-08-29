# frozen_string_literal: true

module Entities
  module Authentication
    class SamlAuthenticationFailure < Dry::Struct
      attribute :kind,
                Types::Symbol.enum(
                  :invalid_token,
                  :invalid_user_data,
                  :user_expired
                ).meta(omittable: false)
      attribute :message, Types::String.meta(omittable: false)
      attribute :severity, Types::String.meta(omittable: false)
    end
  end
end