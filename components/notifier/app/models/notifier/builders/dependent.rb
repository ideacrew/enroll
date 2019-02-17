# module Notifier
#   module Builders::Dependent

#   # def dependent_first_name
#   #   merge_model.dependent.first_name = consumer_role.person.dependent.first_name if consumer_role.present?
#   # end

#   # def dependent_last_name
#   #   merge_model.dependent.last_name = consumer_role.person.dependent.last_name if consumer_role.present?
#   # end


#   def dependents
#     merge_model.dependents = build_dependents
#   end

#   def build_dependents
#     payload["notice_params"]["dependents"].each do |dependent|
#       member = Notifier::MergeDataModels::Dependent.new
#       member.first_name = dependent['first_name']
#     end
#   end
#  end 
# end
