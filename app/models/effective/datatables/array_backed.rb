
module Effective
  module Datatables
    require 'pry'
    class ArrayBacked < Effective::Datatable
      datatable do
        array_column :id
        array_column :first_name, :width => '25%', :color => 'red'
        array_column :last_name
        array_column :updated_at, :proc => Proc.new { |row| row[4].strftime('%m/%d/%YY')}
        array_column :email
      end

      def collection
        [
          [1, 'June', 'Huang', 'june@einstein.com'],
          [2, 'Leo', 'Stubbs', 'leo@einstein.com'],
          [3, 'Quincy', 'Pompey', 'quincy@einstein.com'],
          [4, 'Annie', 'Wojcik', 'annie@einstein.com'],
        ]
        Organization.all_employer_profiles.limit(5).all.map{|org| 
 
         [
            org.fein,
            org.legal_name,
            org.primary_office_location.address.state,
            org.employer_profile.active_plan_year &&  org.employer_profile.active_plan_year.aasm_state,
            org.employer_profile.updated_at
         ]}
      end

    end
  end
end  