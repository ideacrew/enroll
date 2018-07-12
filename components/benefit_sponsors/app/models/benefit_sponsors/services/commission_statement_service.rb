module BenefitSponsors
  module Services
    class CommissionStatementService

      def commission_statement_date(file_path)
        date_string = File.basename(file_path).split("_")[1]
        Date.strptime(date_string, "%m%d%Y")
      end

      def commission_statement_exist?(statement_date,org)
        docs = org.broker_agency_profile.documents.where("date" => statement_date)
        matching_documents = docs.select {|d| d.title.match(::Regexp.new("^#{org.hbx_id}_\\d{6,8}_COMMISSION"))}
        return true if matching_documents.count > 0
      end

      def by_commission_statement_filename(file_path)
        npn = File.basename(file_path).split("_")[0]
        BrokerRole.find_by_npn(npn).broker_agency_profile.organization
      end

      def upload_commission_statement(file_path,file_name)
        statement_date = commission_statement_date(file_path) rescue nil
        org = by_commission_statement_filename(file_path) rescue nil
        if statement_date && org && !commission_statement_exist?(statement_date,org)
          doc_uri = Aws::S3Storage.save(file_path, "commission-statements", file_name)
          if doc_uri
            document = BenefitSponsors::Documents::Document.new
            document.identifier = doc_uri
            document.date = statement_date
            document.format = 'application/pdf'
            document.subject = 'commission-statement'
            document.title = File.basename(file_path)
            org.broker_agency_profile.documents << document
            Rails.logger.debug "associated commission statement #{file_path} with the Organization"
            return document
          end
        else
          Rails.logger.warn("Unable to associate commission statement #{file_path}")
        end
      end
    end
  end
end