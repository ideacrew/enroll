module Notifier
  class Builders::ConsumerRole

    include ActionView::Helpers::NumberHelper
    include Notifier::ApplicationHelper

    attr_accessor :consumer_role, :merge_model, :payload, :event_name, :sep_id

    def initialize
      data_object = Notifier::MergeDataModels::ConsumerRole.new
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

    def person
      consumer_role.person
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
      family = consumer_role.person.primary_family
      family.active_family_members.each do |member|
        merge_model.dependents << MergeDataModels::Dependent.new({
          first_name: member.first_name,
          last_name: member.last_name
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

    def coverage_year
      year = if self.is_shop?
                benefit_group.plan_year.start_on.year
              else
                plan.try(:active_year) || effective_on.year
              end
    end

    def previous_coverage_year
      coverage_year.to_i - 1
    end

    def email
      merge_model.email = consumer_role.person.work_email_or_best if consumer_role.present?
    end

    def aqhp
      person.is_aqhp?
    end

    def irs_consent
      notice_params[:irs_consent].upcase == "YES"
    end

    def shop?
      false
    end
     # Using same merge model for special enrollment period and qualifying life event kind
    def format_date(date)
      return '' if date.blank?
      date.strftime('%m/%d/%Y')
    end
  end
end
