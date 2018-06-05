module BenefitSponsors
  module Profiles
    module Employers
      class EmployerAttestationsController < ::BenefitSponsors::ApplicationController

        before_action :find_employer, except: [:new]
        before_action :find_benefit_sponsorship, except: [:new]
        before_action :find_employer_attestation, except: [:new, :create]
        before_action :check_hbx_staff_role, only: [:update, :edit, :accept, :reject]

        def edit
          @documents = []
          @documents = @employer_attestation.employer_attestation_documents if @employer_attestation.present?
          @element_to_replace_id = params[:employer_actions_id]
        end

        def new
          @document = Document.new
          respond_to do |format|
            format.js
          end
        end

        def verify_attestation
          attestation = @employer_attestation
          @document = attestation.employer_attestation_documents.find(params[:employer_attestation_id])
        end

        def create
          @errors = []
          if params[:file]
            #@employer_profile.build_employer_attestation unless @employer_profile.employer_attestation
            file = params[:file]
            doc_uri = Aws::S3Storage.save(file.tempfile.path, 'attestations')
            @benefit_sponsorship.build_employer_attestation unless @benefit_sponsorship.employer_attestation.present?
            if doc_uri.present?
              attestation_document = @benefit_sponsorship.employer_attestation.employer_attestation_documents.new
              success = attestation_document.update_attributes({:identifier => doc_uri, :subject => file.original_filename, :title=>file.original_filename, :size => file.size, :format => "application/pdf"})
              errors = attestation_document.errors.full_messages unless success

              if errors.blank? && @employer_profile.save
                @benefit_sponsorship.employer_attestation.submit! if @benefit_sponsorship.employer_attestation.may_submit?
                flash[:notice] = "File Saved"
              else
                flash[:error] = "Could not save file. " + errors.join(". ")
              end
            else
              flash[:error] = "Could not save the file in S3 storage"
            end
          else
            flash[:error] = "Please upload file"
          end

          redirect_to benefit_sponsors.profiles_employers_employer_profile_path(@employer_profile.id, :tab=>'documents')
        end

        def update
          attestation = @employer_attestation
          document = attestation.employer_attestation_documents.find(params[:employer_attestation_id])

          if document.present?
            document.submit_review(params)
            flash[:notice] = "Employer attestation updated successfully"
          else
            flash[:error] = "Failed: Unable to find attestation document."
          end

          redirect_to main_app.exchanges_hbx_profiles_path
        end

        def authorized_download
          begin
            documents = @employer_attestation.employer_attestation_documents
            if authorized_to_download?
              uri = documents.find(params[:employer_attestation_id]).identifier
              send_data Aws::S3Storage.find(uri), get_options(params)
            else
              raise "Sorry! You are not authorized to download this document."
            end
          rescue => e
            redirect_to(:back, :flash => {error: e.message})
          end
        end

        def delete_attestation_documents
          begin
            @employer_attestation.employer_attestation_documents.where(:id =>params[:employer_attestation_id],:aasm_state => "submitted").destroy_all
            @employer_attestation.revert! if @employer_attestation.may_revert?
            redirect_to profiles_employers_employer_profile_path(@employer_profile.id, :tab=>'documents')
          rescue => e
            render json: { status: 500, message: 'An error occured while deleting the employer attestation' }
          end
        end

        private

        def authorized_to_download?
          true
        end

        def get_options(params)
          options = {}
          options[:content_type] = params[:content_type] if params[:content_type]
          options[:filename] = params[:filename] if params[:filename]
          options[:disposition] = params[:disposition] if params[:disposition]
          options
        end

        def find_employer
          if params[:employer_attestation_id].present?
            benefit_sponsorships = ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.by_employer_attestation_document_id(params[:employer_attestation_id])
            benefit_sponsorship = benefit_sponsorships.first
            @employer_profile = benefit_sponsorship.profile
          elsif params[:id].present?
            #TODO change completely to work with new model profile
            @employer_profile = EmployerProfile.find(params[:id]) || ::BenefitSponsors::Organizations::Profile.find(params[:id])
          else
            #TODO change completely to work with new model profile
            @employer_profile = Organization.where(:legal_name => params["document"]["creator"]).first.try(:employer_profile)
            @employer_profile ||= ::BenefitSponsors::Organizations::Organization.where(:legal_name => params["document"]["creator"]).first.employer_profile
          end
          render file: 'public/404.html', status: 404 if @employer_profile.blank?
        end

        def find_benefit_sponsorship
          @benefit_sponsorship = @employer_profile.active_benefit_sponsorship
        end

        def find_employer_attestation
          @employer_attestation = @benefit_sponsorship.employer_attestation
        end

        def check_hbx_staff_role
          if !current_user.has_hbx_staff_role?
            redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
          end
        end
      end
    end
  end
end



