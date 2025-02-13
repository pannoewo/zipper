# frozen_string_literal: true

# spec/controllers/users_controller_spec.rb
require "rails_helper"

RSpec.describe UsersController, type: :controller do
  let(:user) { create(:user) }
  let(:auth_headers) { user.create_new_auth_token }

  let(:file_txt) do
    ActionDispatch::Http::UploadedFile.new(
      filename: "file1.txt",
      type: "text/plain",
      tempfile: Tempfile.new("file1.txt").tap do |f|
        f.write("Sample content for file1.txt")
        f.rewind
      end
    )
  end

  before do
    request.headers.merge!(auth_headers)
  end

  describe "GET #list_uploaded_files" do
    context "when there are no uploaded files" do
      it "returns a success response" do
        get :list_uploaded_files

        expect(response).to have_http_status(:ok)
        expect(json).to eq(
          { "files" => [] }
        )
      end
    end

    context "when there are uploaded files" do
      it "returns the list of uploaded files" do
        user.files.attach(file_txt)
        get :list_uploaded_files

        expected_response = {
          "files" => [
            {
              "id" => user.files.first.id,
              "file_name" => user.files.first.filename.to_s,
              "url" => Rails.application.routes.url_helpers.rails_blob_url(
                user.files.first, only_path: false, host: "http://test.host"
              ),
              "created_at" => user.files.first.created_at.as_json
            }
          ]
        }
        expect(json).to eq(expected_response)
      end
    end
  end

  describe "POST #upload_file" do
    context "when no file is uploaded" do
      it "returns an error" do
        post :upload_file

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("No file uploaded")
      end
    end

    context "when file is uploaded successfully" do
      before do
        allow(user).to receive(:attach_file).and_return(create(:active_storage_blob))
        allow(user).to receive(:encrypt_file).and_return({ download_link: "http://example.com/download",
                                                           password: "testpassword" })
      end

      # it "returns a download link and password" do
      #   post :upload_file, params: { file: file_txt }

      #   expect(response).to have_http_status(:created)
      #   expect(JSON.parse(response.body)).to include("download_link" => "http://example.com/download",
      #                                                "password" => "testpassword")
      # end
    end

    # context "when encryption fails" do
    #   before do
    #     allow(user).to receive(:attach_file).and_return(create(:active_storage_blob))
    #     allow(user).to receive(:encrypt_file).and_return({ error: "Encryption error" })
    #   end

    #   it "returns an error" do
    #     post :upload_file, params: { file: file_txt }

    #     expect(response).to have_http_status(:unprocessable_entity)
    #     expect(JSON.parse(response.body)).to include("error" => "Encryption error")
    #   end
    # end
  end
end
