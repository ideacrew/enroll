module Notifier
  module Services
    class ShopNoticeService

      def recipients
        {
          "Employer" => "Notifier::MergeDataModels::EmployerProfile",
          "Employee" => "Notifier::MergeDataModels::EmployeeProfile",
          "Broker" => "Notifier::MergeDataModels::BrokerProfile",
          "Broker Agency" => "Notifier::MergeDataModels::BrokerAgencyProfile",
          "GeneralAgency" => "Notifier::MergeDataModels::GeneralAgency"
        }
      end

      def setting_placeholders
        system_settings.inject([]) do |placeholders, (category, attribute_set)|
          attribute_set.each do |attribute|
            placeholders << {
              title: "#{category.to_s.humanize}: #{attribute.humanize}",
              target: ["Settings", category, attribute].join('.')
            }
          end
          placeholders
        end
      end

      def system_settings
        {
          :site => ['domain_name', 'home_url', 'short_name', 'byline', 'long_name'],
          :contact_center => ['name', 'alt_name', 'phone_number', 'tty_number', 'tty', 'alt_phone_number', 'email_address'],
          :aca => ['state_name state_abbreviation'],
          :'aca.shop_market' => ['binder_payment_due_on']
        }
      end
    end
  end
end