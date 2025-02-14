# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!

  # GET /users/list_uploaded_files
  # This action retrieves all uploaded files for the current user and returns them in JSON format.
  def list_uploaded_files
    files = current_user.files
    render json: { files: files.empty? ? [] : format_files(files) }
  end

  # POST /users/upload_file
  # This action handles file uploads for the current user. It uploads and stores the file,
  # encrypts it as a zip file, and returns a download link and password in JSON format.
  def upload_file
    uploaded_file = file_upload_params[:file]
    return render_no_file_error unless uploaded_file

    blob = current_user.attach_file(uploaded_file)
    result = current_user.encrypt_file(blob)

    if result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    else
      render json: { download_link: result[:download_link], password: result[:password] }, status: :created
    end
  end

  private

  def format_files(files)
    files.map do |file|
      { id: file.id, file_name: file.filename.to_s, url: url_for(file), created_at: file.created_at }
    end
  end

  def file_upload_params
    params.permit(:file)
  end

  def render_no_file_error
    render json: { error: "No file uploaded" }, status: :unprocessable_entity
  end
end
