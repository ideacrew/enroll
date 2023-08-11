# frozen_string_literal: true

# Support product import from SERFF, CSV templates, etc

# Effective dates during which sponsor may purchase this product at this price
## DC SHOP Health   - annual product changes & quarterly rate changes
## CCA SHOP Health  - annual product changes & quarterly rate changes
## DC IVL Health    - annual product & rate changes
## Medicare         - annual product & semiannual rate changes

module BenefitMarkets
  module Products
    # This class is used for loading products.
    class Product
      include Mongoid::Document
      include Mongoid::Timestamps

      CSR_KIND_TO_PRODUCT_VARIANT_MAP = ::EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP
      MARKET_KINDS = %w[shop individual].freeze
      INDIVIDUAL_MARKET_KINDS = %w[individual coverall].freeze
      AGE_BASED_RATING = 'Age-Based Rates'
      FAMILY_BASED_RATING = 'Family-Tier Rates'

      field :benefit_market_kind,   type: Symbol

      # Time period during which Sponsor may include this product in benefit application
      field :application_period,    type: Range   # => Mon, 01 Jan 2018..Mon, 31 Dec 2018

      field :hbx_id,                type: String
      field :title,                 type: String
      field :description,           type: String,         default: ""
      field :issuer_profile_id,     type: BSON::ObjectId
      field :product_package_kinds, type: Array,          default: []
      field :kind,                  type: Symbol
      field :premium_ages,          type: Range,          default: 0..65
      field :provider_directory_url,      type: String
      field :is_reference_plan_eligible,  type: Boolean,  default: false
      field :csr_variant_id, type: String

      field :deductible, type: String
      field :family_deductible, type: String
      field :issuer_assigned_id, type: String
      field :rating_method, type: String, default: AGE_BASED_RATING
      field :service_area_id, type: BSON::ObjectId
      field :network_information, type: String
      field :nationwide, type: Boolean # Nationwide
      # TODO: Refactor this to in_state_network or something similar
      field :dc_in_network, type: Boolean # DC In-Network or not
    end
  end
end
