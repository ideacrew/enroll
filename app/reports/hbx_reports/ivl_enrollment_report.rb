# frozen_string_literal: true

#Ivl Enrollment Recon Report
require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class IvlEnrollmentReport < MongoidMigrationTask
  def migrate
    if ENV['purchase_date_start'].blank? && ENV['purchase_date_end'].blank?
      # Purchase dates are from 10 weeks to todays date
      purchase_date_start = (Time.now - 30.days).beginning_of_day
      purchase_date_end = Time.now.end_of_day
    else
      purchase_date_start = Time.strptime(ENV['purchase_date_start'],'%m/%d/%Y').beginning_of_day
      purchase_date_end = Time.strptime(ENV['purchase_date_end'],'%m/%d/%Y').end_of_day
    end
    Dir.mkdir("hbx_report") unless File.exist?("hbx_report")

    qs = Queries::PolicyAggregationPipeline.new
    qs.filter_to_shopping_completed
    qs.eliminate_family_duplicates

    qs.add({ "$match" => {"policy_purchased_at" => {"$gte" => purchase_date_start, "$lte" => purchase_date_end}}})
    glue_list = File.read("all_glue_policies.txt").split("\n").map(&:strip) if File.exist?("all_glue_policies.txt")
    enrollment_ids = []

    qs.evaluate.each do |r|
      enrollment_ids << r['hbx_id']
    end

    enrollment_ids_final = []
    enrollment_ids.each{|id| (enrollment_ids_final << id)}
    writing_on_csv(enrollment_ids_final, glue_list)
    puts "Ivl Enrollment Report Generated" unless Rails.env.test?
  end

  def writing_on_csv(enrollment_ids_final, glue_list)
    ivl_headers = ['Enrollment GroupID', 'Purchase Date', 'Coverage Start', 'Coverage End', 'Member Coverage Start On', 'Member Coverage End On', 'Coverage Kind', 'Enrollment State',
                   'Subscriber HBXID', 'Subscriber First Name','Subscriber Last Name', "Enrollee's Hbx ID", 'Policy Plan Name', 'HIOS ID', 'Policy Variant','Premium Subtotal',
                   'ER Contribution', 'Applied APTC Amount', 'APTC Pct', 'Total Responsible Amount (Member Premium)', 'Family Size', 'Enrollment Reason', 'In Glue', 'OSSE Eligible', 'Monthly Subsidy Amount']

    file_name = "#{Rails.root}/hbx_report/ivl_enrollment_report.csv"
    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << ivl_headers
      enrollment_ids_final.each do |id|

        hbx_enrollment = HbxEnrollment.by_hbx_id(id).first
        next unless hbx_enrollment.is_ivl_by_kind?
        enrollment_reason = enrollment_kind(hbx_enrollment)
        policy_plan_name = hbx_enrollment.product.title
        osse_eligible = (hbx_enrollment.eligible_child_care_subsidy > 0 ? "Yes" : "No")
        enrollment_member_ids = hbx_enrollment.hbx_enrollment_members.map(&:hbx_id).join(', ')
        subscriber = hbx_enrollment.subscriber
        if subscriber.present? && subscriber.person.present?
          subscriber_hbx_id = subscriber.hbx_id
          first_name = subscriber.person.first_name
          last_name = subscriber.person.last_name
        end
        in_glue = glue_list.include?(id) if glue_list.present?
        csv << [hbx_enrollment.hbx_id,hbx_enrollment.created_at,hbx_enrollment.effective_on,hbx_enrollment.terminated_on, hbx_enrollment.primary_hbx_enrollment_member.coverage_start_on, hbx_enrollment.primary_hbx_enrollment_member.coverage_end_on,
                hbx_enrollment.coverage_kind,hbx_enrollment.aasm_state,subscriber_hbx_id,first_name,last_name, enrollment_member_ids, policy_plan_name,
                hbx_enrollment.product.hios_id, hbx_enrollment.product.csr_variant_id, hbx_enrollment.total_premium,hbx_enrollment.total_employer_contribution,
                hbx_enrollment.applied_aptc_amount, hbx_enrollment.elected_aptc_pct, hbx_enrollment.total_employee_cost,hbx_enrollment.hbx_enrollment_members.size,
                enrollment_reason,in_glue, osse_eligible, hbx_enrollment.eligible_child_care_subsidy]
      rescue StandardError => e
        @logger = Logger.new("#{Rails.root}/log/ivl_enrollment_report_error.log")
        (@logger.error { "Could not add the hbx_enrollment's information on to the CSV for eg_id:#{id}, subscriber_hbx_id:#{subscriber_hbx_id}, #{e.inspect}" }) unless Rails.env.test?

      end
    end
  end

  def enrollment_kind(hbx_enrollment)
    case hbx_enrollment.enrollment_kind
    when "special_enrollment"
      hbx_enrollment.special_enrollment_period.qualifying_life_event_kind.reason
    when "open_enrollment"
      hbx_enrollment.eligibility_event_kind
    end
  end
end