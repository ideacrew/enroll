# frozen_string_literal: true

module Entities
  module Authentication
    # Details and feedback about a successful attempt to authenticate a SAML
    # user.
    class SamlAuthenticationSuccess < Dry::Struct
      attribute :relay_state, Types::String.optional.meta(omittable: true)
      attribute :new_user, Types::Bool.meta(omittable: false)
      attribute :user, Types.Instance(User).meta(omittable: false)
      attribute :saml_session_index, Types::String.optional.meta(omittable: false)
      attribute :saml_name_id, Types::String.meta(omittable: false)
    end
  end
end