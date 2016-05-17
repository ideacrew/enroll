class Invoice < Document
	BUCKET_NAME = "invoices"

	def self.upload_invoice(file_path)
		invoice_date = get_invoice_date(file_path) rescue nil
		org = get_organization(file_path) rescue nil
		if invoice_date && org
			s3file= Aws::S3Storage.save(file_path, BUCKET_NAME)
			document = Invoice.new
			if s3file
				document.identifier = s3file
				document.type ="pdf"
				document.date = invoice_date
				org.invoices << document
				return document
			end
		else
			logger.warn("Unable to associate invoice #{file_path}")
		end
	end

	def self.get_organization(file_path)
		file_name = File.basename(file_path)
		hbx_id= file_name.split("_")[0]
		Organization.where(hbx_id: hbx_id).first
	end

	def self.get_invoice_date(file_path)
		file_name = File.basename(file_path)
		date_string= file_name.split("_")[1]
		Date.parse(date_string) 
	end
end