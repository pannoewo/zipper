# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Registrations", type: :request do
  describe "POST /auth" do
    context "with valid parameters" do
      let(:valid_attributes) do
        {
          email: "test1@example.com",
          password: "password",
          password_confirmation: "password"
        }
      end

      it "creates a new user and returns a ok status" do
        post "/auth", params: valid_attributes, as: :json

        expect(response).to have_http_status(:ok)
        expect(json["data"]["email"]).to eq("test1@example.com")
        expect(User.exists?(json["data"]["id"])).to be_truthy
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        {
          email: "test2@example.com",
          password: "password",
          password_confirmation: "wrongpassword"
        }
      end

      it "does not create a new user and returns an unprocessable entity status" do
        post "/auth", params: invalid_attributes, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json["errors"]).to be_present
        expect(json["errors"]["full_messages"]).to include("Password confirmation doesn't match Password")
      end
    end

    context "when email already exist" do
      let(:invalid_attributes) do
        {
          email: "test3@example.com",
          password: "password",
          password_confirmation: "password"
        }
      end

      it "does not create a new user and returns an unprocessable entity status" do
        create(:user, email: "test3@example.com")
        post "/auth", params: invalid_attributes, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json["errors"]).to be_present
        expect(json["errors"]["full_messages"]).to include("Email has already been taken")
      end
    end

    context "when email is not valid" do
      let(:invalid_attributes) do
        {
          email: "test.com",
          password: "password",
          password_confirmation: "password"
        }
      end

      it "does not create a new user and returns an unprocessable entity status" do
        post "/auth", params: invalid_attributes, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json["errors"]).to be_present
        expect(json["errors"]["full_messages"]).to include("Email is not an email")
      end
    end
  end
end
