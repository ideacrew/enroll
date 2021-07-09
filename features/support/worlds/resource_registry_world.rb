# frozen_string_literal: true

module ResourceRegistryWorld
  def enable_feature(feature_name, args = {})
    registry_name = args[:registry_name] || EnrollRegistry
    return if feature_enabled?(feature_name)

    feature_dsl = registry_name[feature_name]
    feature_dsl.feature.stub(:is_enabled).and_return(true)
  end

  def disable_feature(feature_name, args = {})
    registry_name = args[:registry_name] || EnrollRegistry
    return unless feature_enabled?(feature_name)

    feature_dsl = registry_name[feature_name]
    feature_dsl.feature.stub(:is_enabled).and_return(false)
  end

  def feature_enabled?(feature_name, args = {})
    registry_name = args[:registry_name] || EnrollRegistry
    registry_name.feature_enabled?(feature_name)
  end

  def add_shop_markets_to_sep_types(args = {})
    registry_name = args[:registry_name] || EnrollRegistry
    registry_name[:sep_types].settings(:market_kind).meta.stub(:enum).and_return([{individual: "Individual"}, {shop: "SHOP"}, {fehb: "Congress"}])
  end

  def enable_fa_feature(feature_name)
    return if fa_feature_enabled?(feature_name)

    feature_dsl = FinancialAssistanceRegistry[feature_name]
    feature_dsl.feature.stub(:is_enabled).and_return(true)
  end

  def fa_feature_enabled?(feature_name)
    FinancialAssistanceRegistry.feature_enabled?(feature_name)
  end
end

World(ResourceRegistryWorld)
