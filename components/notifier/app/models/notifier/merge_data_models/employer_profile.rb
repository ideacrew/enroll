module Notifier
  class MergeDataModels::EmployerProfile
    include Virtus.model
    include ActiveModel::Model
    
    attribute :primary_fullname, String, default: 'John Whitmore'
    attribute :primary_identifier, String
    attribute :mpi_indicator, String
    attribute :notice_date, Date, default: '08/07/2017'
    attribute :application_date, Date
    attribute :employer_name, String, default: 'MA Health Connector'
    attribute :primary_address, MergeDataModels::Address
    attribute :broker, MergeDataModels::Broker
    attribute :to, String
    attribute :plan, MergeDataModels::Plan
    attribute :plan_year, MergeDataModels::PlanYear
    attribute :addresses, Array[MergeDataModels::Address]

    def self.stubbed_object
      notice = Notifier::MergeDataModels::EmployerProfile.new
      notice.primary_address = Notifier::MergeDataModels::Address.new
      notice.plan_year = Notifier::MergeDataModels::PlanYear.new
      notice.plan = Notifier::MergeDataModels::Plan.new
      notice.broker = Notifier::MergeDataModels::Broker.new
      notice.addresses = [ notice.primary_address ]
      notice
    end

    def collections
      %w{addresses}
    end

    def conditions
      %w{broker_present?}
    end

    def broker_present?
      self.broker.present?
    end
  
    def place_holders
      placeholders = []

      collections.each do |collection|
        placeholders << {
          title: "Loop: #{collection.humanize}",
          target: ['employer', collection].join('.'),
          iterator: collection.singularize,
          type: 'loop'
        }

        if merge_model = Notifier::MergeDataModels::EmployerProfile.attribute_set.detect{|e| e.name == collection.to_sym}
          get_editor_attributes(merge_model.type.member_type).each do |attribute|
            placeholders << {
              title: "&nbsp;&nbsp; #{attribute.to_s.humanize}",
              target: [collection.singularize, attribute.to_s].join('.'),
            }
          end
        end
      end

      conditions.each do |condition|
         placeholders << {
          title: "Condition: #{condition.humanize}",
          target: ['employer', condition].join('.'),
          type: 'condition'
        }
      end

      placeholders
    end
  
    def editor_tokens
      editor_attributes.inject([]) do |data, (virtus_model_name, virtus_attributes)|
        virtus_attributes.each do |attribute|
          method_name = "#{virtus_model_name}.#{attribute}"
          if virtus_model_name != :employer
            method_name = ['employer', method_name].join('.')
          end
          data << ["#{virtus_model_name.to_s.humanize} - #{attribute.to_s.humanize}", method_name]
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
