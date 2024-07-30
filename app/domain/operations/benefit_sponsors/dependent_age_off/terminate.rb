# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
module Operations
  module BenefitSponsors
    module DependentAgeOff
      # Operation terminates enrollments with aged of dependents and creates new enrollments excluding the aged off dependents.
      class Terminate
        include Config::SiteConcern
        include Dry::Monads[:do, :result]

        def call(enrollment_hbx_id:, new_date:)
          shop_logger = yield initialize_logger("shop")
          parsed_date = yield parse_date(new_date)
          process_shop_dep_age_off(enrollment_hbx_id, shop_logger, parsed_date)
        end

        private

        def initialize_logger(market_kind)
          logger_file = Logger.new("#{Rails.root}/log/dependent_age_off_#{market_kind}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
          Success(logger_file)
        end

        def parse_date(new_date)
          date =
            case new_date
            when String
              Date.parse(new_date)
            when Date
              new_date
            end

          if date
            Success(date)
          else
            Failure("unknown date format")
          end
        end

        def process_shop_dep_age_off(enrollment_hbx_id, shop_logger, new_date) # rubocop:disable Metrics/CyclomaticComplexity
          cut_off_age = ::EnrollRegistry[:aca_shop_dependent_age_off].settings(:cut_off_age).item

          enrollment = ::HbxEnrollment.by_hbx_id(enrollment_hbx_id).first
          primary_person = enrollment.family.primary_person
          enr_members = enrollment.hbx_enrollment_members
          covered_family_members = enr_members.map(&:family_member)
          covered_members = covered_family_members.map(&:person)
          covered_members_ids = covered_members.flat_map(&:_id)
          relations = fetch_relation_objects(primary_person, covered_members_ids)

          if relations.present?
            aged_off_dependent_people = fetch_aged_off_people(relations, new_date, cut_off_age)
            if aged_off_dependent_people.present?
              dep_age_off_people_ids = aged_off_dependent_people.pluck(:id)
              age_off_family_members = covered_family_members.select{|fm| dep_age_off_people_ids.include?(fm.person_id)}.pluck(:id)
              age_off_enr_member = enr_members.select{|hem| age_off_family_members.include?(hem.applicant_id)}
              eligible_dependents = enr_members - age_off_enr_member
              terminate_and_reinstate_enrollment(enrollment, new_date, eligible_dependents)
              Success("Terminated dependent age-off enrollment for #{enrollment_hbx_id}")
            else
              Success("No age-off dependents found for #{enrollment_hbx_id}")
            end
          else
            Success("No relations found for #{enrollment_hbx_id}")
          end
        rescue StandardError => e
          shop_logger.error "Unable to terminate dependent age-off enrollment #{enrollment_hbx_id} due to #{e.message}"
          Failure("Unable to terminate dependent age-off for enrollment #{enrollment_hbx_id} due to #{e.message}")
        end

        def fetch_aged_off_people(relations, new_date, cut_off_age)
          relations.select{|dep| dep.relative.age_on(new_date - 1.day) >= cut_off_age}.flat_map(&:relative).reject{|p| p.age_off_excluded == true}
        end

        def fetch_relation_objects(primary_person, covered_members_ids)
          dependent_relations = ::EnrollRegistry[:aca_shop_dependent_age_off].setting(:relationship_kinds).item
          primary_person.person_relationships.where(:kind.in => dependent_relations).select{ |rel| (covered_members_ids.include? rel.relative_id)}
        end

        def terminate_and_reinstate_enrollment(enrollment, effective_date, eligible_dependents)
          reinstate_enrollment = ::Enrollments::Replicator::Reinstatement.new(enrollment, effective_date, nil, eligible_dependents).build
          reinstate_enrollment.save!
          return unless reinstate_enrollment.may_reinstate_coverage?
          reinstate_enrollment.force_select_coverage!
          reinstate_enrollment.begin_coverage! if reinstate_enrollment.may_begin_coverage? && reinstate_enrollment.effective_on <= TimeKeeper.date_of_record
          notifier = ::BenefitSponsors::Services::NoticeService.new
          notifier.deliver(recipient: reinstate_enrollment.employee_role, event_object: reinstate_enrollment, notice_event: "employee_plan_selection_confirmation_sep_new_hire")
        end
      end
    end
  end
end
