module Notifier
  class Services::ShopNoticeService

    def placeholders
    end

    def configurations
    end

    def tokens
    end

    def recipients
      {
        "Employer" => "Notifier::MergeDataModels::EmployerProfile",
        "Employee" => "Notifier::MergeDataModels::EmployeeProfile",
        "Broker" => "Notifier::MergeDataModels::BrokerProfile",
        "Broker Agency" => "Notifier::MergeDataModels::BrokerAgencyProfile",
        "GeneralAgency" => "Notifier::MergeDataModels::GeneralAgency"
      }
    end
  end
end