# frozen_string_literal: true

date = Time.zone.today

if date.day > 15
  window_start = Date.new(date.year,date.month,16)
  window_end = Date.new(date.next_month.year,date.next_month.month,15)
  window = (window_start..window_end)
elsif date.day <= 15
  window_start = Date.new((date - 1.month).year,(date - 1.month).month,16)
  window_end = Date.new(date.year,date.month,15)
  window = (window_start..window_end)
end

start_on_date = window.end.next_month.beginning_of_month.to_time.utc.beginning_of_day

product_cache = BenefitMarkets::Products::Product.all.inject({}) do |cache_hash, product|
  cache_hash[product.id] = product
  cache_hash
end

def find_renewed_sponsorships(start_on_date)
  BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(
    {:benefit_applications =>
      { :$elemMatch => {
        :"effective_period.min" => start_on_date,
        :predecessor_id => {"$ne" => nil},
        :aasm_state.in => [:enrollment_open, :enrollment_closed, :enrollment_eligible, :enrollment_extended, :active]
      }}}
  )
end

def matching_plan_details(enrollment, other_hbx_enrollment, product_cache)
  return false if other_hbx_enrollment.product_id.blank?
  new_plan = product_cache[enrollment.product_id]
  old_plan = product_cache[other_hbx_enrollment.product_id]
  return false  if old_plan.kind == "dental" && old_plan.active_year == (Time.zone.today.year - 1).to_s && Settings.site.key.to_s == "cca"
  (old_plan.issuer_profile_id == new_plan.issuer_profile_id) && (old_plan.active_year == new_plan.active_year - 1) && (old_plan.kind == new_plan.kind)
end

def initial_or_renewal(enrollment,product_cache,ben_app)
  return "initial" if ben_app.predecessor_id.blank?
  renewal_enrollments = enrollment.family.hbx_enrollments.select do |hbx_enrollment|
    next if hbx_enrollment.sponsored_benefit_package_id.blank?
    hbx_enrollment.sponsored_benefit_package.benefit_application.id == ben_app.predecessor_id
  end

  reject_statuses = HbxEnrollment::CANCELED_STATUSES + HbxEnrollment::WAIVED_STATUSES + ['unverified void']
  renewal_enrollments_no_cancels_waives = renewal_enrollments.reject{|ren| reject_statuses.include?(ren.aasm_state.to_s)}
  renewal_enrollments_no_terms = renewal_enrollments_no_cancels_waives.reject do |ren|
    ['coverage_terminated', 'coverage_termination_pending'].include?(ren.aasm_state.to_s) && ren.terminated_on.present? && ren.terminated_on < (enrollment.effective_on - 1.day)
  end
  if renewal_enrollments_no_terms.any?{|ren| matching_plan_details(enrollment,ren,product_cache)}
    "renewal"
  else
    "initial"
  end
end

renewed_sponsorships = find_renewed_sponsorships(start_on_date)
total_count = renewed_sponsorships.count
sponsorships_per_iteration = 100.0
number_of_iterations = (total_count / sponsorships_per_iteration).ceil
counter = 0

initial_file = File.open("policies_to_pull_ies.txt","w")
renewal_file = File.open("policies_to_pull_renewals.txt","w")

while counter < number_of_iterations
  offset_count = sponsorships_per_iteration * counter
  renewed_sponsorships.no_timeout.limit(100).offset(offset_count).each do |bs|
    selected_application = bs.renewal_benefit_application

    next if selected_application.blank?

    benefit_packages = selected_application.benefit_packages

    enrollment_ids = []
    benefit_packages.each do |benefit_package|
      employer_enrollment_query = ::Queries::NamedEnrollmentQueries.find_simulated_renewal_enrollments(benefit_package.sponsored_benefits, start_on_date)
      enrollment_cache_ids = employer_enrollment_query.inject([]) do |enr_cache_ids, id|
        enr_cache_ids << id
        enr_cache_ids
      end
      enrollment_ids << enrollment_cache_ids
    end
    puts "Fein: #{bs.fein}"
    puts "enrollments count: #{enrollment_ids.flatten.count} and enrollment_ids: #{enrollment_ids.flatten}"
    enrollment_ids.flatten.each do |enrollment_hbx_id|
      puts enrollment_hbx_id
      enrollment = HbxEnrollment.by_hbx_id(enrollment_hbx_id).first
      puts "#{enrollment.hbx_id} has no plan" if enrollment.product.blank?
      case initial_or_renewal(enrollment,product_cache,selected_application)
      when 'initial'
        initial_file.puts(enrollment_hbx_id)
      when 'renewal'
        renewal_file.puts(enrollment_hbx_id)
      end
    end
  end
  counter += 1
end

initial_file.close
renewal_file.close
