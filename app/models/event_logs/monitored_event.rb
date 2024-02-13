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
      parsed = JSON.parse(log.payload, symbolize_names: true)
      details = JSON.parse(self.attributes.to_json, symbolize_names: true)
      datetime = parsed.dig(:state_histories, 0, :effective_on)
      effective_on = DateTime.parse(datetime.to_s)&.strftime("%d/%m/%Y") if datetime
      subject = get_subject_name(log.subject_gid)
      detail = log.event_name&.match(/[^.]+\z/)&.to_s&.titleize
      build_details(parsed, details, effective_on, detail, subject)
    end

    def build_details(parsed, details, effective_on, detail, subject)
      details[:current_state] = parsed[:current_state] || ""
      details[:subject] = subject || ""
      details[:title] = parsed[:title]&.gsub(/osse/i, "Hc4cc")&.gsub("Aca ", "")&.gsub("Eligibility ", "")&.upcase || ""
      details[:effective_on] = effective_on || ""
      details[:detail] = detail || ""
      details
    end

    def get_subject_name(gid)
      subject = GlobalID::Locator.locate(gid)
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

  end
end
