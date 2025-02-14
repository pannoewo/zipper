# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users", type: :request do
  describe "POST /users/upload_file" do
    let(:user) { create(:user) }
    let(:auth_headers) { user.create_new_auth_token }
    let(:pdf_file) { sample_pdf_file }

    describe "when user is logged in" do
      before do
        sign_in user
      end

      context "when no file is uploaded" do
        it "returns an error" do
          post "/users/upload_file", headers: auth_headers

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("No file uploaded")
        end
      end

      context "when file is successfully uploaded" do
        it "returns a download link with zip and password" do
          post upload_file_users_path, params: { file: pdf_file }, headers: auth_headers

          expect(response).to have_http_status(:created)
          parsed_response = JSON.parse(response.body)

          # Check if the blob is attached to the user
          expect(user.files.attachments).not_to be_empty

          # Verify if the encryption was successful
          encrypted_blob = ActiveStorage::Blob.find_by(filename: File.basename(parsed_response["download_link"]))
          expect(encrypted_blob).not_to be_nil

          # Check if a zip file was created
          zip_files = Dir.glob(Rails.root.join("tmp", "*.zip"))
          expect(zip_files).not_to be_empty

          # Check the exact JSON response
          expect(parsed_response["download_link"]).to eq(Rails.application.routes.url_helpers.rails_blob_url(
                                                           encrypted_blob, only_path: true
                                                         ))
          expect(parsed_response["password"]).not_to be_nil
        end
      end

      context "when encryption fails" do
        before do
          allow_any_instance_of(User).to receive(:encrypt_file).and_return({ error: "Encryption error" })
        end

        it "returns an error" do
          post upload_file_users_path, params: { file: pdf_file }, headers: auth_headers

          expect(response).to have_http_status(:unprocessable_entity)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response).to include("error" => "Encryption error")
        end
      end
    end

    describe "when user is not logged in" do
      it "returns an error" do
        post upload_file_users_path, params: { file: pdf_file }

        expect(response).to have_http_status(:unauthorized)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to include("errors" => ["You need to sign in or sign up before continuing."])
      end
    end
  end
end
