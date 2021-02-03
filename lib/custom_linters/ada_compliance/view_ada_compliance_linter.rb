# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'

# This class will check for basic Americans with Disabilities Act (ADA) compliance
# Current checks include:
# 1. Unique Input Attributes - Checks all "input" attributes for unique ["alt", "for", "id", "name", "placeholder"]
# 2. Alt Attribute Present - IMG
# 3. All links in view have unique text (I.E. Cannot have multiple links with simply text of "User")
# 4.
class ViewAdaComplianceLinter
  attr_accessor :stringified_view_files, :compliance_rules, :unique_html_attributes

  def initialize(stringified_view_files, compliance_rules)
    @stringified_view_files = stringified_view_files
    @compliance_rules = compliance_rules.with_indifferent_access
    @unique_html_attributes = compliance_rules[:unique_html_attributes]
  end

  def view_to_nokogiri(stringified_view)
    Nokogiri::HTML(stringified_view)
  end

  def ada_violation_in_view(stringified_view)
    nokogiri_doc = view_to_nokogiri(stringified_view)
    # Will return violations as arrays
    elements_missing_unique_attributes(nokogiri_doc) +
      images_missing_alt_text(nokogiri_doc) +
      links_have_unique_text?(nokogiri_doc) +
      tables_are_properly_scoped?(nokogiri_doc)
  end

  def views_ada_compliant?
    return true if stringified_view_files.blank?
    compliance_results = {}
    stringified_view_files.each do |view_filename, stringified_view|
      violations_in_view = ada_violation_in_view(stringified_view)
      compliance_results[view_filename] = violations_in_view if violations_in_view.present?
    end
    ada_violation_message(compliance_results) unless compliance_results.blank?
    compliance_results.blank?
  end

  def elements_missing_unique_attributes(nokogiri_doc)
    duplicated_elements = []
    return duplicated_elements if unique_html_attributes.blank?
    # TODO: Maybe need to do more than inputs
    doc_inputs = nokogiri_doc.css('input')
    unique_html_attributes.each do |attribute|
      attribute_values = doc_inputs.select { |input| input[attribute.to_sym] }.map { |input| input[attribute.to_sym] }
      next if attribute_values.compact.blank?
      next if attribute_values.uniq.size == attribute_values.size
      duplicated_elements << {attribute.to_sym => attribute_values}
    end
    return duplicated_elements if duplicated_elements.blank?
    [repeated_attributes_that_must_be_unique: duplicated_elements]
  end

  def images_missing_alt_text(nokogiri_doc)
    alt_text_results = []
    nokogiri_imgs = nokogiri_doc.css('img')
    return alt_text_results if nokogiri_imgs.blank?
    nokogiri_imgs.each do |img|
      # blank? will return true on both "" or nil (nil if no alt is present)
      alt_text_results << img[:src] if img[:alt].blank?
    end
    return alt_text_results if alt_text_results.blank?
    [images_missing_alt_text: alt_text_results]
  end

  def links_have_unique_text?(nokogiri_doc)
    # Second reject is to remove where the text is a blank string
    # TODO: Need to figure out if its vaid for links to have no text at all- just a link like <a href='link'></a>
    doc_links_text = nokogiri_doc.css('a').map(&:text).reject(&:blank?)
    return [] if doc_links_text.compact.blank?
    # No duplicated elements
    return [] if doc_links_text.uniq.size == doc_links_text.size
    [links_need_unique_text: doc_links_text.select { |doc_link_text| doc_links_text.count(doc_link_text) > 1 }]
  end

  # th elements must have scope='col' or scope='row' to be descriptive for those with
  # screen readers
  # Reference: https://webaim.org/techniques/tables/data
  def tables_are_properly_scoped?(nokogiri_doc)
    th_elements = nokogiri_doc.css('th').map
    return [] if th_elements.blank?
    # Returns array with text of th (I.E. "From", or "To")
    unscoped_th_elements = th_elements.select { |th| th[:scope].blank? }.compact.map(&:text)
    return [] if unscoped_th_elements.blank?
    [th_elements_need_scope: unscoped_th_elements]
  end

  def ada_violation_message(compliance_results)
    puts("The following are potential ADA violations in the view:")
    compliance_results.each { |key, values| puts("#{key}: #{values}") }
  end
end
