module Notifier
  module MergeDataModels
    BUILDER_STRING_MAPPING = {
      'Notifier::MergeDataModels::Address' => Notifier::MergeDataModels::Address,
      'Notifier::MergeDataModels::BenefitApplication' => Notifier::MergeDataModels::BenefitApplication,
      'Notifier::MergeDataModels::BenefitPackage' => Notifier::MergeDataModels::BenefitPackage,
      'Notifier::MergeDataModels::BrokerAgencyProfile' => Notifier::MergeDataModels::BrokerAgencyProfile,
      'Notifier::MergeDataModels::BrokerProfile' => Notifier::MergeDataModels::BrokerProfile,
      'Notifier::MergeDataModels::Broker' => Notifier::MergeDataModels::Broker,
      'Notifier::MergeDataModels::CensusEmployee' => Notifier::MergeDataModels::CensusEmployee,
      'Notifier::MergeDataModels::ConsumerRole' => Notifier::MergeDataModels::ConsumerRole,
      'Notifier::MergeDataModels::ContributionLevel' => Notifier::MergeDataModels::ContributionLevel,
      'Notifier::MergeDataModels::Dependent' => Notifier::MergeDataModels::Dependent,
      'Notifier::MergeDataModels::EmployeeProfile' => Notifier::MergeDataModels::EmployeeProfile,
      'Notifier::MergeDataModels::EmployeeRole' => Notifier::MergeDataModels::EmployeeRole,
      'Notifier::MergeDataModels::EmployerProfile' => Notifier::MergeDataModels::EmployerProfile,
      'Notifier::MergeDataModels::Enrollment' => Notifier::MergeDataModels::Enrollment,
      'Notifier::MergeDataModels::GeneralAgency' => Notifier::MergeDataModels::GeneralAgency,
      'Notifier::MergeDataModels::HealthBenefitExchange' => Notifier::MergeDataModels::HealthBenefitExchange,
      'Notifier::MergeDataModels::OfferedProduct' => Notifier::MergeDataModels::OfferedProduct,
      'Notifier::MergeDataModels::Person' => Notifier::MergeDataModels::Person,
      'Notifier::MergeDataModels::Product' => Notifier::MergeDataModels::Product,
      'Notifier::MergeDataModels::SpecialEnrollmentPeriod' => Notifier::MergeDataModels::SpecialEnrollmentPeriod,
      'Notifier::MergeDataModels::SponsorContribution' => Notifier::MergeDataModels::SponsorContribution,
      'Notifier::MergeDataModels::SponsoredBenefit' => Notifier::MergeDataModels::SponsoredBenefit,
      'Notifier::MergeDataModels::TaxHousehold' => Notifier::MergeDataModels::TaxHousehold
    }.freeze

    BUILDER_STRING_KINDS = BUILDER_STRING_MAPPING.keys.freeze

    class InvalidBuilderError < StandardError; end
  end
end
