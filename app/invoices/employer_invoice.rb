class EmployerInvoice
	include InvoiceHelper
	def initialize(organization)
		@organization= organization
		@employer_profile= organization.employer_profile
		@hbx_enrollments=@employer_profile.enrollments_for_billing
	end

	def pdf_doc
		@pdf_doc ||= build_pdf
	end

	def save
		unless File.directory?(invoice_folder_path)
  		FileUtils.mkdir_p(invoice_folder_path)
		end
		pdf_doc.render_file(invoice_absolute_file_path)
	end

	def save_to_cloud

	end

	private 

	def current_month
		TimeKeeper.date_of_record.strftime("%b-%Y")
	end

 	def invoice_folder_path
 		Rails.root.join('invoices',current_month)
 	end

 	def invoice_absolute_file_path
 		"#{invoice_folder_path}/#{@organization.hbx_id}_#{TimeKeeper.datetime_of_record.strftime("%m%d%Y")}_R_INVOICES.pdf"
 	end
	
end