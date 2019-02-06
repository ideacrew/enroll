module Notifier
  class Builders::ConsumerProfile

    include ActionView::Helpers::NumberHelper
    include Notifier::ApplicationHelper

    attr_accessor :consumer_role, :merge_model, :payload, :event_name, :sep_id

    def initialize
      data_object = Notifier::MergeDataModels::ConsumerProfile.new
      data_object.address = Notifier::MergeDataModels::IvlAddress.new
      data_object.dependents = Notifier::MergeDataModels::Dependent.new
      @merge_model = data_object
    end

    def resource=(resource)
      @consumer_role = resource
    end

    def notice_date
      merge_model.notice_date = TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    def first_name
      merge_model.first_name = consumer_role.person.first_name if consumer_role.present?
    end

    def last_name
      merge_model.last_name = consumer_role.person.last_name if consumer_role.present?
    end

    def append_contact_details
      mailing_address = consumer_role.person.mailing_address
      if mailing_address.present?
        merge_model.address = MergeDataModels::IvlAddress.new({
          street_1: mailing_address.address_1,
          street_2: mailing_address.address_2,
          city: mailing_address.city,
          state: mailing_address.state,
          zip: mailing_address.zip
          })
      end
    end

    def dependents
      payload["notice_params"]["dep_hbx_ids"].each do |dep_id|
        person =  Person.where(hbx_id: dep_id).first.full_name
        
        merge_model.dependents = MergeDataModels::Dependent.new({
          first_name: person.first_name,
          last_name: person.last_name
        })
      end
    end

    def ivl_oe_start_date
      merge_model.ivl_oe_start_date = Settings.aca.individual_market.upcoming_open_enrollment.start_on
    end

    def ivl_oe_end_date
      merge_model.ivl_oe_end_date = Settings.aca.individual_market.upcoming_open_enrollment.end_on
    end

    def email
      merge_model.email = consumer_role.person.work_email_or_best if consumer_role.present?
    end

    def consumer_profile
      consumer_role.consumer_profile
    end   
    # Using same merge model for special enrollment period and qualifying life event kind
    def format_date(date)
      return '' if date.blank?
      date.strftime('%m/%d/%Y')
    end
  end
end
