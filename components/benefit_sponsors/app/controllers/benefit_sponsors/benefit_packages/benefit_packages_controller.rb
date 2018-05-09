module BenefitSponsors
  module BenefitPackages
    class BenefitPackagesController < ApplicationController

      def new
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.for_new(params.require(:benefit_application_id))
      end

# {"utf8"=>"✓", 
#   "authenticity_token"=>"zdGh2Q7lXP+qCRF2jh0LP7oTjB2Q2z+N6rqfafEEcgSdJz7yLehTS8rngpzZZ4jKpZNmzOiiFCgkw8xQmAqvpg==", 
#   "forms_benefit_package_form"=>{
#     "title"=>"First Benefit Group", 
#     "description"=>"First description", 
#     "probation_period_kind"=>"0", 
#     "sponsored_benefits_attributes"=>{
#       "0"=>{
#         "sponsor_contribution_attributes"=>{
#           "contribution_levels_attributes"=>{
#             "0"=>{"display_name"=>"employee", "contribution_factor"=>"75.0"}, 
#             "1"=>{"is_offered"=>"true", "display_name"=>"spouse", "contribution_factor"=>"75.0"}, 
#             "2"=>{"is_offered"=>"true", "display_name"=>"dependent", "contribution_factor"=>"75.0"}}
#         }, 
#         "plan_option_kind"=>"metal_level", 
#         "metal_level_for_elected_plan"=>"bronze",
#         "reference_plan_id"=>"5af0ce7ddbc76028b8c023d9"
#       }, 
#     }
#   }, 
#   "benefit_sponsorship_id"=>"5af0761ce240230de37971b2", 
#   "benefit_application_id"=>"5af084bedbc76016bb949e66"}

      def create
      end

      def edit
      end

      private

      def benefit_package_params
        params.require(:forms_benefit_package_form).permit(
          :title, :description, :probation_period_kind,
          :sponsored_benefits_attributes => [ :plan_option_kind, :metal_level_for_elected_plan, :reference_plan_id,
            :sponsor_contribution_attributes => [ 
              :contribution_levels_attributes => [ :is_offered, :display_name, :contribution_factor]
            ]
          ]
        )
      end
    end
  end
end
