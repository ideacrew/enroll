# frozen_string_literal: true

module Operations
  class BatchHandler
    include EventSource::Command

    attr_reader :batch_size, :record_kind

    BATCH_SIZE = 1000

    def initialize(params)
      @batch_size = params[:batch_size] || BATCH_SIZE
      @record_kind = params[:record_kind]
    end

    def trigger_batch_requests
      validate
      total_records = query.count

      batch = 0
      offset = 0
      loop do
        trigger_batch_request(offset)
        offset += batch_size
        batch += 1

        break if offset > total_records
      end
      logger.info ".trigger_batch_request sent #{batch} batch requests"
    end

    def trigger_batch_request(offset)
      logger.info ".trigger_batch_request with offset: #{offset}"
      event =
        event(
          "events.batch_process.batch_event_process_requested",
          attributes: batch_request_options(offset)
        )
      event.success.publish if event.success?
    end

    def batch_request_options(offset)
      {
        batch_handler: self.class.name,
        record_kind: :individual,
        batch_options: {
          batch_size: batch_size,
          offset: offset
        }
      }
    end

    def process_batch_request(options)
      logger.info ".process_batch_request with #{options.inspect} started"
      validate
      query
        .offset(options[:offset].to_i)
        .limit(options[:batch_size].to_i)
        .no_timeout
        .each { |record| process_record(record) }
    end

    def validate
      raise NotImplementedError.new("This is a documentation only interface.")
    end

    def process_record(record)
      raise NotImplementedError.new("This is a documentation only interface.")
    end

    def query
      raise NotImplementedError.new("This is a documentation only interface.")
    end

    def logger
      return @logger if defined?(@logger)
      @logger =
        Logger.new(
          "#{Rails.root}/log/on_#{self.class.name.demodulize.underscore}_#{TimeKeeper.date_of_record.strftime("%Y_%m_%d")}.log"
        )
    end
  end

  module Eligible
    # Configurations for the Eligibility
    class EligibilityBatchHandler < ::Operations::BatchHandler
      attr_reader :effective_date

      def initialize(params)
        super

        @effective_date = params[:effective_date]&.to_date
      end

      def validate
        errors = []
        errors << "record_kind missing" unless record_kind
        errors << "effective_date missing" unless effective_date

        raise StandardError, errors.join(",") if errors.present?
      end

      def batch_request_options(offset)
        default_options = super
        default_options.merge(effective_date: effective_date)
      end

      def process_record(record)
        subject = find_subject(record)
        logger.info "processing hbx_id: #{subject.hbx_id} of #{subject.class.to_s}"

        event =
          event(
            "events.eligible.create_default_eligibility",
            attributes: {
              subject_gid: subject.to_global_id.uri,
              effective_date:
                (effective_date || TimeKeeper.date_of_record.beginning_of_year),
              evidence_key: evidence_key
            }
          )
        if event.success?
          event.success.publish
        else
          logger.error "ERROR: Event trigger failed: role hbx_id: #{subject.hbx_id}"
        end
      end

      def find_subject(record)
        return record unless individual

        if record.has_active_resident_role?
          record.resident_role
        elsif record.has_active_consumer_role?
          record.consumer_role
        end
      end

      def query
        if individual
          ::Person.active.where(
            {
              "$or" => [
                { "consumer_role" => { "$exists" => true } },
                { "resident_role" => { "$exists" => true } }
              ]
            }
          )
        else
          ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.all
        end
      end

      def individual
        record_kind.to_s == "individual"
      end

      def evidence_key
        individual ? :ivl_osse_evidence : :shop_osse_evidence
      end
    end
  end
end
