# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  class SendTaxFormNoticeAlert
    send(:include, Dry::Monads[:result, :do, :try])

    include Config::SiteHelper

    def call(resource:)
      return Failure({:message => ['Please find valid resource to send the alert message']}) if resource.blank?
      @resource = resource
      recipient_target = yield fetch_recipient_target
      return Success(true) if recipient_target.blank?
      recipient_name = yield fetch_recipient_name(recipient_target)
      recipient_email = yield fetch_recipient_email(recipient_target)
      send_tax_form_notice_alert_to_resource(recipient_name, recipient_email)

      Success(true)
    end

    private

    def fetch_recipient_target
      Success(@resource) if is_person?
    end

    def fetch_recipient_name(recipient_target)
      Success(recipient_target.first_name.titleize)
    end

    def fetch_recipient_email(recipient_target)
      Success(recipient_target.work_email_or_best)
    end

    def send_tax_form_notice_alert_to_resource(name, target)
      ::UserMailer.tax_form_notice_alert(name, target).deliver_now  unless !is_person? && !can_receive_electronic_communication?
      Success(true)
    end

    def is_person?
      @resource.is_a?(Person)
    end

    def can_receive_electronic_communication?
      @resource.consumer_role.present? && @resource.consumer_role.can_receive_electronic_communication?
    end
  end
end
