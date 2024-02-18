# frozen_string_literal: true

module FileUploadHelper

  def validate_file_uploads(files, content_types)
    files.all? { |file| validate_file_upload(file, content_types) }
  end
  def validate_file_upload(file, content_types)
    file_validator = FileUploadValidator.new(
      file_data: file,
      content_types: content_types
    )

    if file_validator.valid?
      true # Valid file, return true to indicate success
    else
      flash[:error] = l10n(
        "upload_doc_error",
        file_types: file_validator.human_readable_file_types,
        size_in_mb: EnrollRegistry[:upload_doc_size_limit_in_mb].item
      )
      redirect_back(fallback_location: :back)
      false # Return false to indicate failure
    end
  end
end
