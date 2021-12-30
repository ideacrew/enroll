# frozen_string_literal: true

module Queries
  # Datatable query for eligibilities in outtstanding verification state
  class EligibilitiesOutstandingVerificationDatatableQuery

    attr_reader :search_string, :custom_attributes

    def datatable_search(string)
      @search_string = string
      self
    end

    def initialize(attributes)
      @custom_attributes = attributes
    end

    def person_search(search_string)
      klass if search_string.blank?
    end

    def build_scope
      family = klass
      family = family.send(@custom_attributes[:documents_uploaded]) if @custom_attributes[:documents_uploaded].present?
      if @custom_attributes[:custom_datatable_date_from].present? & @custom_attributes[:custom_datatable_date_to].present?
        family = family.eligibility_due_date_in_range(@custom_attributes[:custom_datatable_date_from].to_date, @custom_attributes[:custom_datatable_date_to].to_date)
      end
      #add other scopes here
      return family if @search_string.blank? || @search_string.length < 2

      family_scope = family.eligibility_determination_family_member_search(@search_string.to_s.strip)
      return family_scope if @order_by.blank?
      family_scope.order_by(@order_by)
    end

    def skip(num)
      build_scope.skip(num)
    end

    def limit(num)
      build_scope.limit(num)
    end

    def order_by(var)
      @order_by = var
      self
    end

    def klass
      return @klass if defined? @klass

      @klass = Family.eligibility_determination_outstanding_verifications
    end

    def size
      build_scope.count
    end

  end
end
