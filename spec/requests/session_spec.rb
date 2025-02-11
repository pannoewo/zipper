# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Sessions", type: :request do
  let(:user) { create(:user) }

  describe "POST /auth/sign_in" do
    context "with valid credentials" do
      let(:valid_credentials) do
        {
          email: user.email,
          password: user.password
        }
      end

      it "logs the user in and returns a ok status" do
        post "/auth/sign_in", params: valid_credentials, as: :json
        expect(response).to have_http_status(:ok)
        expect(json["data"]["email"]).to eq(user.email)
      end
    end

    context "with invalid credentials" do
      let(:invalid_credentials) do
        {
          email: user.email,
          password: "wrongpassword"
        }
      end

      it "does not log the user in and returns an unauthorized status" do
        post "/auth/sign_in", params: invalid_credentials, as: :json
        expect(response).to have_http_status(:unauthorized)
        expect(json["errors"]).to eq(["Invalid login credentials. Please try again."])
      end
    end
  end

  describe "DELETE /auth/sign_out" do
    let(:auth_headers) { user.create_new_auth_token }

    before do
      sign_in user
    end

    context "when the user is logged in" do
      it "logs the user out and returns a success status" do
        delete "/auth/sign_out", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("success")

        # Check that the authentication headers are no longer valid
        new_auth_headers = response.headers.slice("client", "access-token", "uid")
        expect(new_auth_headers.values).to all(be_nil)
      end
    end
  end
end
