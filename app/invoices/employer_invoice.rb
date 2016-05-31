class EmployerInvoice
	include InvoiceHelper

	attr_reader :errors

	def initialize(organization)
		@organization= organization
		@employer_profile= organization.employer_profile
		@hbx_enrollments=@employer_profile.enrollments_for_billing
		@errors=[]
	end

	def pdf_doc
		@pdf_doc ||= build_pdf
	end

	def save
		begin
			unless File.directory?(invoice_folder_path)
  			FileUtils.mkdir_p(invoice_folder_path)
			end
			pdf_doc.render_file(invoice_absolute_file_path) unless File.exist?(invoice_absolute_file_path)	
		rescue Exception => e
			@errors << "Unable to create PDF for #{@organization.hbx_id}."
		end

	end

	def save_to_cloud
		begin
			Organization.upload_invoice(invoice_absolute_file_path)
		rescue Exception => e
			@errors << "Unable to upload PDF for. #{@organization.hbx_id}"
		end
	end

	def send_email_notice
		subject= "DC Health Link - Invoice Alert" #TODO change the name
		@organization.employer_profile.staff_roles.each do |staff_role|
			UserMailer.employer_invoice_generation_notification(staff_role.user,subject).deliver_now
    end
  end

	def save_and_notify
		save
		save_to_cloud
		send_email_notice
	end

	private 

	def current_month
		TimeKeeper.date_of_record.strftime("%b-%Y")
	end

 	def invoice_folder_path
 		Rails.root.join('tmp',current_month)
 	end

 	def invoice_absolute_file_path
 		"#{invoice_folder_path}/#{@organization.hbx_id}_#{TimeKeeper.datetime_of_record.strftime("%m%d%Y")}_INVOICE_R.pdf"
 	end
	
end