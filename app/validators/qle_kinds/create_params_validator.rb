module QleKinds
  class CreateParamsValidator < ::BenefitSponsors::BaseParamValidator
    define do
      required(:title).value(:filled?)
      required(:market_kind).value(:filled?, included_in?: QualifyingLifeEventKind::MARKET_KINDS)
      required(:is_self_attested).filled(::Dry::Types["params.bool"])

      optional(:action_kind).maybe(:str?)
      optional(:tool_tip).maybe(:str?)
      optional(:reason).maybe(:str?)
    end
  end
end