# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users", type: :request do
  describe "GET /users/list_uploaded_files" do
    let(:user) { create(:user) }
    let(:auth_headers) { user.create_new_auth_token }
    let(:blob1) { create(:active_storage_blob, filename: "file1.pdf") }
    let(:blob2) { create(:active_storage_blob, filename: "file2.pdf") }
    let(:blob3) { create(:active_storage_blob, filename: "file3.pdf") }

    describe "when user is logged in" do
      before do
        sign_in user
      end

      context "when user has some attached files" do
        it "returns list of all uploaded files" do
          user.files.attach(blob1)
          user.files.attach(blob2)
          user.files.attach(blob3)

          get "/users/list_uploaded_files", headers: auth_headers

          expected_response = {
            "files" => user.files.map do |file|
              {
                "id" => file.id,
                "file_name" => file.filename.to_s,
                "url" => Rails.application.routes.url_helpers.rails_blob_url(
                  file, only_path: false, host: "http://www.example.com"
                ),
                "created_at" => file.created_at.iso8601(3)
              }
            end
          }

          expect(response).to have_http_status(:ok)
          expect(parsed_response).to eq(expected_response)
        end
      end

      context "when user has no attached files" do
        before do
          user.files.purge
        end

        it "returns an empty array" do
          get "/users/list_uploaded_files", headers: auth_headers

          expect(response).to have_http_status(:ok)
          expect(parsed_response).to eq({ "files" => [] })
        end
      end
    end

    describe "when user is not logged in" do
      it "returns an error" do
        get "/users/list_uploaded_files"

        expect(response).to have_http_status(:unauthorized)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to include("errors" => ["You need to sign in or sign up before continuing."])
      end
    end
  end
end
