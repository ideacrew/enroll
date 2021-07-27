# frozen_string_literal: true

module Autocomplete
  extend ActiveSupport::Concern

  # Credit to Adam at dwellable.com.  See blog: https://www.dwellable.com/blog/Tech-Autocomplete-with-Rails-Mongoid

  included do
    field :autocomplete
    before_save :generate_autocomplete
  end

  # callback to populate :autocomplete
  def generate_autocomplete
    # Autocomplete will resolve on following attribute value
    # Note: Mongoid will not use index on this attribute

    return if @autocomplete_slug.blank?
    slug = @autocomplete_slug

    slug = slug.truncate(45, omission: "", separator: " ") if slug.length > 45
    write_attribute(:autocomplete, Autocomplete.normalize(slug))
  end

  # turn strings into autocomplete keys
  def self.normalize(string)
    string = string.downcase
    string = string.gsub("'", "")
    string = string.gsub("&", " and ")
    string = string.gsub(/[^a-z0-9 ]/, " ")
    string = string.gsub(/ the /, "")
    string = string.squish
    string = " #{string}"
    string
  end

  def self.search(query)
    query = normalize(query)
    return [] if query.blank?
    CensusEmployee.where(autocomplete: /#{query}/).asc(:autocomplete_slug).limit(10)
  end
end