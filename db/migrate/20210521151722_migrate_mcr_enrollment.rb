# frozen_string_literal: true

require 'aca_entities/ffe/operations/mcr_to/enrollment'
require 'aca_entities/ffe/transformers/mcr_to/enrollment'

# rubocop:disable Metrics/AbcSize, Lint/ShadowedArgument, Lint/DuplicateBranch
# MigrateMcrEnrollment
class MigrateMcrEnrollment < Mongoid::Migration
  def self.up
    self.enrollments_array.each do |payload|
      transform_enrollment = ::AcaEntities::FFE::Operations::McrTo::Enrollment.new.call(payload.first)
      if transform_enrollment.success?
        enrollment_hash = transform_enrollment.success.to_h.deep_stringify_keys!
      else
        puts "enrollment hash: #{payload.first} | failed: #{transform_enrollment.failure}"
        next
      end
      sanitized_hash = sanitize_enrollment_hash(enrollment_hash)
      create_hbx_enrollment(sanitized_hash)
    end
  end

  def self.sanitize_enrollment_hash(hash)
    hash["external_id"] = hash["hbx_id"]
    hash["hbx_id"] = ""

    hash["kind"] = hash["market_place_kind"]
    hash.delete("market_place_kind")

    hash["enrollment_kind"] = hash["enrollment_period_kind"]
    hash.delete("enrollment_period_kind")

    hash["coverage_kind"] = hash["product_kind"]
    hash.delete("product_kind")

    hash["product_reference"].delete("issuer_profile_reference")
    hash["product_reference"]["benefit_market_kind"] = "aca_individual"
    hash["product_reference"]["kind"] = hash["product_reference"]["product_kind"]
    product_hash = hash["product_reference"].slice("hios_id", "benefit_market_kind", "kind")
    active_year = hash["product_reference"]["active_year"]

    product = find_product(product_hash, active_year)
    hash["product_id"] = product.id
    hash.delete("product_reference")

    # hash["issuer_profile_id"] = find_issuer_profile(hash["issuer_profile_reference"]).id
    hash.delete("issuer_profile_reference")
    hash["issuer_profile_id"] = product.issuer_profile.id

    family = find_family(hash["family_hbx_id"])
    hash["family_id"] = family.id
    hash.delete("family_hbx_id")

    # TODO: Check for incoming data
    # hash["special_enrollment_period_id"] = build_special_enrollment_period(family, hash["special_enrollment_period_reference"]).id
    hash.delete("special_enrollment_period_reference")

    hash["consumer_role_id"] = family.primary_person.consumer_role.id
    hash["household_id"] = family.active_household.id

    # TODO: check this id need?
    # hash["coverage_household_id"] = family.active_household.id

    # TODO: Add these fields
    # hash["predecessor_enrollment_id"] =
    # hash["enrollment_signature"] =
    # hash["rating_area_id"]
    hash["external_enrollment"] = false

    benefit_coverage_period = find_benefit_coverage_period(hash["effective_on"])
    hash["benefit_coverage_period_id"] = benefit_coverage_period.id
    hash.delete("benefit_coverage_period_reference")

    benefit_package = find_benefit_package(benefit_coverage_period, hash["benefit_package_reference"])
    hash["benefit_package_id"] = benefit_package.id
    hash.delete("benefit_package_reference")

    hash["hbx_enrollment_members"] = sanitize_enrollment_member_hash(family, hash["hbx_enrollment_members"])
    hash
  end

  def self.find_benefit_package(benefit_coverage_period, _package_hash)
    benefit_coverage_period.benefit_packages.first
  end

  def self.find_benefit_coverage_period(effective_on)
    sponsorship = HbxProfile.current_hbx.try(:benefit_sponsorship)
    sponsorship.benefit_coverage_periods.where(start_on: effective_on.beginning_of_year).first
  end

  def self.build_special_enrollment_period(family, sep_hash); end

  def self.sanitize_enrollment_member_hash(family, member_hash)
    member_hash.inject([]) do |members, m_hash|
      applicant = find_family_member(family, m_hash["family_member_reference"])
      m_hash["applicant_id"] = applicant.id
      m_hash.delete("family_member_reference")
      # TODO: .
      # hash["tobacco_use"]
      members << m_hash
    end
  end

  def self.find_family(external_id)
    result = Operations::Families::Find.new.call(ext_app_id: external_id)
    result.success? ? result.success : result
  end

  def self.find_family_member(family, fm_hash)
    # external_id = fm_hash["person_hbx_id"]
    # person = Person.where(ext_app_id: external_id).first
    person = Person.where(first_name: fm_hash["first_name"], last_name: fm_hash["last_name"]).first
    family.family_members.active.select { |fam| fam.person_id == person.id}.first


    # TODO: verify coverage household
    # coverage_household = family.active_household.immediate_family_coverage_household
    # unless coverage_household.coverage_household_members.any? {|c_mem| c_mem.family_member_id == family_member.id}
    #   raise "coverage household not found"
    # else
    #   family_member
    # end
    # result = Operations::Families::FindFamilyMember.new.call(ext_app_id: external_hbxid)
    # result.success? ? result.success : result
  end

  def self.find_product(product_hash, year)
    #TODO: for testing, revert
    product_hash = {"hios_id" => "94506DC0390008-01", "benefit_market_kind" => "aca_individual", "kind" => "health"}
    year = 2021
    result = Operations::HbxEnrollments::FindProduct.new.call(product_hash, year)
    result.success? ? result.success : result
  end

  # def self.find_issuer_profile(hash)
  #   result = Operations::HbxEnrollments::FindIssuerProfile.new.call(hash)
  #   result.success? ? result.success : result
  # end

  def self.create_hbx_enrollment(sanitized_hash)
    result = Operations::HbxEnrollments::Find.new.call({external_id: sanitized_hash["external_id"]})
    return result.success if result.success?

    hbx_enrollment = HbxEnrollment.new(sanitized_hash.except("hbx_enrollment_members"))
    hbx_enrollment.hbx_enrollment_members = hbx_enrollment_members(sanitized_hash)
    hbx_enrollment.aasm_state = 'coverage_selected'
    hbx_enrollment.save
  end

  def self.hbx_enrollment_members(sanitized_hash)
    sanitized_hash["hbx_enrollment_members"].inject([]) do |members, hbx_enrollment_member|
      members << HbxEnrollmentMember.new(hbx_enrollment_member)
    end
  end

  def self.file_path
    case Rails.env
    when 'development'
      "spec/test_data/transform_example_payloads/enrollment.json"
    when 'test'
      "spec/test_data/transform_example_payloads/enrollment.json"
    end
  end

  def self.enrollments_array
    JSON.parse(File.open(Pathname.pwd.join(file_path)).read)
  end

  def self.down; end
end
# rubocop:enable Metrics/AbcSize, Lint/ShadowedArgument, Lint/DuplicateBranch
