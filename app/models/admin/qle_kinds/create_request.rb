module Admin
  module QleKinds
    class CreateRequest
      extend Dry::Initializer

      option :title, Dry::Types['coercible.string']
      option :market_kind, Dry::Types['coercible.string']
      option :is_self_attested, Dry::Types['params.bool']

      option :action_kind, Dry::Types['coercible.string'], optional: true
      option :tool_tip, Dry::Types['coercible.string'], optional: true
      option :reason, Dry::Types['coercible.string'], optional: true
    end
  end
end