# frozen_string_literal: true

module ResourceRegistryWorld
  def enable_feature(feature_name)
    return if feature_enabled?(feature_name)

    feature_dsl = EnrollRegistry[feature_name]
    feature_dsl.feature.stub(:is_enabled).and_return(true)
  end

  def disable_feature(feature_name)
    return unless feature_enabled?(feature_name)

    feature_dsl = EnrollRegistry[feature_name]
    feature_dsl.feature.stub(:is_enabled).and_return(false)
  end

  def feature_enabled?(feature_name)
    EnrollRegistry.feature_enabled?(feature_name)
  end

  def add_shop_markets_to_sep_types
    EnrollRegistry[:sep_types].settings(:only_individual).meta.stub(:enum).and_return([{individual: "Individual"}, {shop: "SHOP"}, {fehb: "Congress"}])
  end
end

World(ResourceRegistryWorld)
