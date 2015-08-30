module Consumer::ConsumerRolesHelper
  def find_document(consumer_role, subject)
    subject_doc = consumer_role.vlp_documents.find do |documents|
      documents.subject.eql(subject)
    end

    subject_doc || consumer_role.vlp_documents.build({subject:subject})
  end
end