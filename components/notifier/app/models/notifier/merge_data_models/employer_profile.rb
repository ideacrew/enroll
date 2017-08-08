module Notifier
  class MergeDataModels::EmployerProfile
    include Virtus.model
    include ActiveModel::Model

    ## is notification_type attribute necessary?  is it already reflected in event type?  should it be in parent class?
    # attribute :notification_type, String

    attribute :primary_fullname, String, default: 'John Whitmore'
    attribute :primary_identifier, String
    attribute :mpi_indicator, String
    attribute :notice_date, Date, default: '08/07/2017'
    attribute :application_date, Date
    attribute :employer_name, String, default: 'MA Health Connector'
    attribute :primary_address, MergeDataModels::Address
    attribute :broker, MergeDataModels::BrokerAgencyProfile
    attribute :health_benefit_exchange, MergeDataModels::HealthBenefitExchange
    attribute :to, String
    # attribute :plan, MergeDataModels::Plan
    attribute :plan_year, MergeDataModels::PlanYear


    def self.stubbed_object
      notice = Notifier::MergeDataModels::EmployerProfile.new
      notice.primary_address = Notifier::MergeDataModels::Address.new
      notice.plan_year = Notifier::MergeDataModels::PlanYear.new
      notice
    end
  
    def editor_tokens
      editor_attributes.inject([]) do |data, (virtus_model_name, virtus_attributes)|
        virtus_attributes.each do |attribute|
          method_name = "#{virtus_model_name}.#{attribute}"
          if virtus_model_name != :employer
            method_name = ['employer', method_name].join('.')
          end
          data << [attribute.to_s.humanize, method_name]
        end
        data
      end
    end

    def get_editor_attributes(virtus_model)
      virtus_model.attribute_set.select{|set| !set.is_a?(Virtus::Attribute::EmbeddedValue)}.collect(&:name)
    end

    def editor_attributes
      attributes_hash = {
        employer: get_editor_attributes(self.class)
      }

      Notifier::MergeDataModels::EmployerProfile.attribute_set.select{|set| set.is_a?(Virtus::Attribute::EmbeddedValue)}.each do |embed|
        attributes_hash[embed.name] = get_editor_attributes(embed.type.primitive)
      end

      attributes_hash
    end

  end
end
