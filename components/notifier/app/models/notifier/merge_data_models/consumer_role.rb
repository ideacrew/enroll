module Notifier
  class MergeDataModels::ConsumerRole
    include Virtus.model
    include ActiveModel::Model
    include Notifier::MergeDataModels::TokenBuilder

    attribute :notice_date, String
    attribute :first_name, String
    attribute :last_name, String
    attribute :mailing_address, MergeDataModels::Address
    # attribute :coverage_begin_date, Date
    attribute :addresses, Array[MergeDataModels::Address]
    attribute :enrollments, Array[MergeDataModels::Enrollment]
    attribute :subject_line, String
    attribute :documents_needed, Boolean
    attribute :current_health_enrollments, Array

    def self.stubbed_object
      notice = Notifier::MergeDataModels::ConsumerRole.new({
                                                                  notice_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
                                                                  first_name: 'John',
                                                                  last_name: 'Whitmore',
                                                                  subject_line: 'Hello world'
                                                                  # coverage_begin_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
                                                              })
      notice.mailing_address = Notifier::MergeDataModels::Address.stubbed_object
      notice.addresses = [ notice.mailing_address ]
      notice.enrollments = [Notifier::MergeDataModels::Enrollment.stubbed_object]
      notice
    end

    def collections
      %w{addresses enrollments}
    end

    def conditions
      %w{uqhp_present? aqhp_present? uqhp_and_dental_present? aqhp_and_dental_present? documents_needed? }
    end

    def uqhp_present?
      true #self.person.primary_family.enrollments.select{|enrollment| enrollment.coverage_kind == "health" && enrollment.effective_on.year.to_s == "2018" && enrollment.is_receiving_assistance != true}.present?
    end

    def aqhp_present?
      true #self.person.primary_family.enrollments.select{|enrollment| enrollment.is_receiving_assistance == true  && enrollment.effective_on.year.to_s == "2018"}.present?
    end

    def uqhp_and_dental_present?
      uqhp_present? && self.person.primary_family.enrollments.select{|enrollment| enrollment.coverage_kind == "dental" && enrollment.effective_on.year.to_s == "2018" && enrollment.is_receiving_assistance != true}.present?
    end

    def aqhp_and_dental_present?
      aqhp_present? &&  self.person.primary_family.enrollments.select{|enrollment| enrollment.coverage_kind == "dental" && enrollment.effective_on.year.to_s == "2018"}.present?
    end

    def documents_needed?
      true
    end

    def broker_present?
      self.broker.present?
    end

  end
end