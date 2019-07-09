# frozen_string_literal: true

module BenefitSponsors
  module Exporters
    class CensusEmployeeExport
      include ActionView::Helpers::NumberHelper

      attr_reader :employer_profile, :site_key
      attr_accessor :headers, :type_of_action, :dep_count

      def initialize(employer_profile, options = {})
        @employer_profile = employer_profile
        @site_key = fetch_site_key
        @dep_count = dependent_count
        @type_of_action = options[:action]
        @headers = config_based_headers
      end

      def config_based_headers
        site_key == :dc ? dc_csv_headers : census_employee_details_headers
      end

      def dc_csv_headers
        census_employee_details_headers + contribution_headers + dependent_dob_headers(type_of_action)
      end

      def to_csv
        CSV.generate(headers: true) do |csv|
          csv << (["#{Settings.site.long_name} Employee Census Template"] + 6.times.collect{ "" } + [TimeKeeper.date_of_record] + 5.times.collect{ "" } + ["1.1"])
          csv << headers
          census_employee_roster.each do |census_employee|
            personal_details = personal_headers(census_employee)
            employee_details = employeement_headers(census_employee)
            benefit_group_details = benefit_group_assignment_details(census_employee)
            address_details = primary_location_details(census_employee)
            contribution_details = total_premium(census_employee)
            dependet_dob_details = append_dependent_dob(census_employee)
            csv << ["", "employee"] + personal_details + employee_details + benefit_group_details + address_details + contribution_details + dependet_dob_details
          end
        end
      end

      def personal_headers(record)
        personal_info_headers = []
        %w[last_name first_name middle_name name_sfx email_address ssn dob gender].each do |attribute|
          personal_info_headers.push record.send(attribute)
        end
        personal_info_headers
      end

      def primary_location_details(record)
        if record.address.present?
          record.address.to_a
        else
          6.times.collect{ "" }
        end
      end

      def employeement_headers(census_employee)
        employeement = []
        employeement.push(
          census_employee.hired_on.present? ? census_employee.hired_on.strftime("%m/%d/%Y") : "",
          census_employee.aasm_state.humanize.downcase,
          census_employee.employment_terminated_on.present? ? census_employee.employment_terminated_on.strftime("%m/%d/%Y") : "",
          census_employee.is_business_owner ? "yes" : "no"
        )
        employeement
      end

      def benefit_group_assignment_details(census_employee)
        bga = []
        active_assignment = census_employee.active_benefit_group_assignment
        if active_assignment
          health_enrollment = pull_enrollment_state_by_kind(active_assignment, "health")
          dental_enrollment = pull_enrollment_state_by_kind(active_assignment, "dental")
          bga.push(
            active_assignment.benefit_group.title,
            "dental: #{dental_enrollment}  health: #{health_enrollment}",
            active_assignment.try(:benefit_application).try(:start_on)
          )
        else
          bga += 3.times.collect{ "" }
        end
        bga
      end

      def append_dependent_dob(census_employee)
        dob_rows = []
        census_employee.census_dependents.each do |dependent|
          dob_rows.push(
            dependent.dob.present? ? dependent.dob.strftime("%m/%d/%Y") : ""
          )
        end
        dependent_count_diff = (dependent_count - dob_rows.length).times.collect{ "" }
        dob_rows + dependent_count_diff
      end

      def pull_enrollment_state_by_kind(active_bga, coverage_kind)
        active_bga.try(:hbx_enrollments).detect{|enrollment| enrollment.coverage_kind == coverage_kind}.try(:aasm_state).try(:humanize).try(:downcase)
      end

      def total_premium(record)
        bga = record.active_benefit_group_assignment
        if bga
          enrollments = bga.try(:hbx_enrollments)
          return ["", ""] if enrollments.nil?

          health_selected_enrollment = pull_selected_enrollment(enrollments, "health")
          dental_selected_enrollment = pull_selected_enrollment(enrollments, "dental")
          health_cost = number_with_precision(health_selected_enrollment.total_employee_cost, precision: 2)
          dental_cost = number_with_precision(dental_selected_enrollment.total_employee_cost, precision: 2)
        else
          health_cost, dental_cost = 2.times.collect{ "" }
        end
        [health_cost, dental_cost]
      end

      def pull_selected_enrollment(enrollments, coverage_kind)
        enrollments.detect{|enrollment| enrollment.coverage_kind == coverage_kind && enrollment.aasm_state == "coverage_selected"}
      end

      def census_employee_details_headers
        [
          "Family ID # (to match family members to the EE & each household gets a unique number)(Optional)",
          "Relationship (EE, Spouse, Domestic Partner, or Child)",
          "Last Name",
          "First Name",
          "Middle Name or Initial (Optional)",
          "Suffix (Optional)",
          "Email Address",
          "SSN / TIN (Required for EE & enter without dashes)",
          "Date of Birth (MM/DD/YYYY)",
          "Gender",
          "Date of Hire",
          "Status(Optional)",
          "Date of Termination (Optional)",
          "Is Business Owner?",
          "Benefit Group(Optional)",
          "Enrollment Type(Optional)",
          "Plan Year (Optional)",
          "Address Kind(Optional)",
          "Address Line 1(Optional)",
          "Address Line 2(Optional)",
          "City(Optional)",
          "State(Optional)",
          "Zip(Optional)"
        ]
      end

      def contribution_headers
        %w[Total\ Monthly\ Premium\ Health Total\ Monthly\ Premium\ Dental]
      end

      def dependent_dob_headers(type_of_action)
        return [] if type_of_action == "upload"

        dep_headers = []
        dep_count.times do |i|
          dep_headers << "Dep#{i + 1} DOB"
        end
        dep_headers
      end

      def dependent_count
        dependent = []
        census_employee_roster.each do |census_employee|
          next if census_employee.census_dependents.blank?

          dependent.push census_employee.census_dependents.count
        end
        dependent.max.nil? ? 0 : dependent.max
      end

      private

      def fetch_site_key
        BenefitSponsors::ApplicationController.current_site.site_key
      end

      def census_employee_roster
        @census_employee_roster ||= employer_profile.census_employees.sorted
      end
    end
  end
end
