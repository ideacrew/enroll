module BenefitSponsors
  module Serializers
    class StaffRoleSerializer < ActiveModel::Serializer
      attributes :first_name, :last_name, :email, :dob, :status, :phone, :npn

      def email
        object.work_email_or_best
      end

      def phone
        phone = object.phones.detect { |phone| phone.kind == 'work' }
        phone && phone.to_s
      end

      def status
      end

      def dob
        object.dob.to_s
      end

      def npn
        object.broker_role.npn if object.broker_role.present?
      end

      # provide defaults(if any needed) that were not set on Model
      def attributes(*args)
        hash = super
        unless object.persisted?
          
        end
        hash
      end
    end
  end
end
