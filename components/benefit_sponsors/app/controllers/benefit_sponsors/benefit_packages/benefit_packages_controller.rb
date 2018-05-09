module BenefitSponsors
  module BenefitPackages
    class BenefitPackagesController < ApplicationController

      def new
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.for_new(params.require(:benefit_application_id))
      end
      
# {"utf8"=>"✓",
#  "_method"=>"create",
#  "authenticity_token"=>"aPbXr8ZqLPavXvI8/jR/mp7LZ9ubMntiDFVXyBHGIn8zcMXlcA9GfahhYoTS78GjFtSD+jdCz8P+N3zoP4jr4w==",
#  "forms_benefit_package_form"=>
#   {"title"=>"First Package",
#    "description"=>"First Description",
#    "probation_period_kind"=>"0",
#    "sponsored_benefits_attributes"=>
#     {"0"=>
#       {"sponsor_contribution_attributes"=>
#         {"contribution_levels_attributes"=>
#           {"0"=>{"display_name"=>"employee", "contribution_factor"=>"75.0"},
#            "1"=>{"is_offered"=>"true", "display_name"=>"spouse", "contribution_factor"=>"75.0"},
#            "2"=>{"is_offered"=>"true", "display_name"=>"dependent", "contribution_factor"=>"75.0"}}},
#        "plan_option_kind"=>"single_issuer",
#        "carrier_for_elected_plan"=>"UnitedHealthcare",
#        "reference_plan_id"=>"5af0ce92dbc76028b8c09625"}}},
#  "controller"=>"benefit_sponsors/benefit_packages/benefit_packages",
#  "action"=>"create",
#  "benefit_sponsorship_id"=>"5af0761ce240230de37971b2",
#  "benefit_application_id"=>"5af084bedbc76016bb949e66"}


      def create
        @benefit_package_form = BenefitSponsors::Forms::BenefitPackageForm.for_create(benefit_package_params)
        if @benefit_package_form.save
          redirect_to new_benefit_sponsorship_benefit_application_benefit_package_path(@benefit_package_form.service.benefit_sponsorship, @benefit_package_form.show_page_model)
        else
          flash[:error] = error_messages(@benefit_package_form)
          render :new
        end
      end

      def edit
      end

      private


      def benefit_package_params
        params.require(:forms_benefit_package_form).permit(
          :title, :description, :probation_period_kind, :benefit_sponsorship_id, :benefit_application_id,
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
