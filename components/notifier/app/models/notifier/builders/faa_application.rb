module Notifier
  module Builders
    class FaaApplication
      # Builder class ConsumerRole for Projected Renewal Eligibility Notice- AQHP/UQHP

      include ActionView::Helpers::NumberHelper
      include Notifier::ApplicationHelper
      include Config::ContactCenterHelper
      include Config::SiteHelper

      attr_accessor :faa_application, :merge_model, :full_name, :payload,
                    :event_name, :sep_id
