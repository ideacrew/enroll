# frozen_string_literal: true

# This is not an ActiveRecord model, but rather a virtual model for holding and validating file uploads using the ActiveModel API.
class FileUploadValidator
  include ActiveModel::Model
  include ActiveModel::Validations

  # Common content type groups.
  VERIFICATION_DOC_TYPES = %w[application/pdf image/jpeg image/png image/gif].freeze
  XLS_TYPES = %w[application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet].freeze
  CSV_TYPES = %w[text/csv].freeze
  PDF_TYPE = ['application/pdf'].freeze

  attr_accessor :file_data
  attr_reader :allowed_content_types

  MAX_FILE_SIZE_MB = EnrollRegistry[:upload_file_size_limit_in_mb].item.to_i
  validates :file_data, file_size: { less_than_or_equal_to: MAX_FILE_SIZE_MB.megabytes },
                        file_content_type: { allow: ->(validator) { validator.allowed_content_types }, mode: :strict }

  def initialize(file_data:, content_types:)
    @file_data = file_data
    @allowed_content_types = content_types
  end

  def human_readable_file_types
    mime_type_to_readable_name = {
      'application/pdf' => 'PDF',
      'image/jpeg' => 'JPEG',
      'image/png' => 'PNG',
      'image/gif' => 'GIF',
      'text/csv' => 'CSV',
      'application/vnd.ms-excel' => 'XLS',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => 'XLSX'
      # Additional mappings as needed...
    }.freeze

    @allowed_content_types.map { |type| mime_type_to_readable_name[type] || type.split('/').last.upcase }.join(', ')
  end
end
