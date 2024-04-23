module Notifier
  module MergeDataModels
    BUILDER_STRING_KINDS = [
      "Notifier::MergeDataModels::Address",
      "Notifier::MergeDataModels::BenefitApplication",
      "Notifier::MergeDataModels::BenefitPackage",
      "Notifier::MergeDataModels::BrokerAgencyProfile",
      "Notifier::MergeDataModels::BrokerProfile",
      "Notifier::MergeDataModels::Broker",
      "Notifier::MergeDataModels::CensusEmployee",
      "Notifier::MergeDataModels::ConsumerRole",
      "Notifier::MergeDataModels::ContributionLevel",
      "Notifier::MergeDataModels::Dependent",
      "Notifier::MergeDataModels::EmployeeProfile",
      "Notifier::MergeDataModels::EmployeeRole",
      "Notifier::MergeDataModels::EmployerProfile",
      "Notifier::MergeDataModels::Enrollment",
      "Notifier::MergeDataModels::GeneralAgency",
      "Notifier::MergeDataModels::HealthBenefitExchange",
      "Notifier::MergeDataModels::OfferedProduct",
      "Notifier::MergeDataModels::Person",
      "Notifier::MergeDataModels::Product",
      "Notifier::MergeDataModels::SpecialEnrollmentPeriod",
      "Notifier::MergeDataModels::SponsorContribution",
      "Notifier::MergeDataModels::SponsoredBenefit",
      "Notifier::MergeDataModels::TaxHousehold"
    ].freeze

    BUILDER_STRING_MAPPING = (BUILDER_STRING_KINDS.map { |bst| [bst, bst.constantize] }).to_h.freeze

    class InvalidBuilderError < StandardError; end
  end
end
