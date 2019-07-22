module Admin
  module QleKinds
    class UpdateRequest
      extend Dry::Initializer

      option :id, Dry::Types['coercible.string']
      option :title, Dry::Types['coercible.string']
      option :market_kind, Dry::Types['coercible.string']
      option :is_self_attested, Dry::Types['params.bool']
      option :effective_on_kinds, Dry::Types['coercible.array']
      option :post_event_sep_in_days, Dry::Types['coercible.string']
      option :pre_event_sep_in_days, Dry::Types['coercible.string']
      option :action_kind, Dry::Types['coercible.string'], optional: true
      option :tool_tip, Dry::Types['coercible.string'], optional: true
      option :reason, Dry::Types['coercible.string'], optional: true
    end
  end
end