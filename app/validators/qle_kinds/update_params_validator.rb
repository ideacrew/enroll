module QleKinds
  class UpdateParamsValidator < ::BenefitSponsors::BaseParamValidator
    define do
      required(:title).filled(:str?)
      required(:pre_event_sep_in_days).filled
      required(:post_event_sep_in_days).filled
      required(:effective_on_kinds).value(:array?, min_size?: 1)
      required(:market_kind).value(:filled?, included_in?: QualifyingLifeEventKind::MARKET_KINDS)
      required(:is_self_attested).filled(::Dry::Types["params.bool"])
      optional(:action_kind).maybe(:str?)
      optional(:tool_tip).maybe(:str?)
      optional(:reason).maybe(:str?)
    end
  end
end