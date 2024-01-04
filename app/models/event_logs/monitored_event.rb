# frozen_string_literal: true
# Model for Event Logs
module EventLogs
  class MonitoredEvent
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :monitorable, polymorphic: true

    attr_accessor :outcome

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

    def self.fetch_event_logs(params)
      query = {}
      %w(subject_hbx_id event_category).each do |param|
        query[param.to_sym] = params[param.to_sym] if params[param.to_sym].present?
      end

      if params[:account].present?
        query["$or"] = [{ account_hbx_id: params[:account] }, { account_username: params[:account] }]
      end

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
  end
end
