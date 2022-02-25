module Forms
  class BulkActionsForAdmin
    include Acapi::Notifiers
    include Insured::FamiliesHelper

    attr_reader :result
    attr_reader :row
    attr_reader :family_id
    attr_reader :enrollment_id
    attr_reader :params
    attr_reader :config

    def initialize(*arguments)
      @params = arguments.extract_options!
      @result = {success: [], failure: []}
      @row = @params[:family_actions_id]
      @family_id = @params[:family_id]
      @enrollment_id = @params[:enrollment_id]
      @config = Rails.application.config.acapi
    end

    def cancel_enrollments
      cancelled_enrollments_transmission_info = {}
      @params.each do |key, value|
        if key.to_s[/cancel_hbx_.*/]
          hbx = HbxEnrollment.find(params[key.to_s])
          begin
            hbx.cancel_coverage! if hbx.may_cancel_coverage?
            @result[:success] << hbx
            cancelled_enrollments_transmission_info[hbx.id] = params.key?("transmit_hbx_#{hbx.id.to_s}") ? true : false
          rescue
            @result[:failure] << hbx
          end
        end
      end
      cancelled_enrollments_transmission_info.each { |hbx_id, transmit_flag| handle_edi_transmissions(hbx_id, transmit_flag) }
    end

    def terminate_enrollments
      terminated_enrollments_transmission_info = {}
      @params.each do |key, value|
        if key.to_s[/terminate_hbx_.*/]
          hbx = HbxEnrollment.find(params[key.to_s])
          begin
            termination_date = Date.strptime(params["termination_date_#{value}"], "%m/%d/%Y")
            # IVL enrollments go automatically to coverage_terminated
            if termination_date >= ::TimeKeeper.date_of_record && hbx.is_shop?
              hbx.schedule_coverage_termination!(termination_date) if hbx.may_schedule_coverage_termination?
            elsif hbx.may_terminate_coverage?
              hbx.terminate_coverage!(termination_date)
            end
            @result[:success] << hbx
            terminated_enrollments_transmission_info[hbx.id] = params.key?("transmit_hbx_#{hbx.id.to_s}") ? true : false
          rescue
            @result[:failure] << hbx
          end
        end
      end
      terminated_enrollments_transmission_info.each { |hbx_id, transmit_flag| handle_edi_transmissions(hbx_id, transmit_flag) }
    end

    # drop action
    def drop_enrollment_members
      if @params.keys.to_s[/terminate_member_.*/]
        hbx_enrollment = HbxEnrollment.find(@enrollment_id)
        begin
          terminate_date = Date.strptime(@params["termination_date_#{hbx_enrollment.id}"], "%m/%d/%Y")
          dropped_enr_members = @params.select{|string| string.include?("terminate_member")}.values

          dropped_member_info = []
          dropped_enr_members.each do |member_id|
            hem = hbx_enrollment.hbx_enrollment_members.where(id: member_id).first
            person = hem.family_member.person
            dropped_member_info << {hbx_id: member_id, full_name: person.full_name, terminated_on: terminate_date}
          end

          all_enr_members = hbx_enrollment.hbx_enrollment_members
          eligible_members = all_enr_members.reject!{ |member| dropped_enr_members.include?(member.id.to_s) }
          effective_date = Insured::Factories::SelfServiceFactory.find_enrollment_effective_on_date(::TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), hbx_enrollment.effective_on).to_date
          if hbx_enrollment.applied_aptc_amount > 0
            tax_household = hbx_enrollment.family.active_household.latest_tax_household_with_year(hbx_enrollment.effective_on.year)
            applied_aptc = tax_household.monthly_max_aptc(hbx_enrollment, effective_date) if tax_household
          end

          applied_aptc = applied_aptc.present? ? applied_aptc : 0

          if hbx_enrollment.may_terminate_coverage?
            hbx_enrollment.terminate_coverage!
            hbx_enrollment.update_attributes!(terminated_on: terminate_date)
          end

          reinstatement = Enrollments::Replicator::Reinstatement.new(hbx_enrollment, effective_date, applied_aptc, eligible_members).build

          previous_enrollment_state = hbx_enrollment.aasm_state
          reinstatement.update_attributes!(aasm_state: previous_enrollment_state)

          # extra update in the event enrollment gets updated in the reinstatement
          hbx_enrollment.update_attributes!(terminated_on: terminate_date)
          hbx_enrollment.save!

          reinstatement.save!

          transmit_drop = params.key?("transmit_hbx_#{hbx_enrollment.id.to_s}") ? true : false
          handle_edi_transmissions(hbx_enrollment.id, transmit_drop)

          dropped_member_info.each do |member_info|
            @result[:success] << member_info
          end
        rescue => error
          @result[:failure] << hbx_enrollment
        end
      end
    end

    def transition_family_members
      # Handle transitions here
      params.each do |key, value|
        if key.to_s[/transition_user_.*/]
          person = Person.find(value)
          market_kind = params["transition_market_kind_#{value}"]
          effective_date = Date.strptime(params["transition_effective_date_#{value}"], "%m/%d/%Y")
          transition_reason = params["transition_reason_#{value}"]

          current_active_role = person.individual_market_transitions.all.last
          # need to update current transition instance end date to new transition start date less 1 day
          current_active_role.update_attributes!(effective_ending_on: effective_date - 1.days)

          person.individual_market_transitions.build(role_type: market_kind, effective_starting_on: effective_date, reason_code: transition_reason, submitted_at: ::TimeKeeper.datetime_of_record)
          begin
            person.save!
            @result[:success] << person
            # creation of roles for a person
            @family = Family.find(params[:family])
            person.consumer_role.move_to_expired if person.consumer_role.present? && person.is_resident_role_active?
            build_consumer_role(person, @family) if person.is_consumer_role_active? && !person.consumer_role.present?
            build_resident_role(person, @family) if person.is_resident_role_active? && !person.resident_role.present?

            # creation of SEP?
            qle = QualifyingLifeEventKind.find(params[:qle_id])
            effective_kind = qle.effective_on_kinds.first
            special_enrollment_period = @family.special_enrollment_periods.new(effective_on_kind: effective_kind)
            special_enrollment_period.selected_effective_on = effective_date
            special_enrollment_period.qualifying_life_event_kind = qle
            special_enrollment_period.qle_on = effective_date
            special_enrollment_period.save
          rescue
            @result[:failure] << person
          end
        end
      end
    end

    private

    def eligible_to_transmit(hbx)
      return true unless hbx.is_shop? || hbx.sponsored_benefit_package_id.present?

      benefit_package = hbx.sponsored_benefit_package
      benefit_application = benefit_package.benefit_application
      quiet_period = benefit_application.enrollment_quiet_period
      transition_at = hbx.workflow_state_transitions.where(:to_state.in => ["coverage_terminated","coverage_canceled", "coverage_termination_pending"]).last.transition_at
      ["enrollment_eligible", "active", "terminated","expired", "termination_pending"].include?(benefit_application.aasm_state.to_s) && transition_at.in_time_zone("UTC") >= quiet_period.max
    end

    def handle_edi_transmissions(hbx_id, transmit_flag) #transmit_flag = true/false based on wheather the user elected to transmit.
      hbx = HbxEnrollment.find(hbx_id)
      ### Handle EDI transmission here ###

      return true unless eligible_to_transmit(hbx)

      notify(
        "acapi.info.events.hbx_enrollment.terminated",
        {
          :reply_to => "#{config.hbx_id}.#{config.environment_name}.q.glue.enrollment_event_batch_handler",
          "hbx_enrollment_id" => hbx.hbx_id,
          "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
          "is_trading_partner_publishable" => transmit_flag
        }
      )
    end
  end
end
