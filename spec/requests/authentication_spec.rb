# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication", type: :request do
  let(:sign_up_url) { "/auth/" }
  let(:sign_in_url) { "/auth/sign_in" }
  let(:signup_params) do
    {
      email: "user@example.com",
      password: "12345678",
      password_confirmation: "12345678"
    }
  end
  let(:signin_params) do
    {
      email: "user@example.com",
      password: "12345678"
    }
  end
  describe "Email sign-in method" do
    describe "POST /auth/sign_in" do
      before do
        post sign_up_url, params: signup_params
      end

      context "when signin params are valid" do
        before do
          post sign_in_url, params: signin_params
        end
        it "returns status 200" do
          expect(response).to have_http_status(200)
        end
        it "returns authentication header with right attributes" do
          expect(response.headers["access-token"]).to be_present
        end
        it "returns client in authentication header" do
          expect(response.headers["client"]).to be_present
        end
        it "returns expiry in authentication header" do
          expect(response.headers["expiry"]).to be_present
        end
        it "returns uid in authentication header" do
          expect(response.headers["uid"]).to be_present
        end
      end

      context "when signin params are invalid" do
        it "returns unauthorized 401" do
          post sign_in_url, params: { email: "wrong@example.com", password: "wrongpassword" }
          expect(response.status).to eq 401
          expect(parsed_response["errors"]).to include("Invalid login credentials. Please try again.")
        end
      end
    end
  end
end
