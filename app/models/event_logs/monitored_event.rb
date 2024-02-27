# frozen_string_literal: true

module EventLogs
  # Model for Event Logs
  class MonitoredEvent
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :monitorable, polymorphic: true

    field :account_hbx_id, type: String
    field :account_username, type: String
    field :subject_hbx_id, type: String
    field :event_category, type: Symbol
    field :event_time, type: DateTime
    field :login_session_id, type: String

    index({ account_hbx_id: 1 })
    index({ account_username: 1 })
    index({ subject_hbx_id: 1 })
    index({ event_category: 1 })
    index({ event_time: 1 })
    index({ login_session_id: 1 })

    def self.get_category_options(subject_hbx_id = nil)
      if subject_hbx_id.present?
        where(subject_hbx_id: subject_hbx_id).pluck(:event_category).uniq
      else
        pluck(:event_category).uniq
      end
    end

    def eligibility_details
      log = self.monitorable
      return {} unless json?(log&.payload)
      payload = JSON.parse(log.payload, symbolize_names: true)
      details = JSON.parse(self.attributes.to_json, symbolize_names: true)
      build_details(payload, details)
    end

    def build_details(payload, details)
      details[:current_state] = payload[:current_state] || ""
      details[:subject] = get_subject_name(subject) || ""
      details[:title] = payload[:title]&.gsub(/osse/i, "Hc4cc")&.gsub("Aca ", "")&.gsub("Eligibility ", "")&.upcase || ""
      details[:effective_on] = effective_on(payload)
      details[:detail] = event_name
      details[:event_time] = format_time_display(details[:event_time])
      attach_osse_application_period(details)
      details
    end

    def subject
      return @subject if defined?(@subject)
      @subject = GlobalID::Locator.locate(self.monitorable.subject_gid)
    end

    def event_name
      event = self.monitorable&.event_name
      event&.match(/[^.]+\z/)&.to_s&.titleize || ""
    end

    def effective_on(payload)
      datetime = payload.dig(:state_histories, -1, :effective_on)
      DateTime.parse(datetime.to_s) if datetime
    end

    def attach_osse_application_period(details)
      return unless event_category == :shop_osse_eligibility && subject.is_a?(BenefitSponsors::Organizations::GeneralOrganization)
      return if details[:effective_on].blank?

      application = osse_eligibile_application_for(details[:effective_on].year)
      return unless application
      details[:effective_on] = application.effective_period.min
    end

    def osse_eligibile_application_for(year)
      benefit_sponsorship = subject.active_benefit_sponsorship
      applications = benefit_sponsorship.benefit_applications.by_year(year).approved_and_terminated
      applications.select(&:osse_eligible?).last
    end

    def get_subject_name(subject)
      return subject.full_name if subject.instance_of?(Person)
      subject&.legal_name
    end

    def self.fetch_event_logs(params)
      query = {}
      %w[subject_hbx_id event_category].each do |param|
        query[param.to_sym] = params[param.to_sym] if params[param.to_sym].present?
      end

      query["$or"] = [{ account_hbx_id: params[:account] }, { account_username: params[:account] }] if params[:account].present?

      if params[:event_start_date].present?
        start_date = params[:event_start_date].to_date
        query[:event_time] ||= {}
        query[:event_time].merge!({ "$gte" => start_date.beginning_of_day })
      end

      if params[:event_end_date].present?
        end_date = params[:event_end_date].to_date
        query[:event_time] ||= {}
        query[:event_time].merge!({ "$lte" => end_date.end_of_day })
      end
      query.present? ? EventLogs::MonitoredEvent.where(query).order(:event_time.desc) : EventLogs::MonitoredEvent.all.order(:event_time.desc)
    end

    def json?(response)
      !JSON.parse(response).nil?
    rescue StandardError
      false
    end

    def self.to_csv(event_logs)
      CSV.generate(headers: true) do |csv|
        csv << [
          "Subject",
          "Eligibility",
          "Eligibility Status",
          "Effective On",
          "Event Details",
          "Performed By",
          "Time"
        ]

        event_logs.each do |event_log|
          details = event_log.eligibility_details
          performed_by =
            "#{details[:account_username]} (#{details[:account_hbx_id]})"

          csv << [
            details[:subject],
            details[:title].to_s.upcase,
            details[:current_state]&.titleize,
            details[:effective_on]&.strftime("%m/%d/%Y"),
            details[:detail],
            performed_by,
            details[:event_time]
          ]
        end
      end
    end

    def format_time_display(timestamp)
      timestamp.present? ? timestamp.in_time_zone('Eastern Time (US & Canada)') : ""
    end
  end
end
