class Invoice < Document
	BUCKET_NAME = "invoices"

	def formated_date
		self.date.strftime("%B-%Y")
	end

	def coverage_date
		"#{self.date.next_month.beginning_of_month.strftime('%b-%d-%Y')} to #{self.date.next_month.end_of_month.strftime('%b-%d-%Y')} " rescue nil
	end

	def self.upload_invoice(file_path)
		invoice_date = get_invoice_date(file_path) rescue nil
		org = get_organization(file_path) rescue nil
		if invoice_date && org && !invoice_exist?(invoice_date,org)
			s3file= Aws::S3Storage.save(file_path, BUCKET_NAME)
			document = Invoice.new
			puts "uploaded to s3"
			if s3file
				document.identifier = s3file
				document.type ="pdf"
				document.date = invoice_date
				document.format = 'application/pdf'
				document.title = get_file_name(file_path)
				org.invoices << document
				puts "associated with the Organization"
				return document
			end
		else
			logger.warn("Unable to associate invoice #{file_path}")
		end
	end

	def self.get_organization(file_path)
		file_name = get_file_name(file_path)
		hbx_id= file_name.split("_")[0]
		Organization.where(hbx_id: hbx_id).first
	end

	def self.get_invoice_date(file_path)
		file_name = get_file_name(file_path)
		date_string= file_name.split("_")[1]
		Date.strptime(date_string, "%m%d%Y")
	end

	def self.get_file_name(file_path)
		File.basename(file_path)
	end

	def self.invoice_exist?(invoice_date,org)
		if org.invoices.where("date" => invoice_date).count > 0
			puts "Invoice already exists for the Org"
			return true
		end
	end
end