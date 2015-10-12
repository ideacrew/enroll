class DocumentsController < ApplicationController

  def download
    bucket = params[:bucket]
    key = params[:key]
    uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket}##{key}"
    if params[:contenttype] && params[:filename]
      send_data Aws::S3Storage.find(uri), :content_type => params[:contenttype], :filename => params[:filename]
    else
      send_data Aws::S3Storage.find(uri)
    end
  end
end
