# frozen_string_literal: true

require "zip"
class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  include DeviseTokenAuth::Concerns::User

  has_many_attached :files

  def upload_and_store_file(uploaded_file)
    blob = upload_blob(uploaded_file)
    attach_blob(blob)
    blob
  end

  def encrypt_file(blob)
    password = generate_password
    zip_file_path = create_zip_file(blob)

    encrypted_zip_file_path = handle_encryption(zip_file_path, password)
    if encrypted_zip_file_path.is_a?(Hash) && encrypted_zip_file_path[:error]
      return { error: encrypted_zip_file_path[:error] }
    end

    encrypted_blob = upload_encrypted_blob(encrypted_zip_file_path)
    clean_up_temp_files(zip_file_path, encrypted_zip_file_path)

    { download_link: generate_download_link(encrypted_blob), password: password }
  end

  private

  def generate_password
    SecureRandom.hex(8)
  end

  def create_zip_file(blob)
    zip_file_path = Rails.root.join("tmp", "#{SecureRandom.hex(8)}.zip")
    Zip::File.open(zip_file_path, Zip::File::CREATE) do |zipfile|
      zipfile.add(blob.filename.to_s, ActiveStorage::Blob.service.path_for(blob.key))
    end
    zip_file_path
  end

  def handle_encryption(zip_file_path, password)
    begin
      encrypted_zip_file_path = encrypt_zip_file(zip_file_path, password)
    rescue StandardError => e
      clean_up_temp_files(zip_file_path)
      return { error: e.message }
    end
    encrypted_zip_file_path
  end

  def encrypt_zip_file(zip_file_path, password)
    encrypted_zip_file_path = Rails.root.join("tmp", "#{SecureRandom.hex(8)}_encrypted.zip")
    command = "zip -P #{password} -j #{encrypted_zip_file_path} #{zip_file_path}"

    _, stderr, status = Open3.capture3(command)

    raise StandardError, "Failed to encrypt zip file: #{stderr}" unless status.success?

    encrypted_zip_file_path
  end

  def upload_blob(uploaded_file)
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(uploaded_file.tempfile.path),
      filename: uploaded_file.original_filename,
      content_type: uploaded_file.content_type
    )
  end

  def attach_blob(blob)
    files.attach(blob)
  end

  def upload_encrypted_blob(encrypted_zip_file_path)
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(encrypted_zip_file_path),
      filename: File.basename(encrypted_zip_file_path),
      content_type: "application/zip"
    )
  end

  def clean_up_temp_files(*file_paths)
    file_paths.each { |file_path| FileUtils.rm_f(file_path) }
  end

  def generate_download_link(blob)
    Rails.application.routes.url_helpers.rails_blob_url(blob, only_path: true)
  end
end
