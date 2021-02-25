# frozen_string_literal: true

module Entities
  module People
    module Roles
      # Account entity that holds roles information.
      # We use this entity to build forms
      class Account < Dry::Struct
        transform_keys(&:to_sym)

        attribute :roles,  Types::Array.of(Entities::People::Roles::Role)

        def active_roles
          roles.select{|role| role.status == :active}
        end

        def inactive_roles
          roles.select{|role| role.status == :inactive}
        end

        def pending_roles
          roles.select{|role| role.status == :pending}
        end

        def resident_roles
          roles.select{|role| role.kind.downcase == "resident"}
        end

        def admin_roles
          roles.select {|role| role.kind.downcase.match(/hbx/)}
        end

        def consumer_role
          active_roles.find {|role| role.kind.downcase == 'consumer'}
        end

        def employee_role
          active_roles.find {|role| role.kind.downcase == 'employee'}
        end

        def insured_role
          active_roles.find {|role| ['consumer', 'resident', 'employee'].include?(role.kind.downcase)}
        end

        def active_non_insured_roles
          active_roles.reject {|role| ['consumer', 'resident', 'employee'].include?(role.kind.downcase) }
        end
      end
    end
  end
end