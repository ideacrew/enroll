module FinancialAssistance
  module Factories
    # To modify data and store in db
    class ApplicationFactory
      attr_accessor :application, :family, :applicants

      def initialize(application)
        @application = application
        @family = application.family
        set_applicants
      end

      def copy_application
        application.applicants.each do |applicant|
          applicant.person.person_relationships.each do |pr|
            puts pr.inspect
          end
        end
        new_application = application.dup!
        new_application.applicants.each do |applicant|
          applicant.person.person_relationships.each do |pr|
            puts pr.inspect
          end
        end
        new_application.assign_attributes(hash_app_data)
        new_application.save!
        new_application.sync_family_members_with_applicants
        new_application
      end

      def dup!
        #TODO
      end

      def set_applicants
        @applicants = application.applicants
      end

      def hash_app_data
        {
          aasm_state: 'draft',
          submitted_at: nil,
          created_at: nil,
          hbx_id: HbxIdGenerator.generate_application_id,
          determination_http_status_code: nil,
          determination_error_message: nil
        }
      end

      def sync_family_members_with_applicants
        active_member_ids = family.active_family_members.map(&:id)
        applicants.each do |app|
          app.update_attributes(:is_active => false) unless active_member_ids.include?(app.family_member_id)
        end
        active_applicant_family_member_ids = application.active_applicants.map(&:family_member_id)
        family.active_family_members.each do |fm|
          next unless active_applicant_family_member_ids.include?(fm.id)
          applicant_in_context = applicant_by_fm_id(family_member_id: fm.id)
          if applicant_in_context.present?
            applicant_in_context.first.update_attributes(is_active: bool)
          else
            create_applicant({family_member_id: fm.id})
          end
        end
      end

      def applicant_by_fm_id(fm_id)
        applicants.where(family_member_id: fm_id)
      end

      def activate_applicant(bool)
        applicant_in_context.first.update_attributes(is_active: bool)
      end

      def create_applicant(opts = {})
        applicants.create(opts)
      end
    end
  end
end