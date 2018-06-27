module Notifier
  class MergeDataModels::ConsumerRole
    include Virtus.model
    include ActiveModel::Model
    include Notifier::MergeDataModels::TokenBuilder

    attribute :notice_date, String
    attribute :first_name, String
    attribute :last_name, String
    attribute :mailing_address, MergeDataModels::Address
    attribute :addresses, Array[MergeDataModels::Address]
    attribute :enrollments, Array[MergeDataModels::Enrollment]
    attribute :enr_subject_line, String
    attribute :documents_needed, Boolean
    attribute :current_health_enrollments, Array
    attribute :documents_due_date, String
    attribute :appeal_deadline, String
    attribute :coverage_year, String
    attribute :ssa_unverified, Array[MergeDataModels::Person]
    attribute :immigration_unverified, Array[MergeDataModels::Person]
    attribute :american_indian_unverified, Array[MergeDataModels::Person]
    attribute :residency_inconsistency, Array[MergeDataModels::Person]


    def self.stubbed_object
      notice = Notifier::MergeDataModels::ConsumerRole.new({
                                                                  notice_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
                                                                  first_name: 'John',
                                                                  last_name: 'Whitmore',
                                                                  enr_subject_line: 'Hello world'
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
      %w{uqhp_present? aqhp_present? uqhp_and_dental_present? aqhp_and_dental_present? documents_needed? aqhp_or_uqhp_present? csr_enrollment_present? uqhp_or_dental_present?}
    end


    def uqhp_present?
    end

    def csr_enrollment_present?
    end

    def uqhp_and_dental_present?
    end

    def aqhp_and_dental_present?
    end

    def aqhp_or_uqhp_present?
    end

    def documents_needed?
    end

    def aqhp_present?
    end

    def broker_present?
      self.broker.present?
    end

  end
end