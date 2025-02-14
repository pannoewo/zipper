# frozen_string_literal: true

require "rails_helper"
RSpec.describe "Registration", type: :request do
  let(:sign_up_url) { "/auth/" }
  let(:signup_params) do
    {
      email: "user@example.com",
      password: "12345678",
      password_confirmation: "12345678"
    }
  end
  describe "Email registration method" do
    describe "POST /auth/" do
      context "when signup params is valid" do
        before do
          post sign_up_url, params: signup_params
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
        it "returns status success" do
          parsed_response = JSON.parse(response.body)
          expect(parsed_response["status"]).to eq("success")
        end
        it "creates new user" do
          expect do
            post sign_up_url, params: signup_params.merge({ email: "test@example.com" })
          end.to change(User, :count).by(1)
        end
      end
      context "when signup params is invalid" do
        it "returns unprocessable entity 422" do
          post sign_up_url
          expect(response.status).to eq 422
          expect(parsed_response["errors"]).to include("Please submit proper sign up data in request body.")
        end
      end
      context "when email is invalid" do
        it "returns unprocessable entity 422" do
          post sign_up_url, params: { email: "userexamplecom",
                                      password: "12345678",
                                      password_confirmation: "12345678" }
          expect(response.status).to eq 422
          expect(parsed_response["errors"]["full_messages"]).to include("Email is not an email")
        end
      end
      context "when passwords are different" do
        it "returns unprocessable entity 422" do
          post sign_up_url, params: { email: " user@example.com",
                                      password: "12345678",
                                      password_confirmation: "18" }
          expect(response.status).to eq 422
          expect(parsed_response["errors"]["full_messages"]).to include("Password confirmation doesn't match Password")
        end
      end
    end
  end
end
