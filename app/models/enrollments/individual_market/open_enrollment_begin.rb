# frozen_string_literal: true

class Enrollments::IndividualMarket::OpenEnrollmentBegin
  include EventSource::Command
  # Active IVL hbx enrollments
  # without a termination date in the current year
  # kind 'individual'
  # health || dental
  # effective on >= 1/1/2016
  # terminated_on.blank? || terminated_on > 12/31/2016
  # hbx sponsored benefit
  # Unassisted, Assisted, CSR Assisted, Catastrophic
  # Responsible party
  # :$or => [
  #   :terminated_on.lte => HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.end_on,
  #   :terminated_on => nil
  # ]
  # TODO: Move aged off people from immedidate coverage household to extended coverage household on the day new benefit coverage period begin.

  def initialize
    @logger = Logger.new("#{Rails.root}/log/ivl_open_enrollment_begin_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
  end

  def process_renewals
    @logger.info "Started process at #{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%m-%d-%Y %H:%M')}"
    @logger.info "Started async enrollment renewals at #{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%m-%d-%Y %H:%M')}"
    process_async_renewals
    @logger.info "Ended async enrollment renewals at #{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%m-%d-%Y %H:%M')}"
  end

  def process_async_renewals
    count = 0
    records.no_timeout.each do |family|
      count += 1
      @logger.info "Processsed #{count} IVL OSSE eligibilities" if (count % 1000) == 0
      trigger_event(count, family.to_global_id.uri)
    rescue StandardError => e
      @logger.error "ERROR: Failed Renewal for family hbx_id: #{family.hbx_assigned_id}; Exception: #{e.inspect}"
    end
  end

  def records
    query = kollection(HbxEnrollment::COVERAGE_KINDS, current_bcp)
    family_ids = HbxEnrollment.where(query).pluck(:family_id).uniq
    Family.where(:id.in => family_ids)
  end

  def trigger_event(family_index, gid)
    event = event('events.individual.open_enrollment.begin', attributes: payload_attributes(family_index, gid))
    if event.success?
      event.success.publish
    else
      @logger.error "ERROR: Event trigger failed: person hbx_id: #{person.hbx_id}"
    end
  end

  def payload_attributes(family_index, gid)
    {
      current_end_on: current_end_on,
      current_start_on: current_start_on,
      family_gid: gid,
      index_id: family_index,
      osse_enabled: osse_enabled,
      renewal_effective_on: renewal_effective_on
    }
  end

  def kollection(kind, coverage_period)
    {
      :kind.in => ['individual', 'coverall'],
      :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES - ["coverage_renewed", "coverage_termination_pending"]),
      :coverage_kind.in => kind,
      :effective_on => { "$gte" => coverage_period.start_on, "$lt" => coverage_period.end_on}
    }
  end

  def current_bs
    @current_bs ||= HbxProfile.current_hbx.benefit_sponsorship
  end

  def renewal_bcp
    @renewal_bcp ||= current_bs.renewal_benefit_coverage_period
  end

  def current_bcp
    @current_bcp ||= current_bs.current_benefit_coverage_period
  end

  def renewal_effective_on
    @renewal_effective_on ||= renewal_bcp.start_on
  end

  def current_start_on
    @current_start_on ||= current_bcp.start_on
  end

  def current_end_on
    @current_end_on ||= current_bcp.end_on
  end

  def osse_enabled
    @osse_enabled ||= renewal_bcp.eligibility_on(renewal_effective_on).present?
  end
end
