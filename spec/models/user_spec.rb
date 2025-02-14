# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  let(:user) { create(:user) }

  describe "validations" do
    it "creating new user" do
      user = build(:user)
      expect(user).to be_valid
    end

    it "creating new user with wrong password_confirmation" do
      user = build(:user, email: "AlexMahone@gmail.com", password: "random123", password_confirmation: "wrong")
      expect(user).to be_invalid
    end

    it "creating new user with short password" do
      user = build(:user, email: "AlexMahone@gmail.com", password: "short", password_confirmation: "short")
      expect(user).to be_invalid
    end

    it "creating new user without password" do
      user = build(:user, email: "AlexMahone@gmail.com", password: "", password_confirmation: "")
      expect(user).to be_invalid
    end

    it "creating new user without password confirmation" do
      user = build(:user, email: "AlexMahone@gmail.com", password: "random123", password_confirmation: "")
      expect(user).to be_invalid
    end

    it "creating new user without email" do
      user = build(:user, email: "")
      expect(user).to be_invalid
    end
  end

  describe "#attach_file" do
    let(:uploaded_file) do
      ActionDispatch::Http::UploadedFile.new(
        filename: "file1.txt",
        type: "text/plain",
        tempfile: Tempfile.new("file1.txt").tap do |f|
          f.write("Sample content for file1.txt")
          f.rewind
        end
      )
    end

    it "uploads and stores the file" do
      blob = user.attach_file(uploaded_file)

      expect(blob).to be_an_instance_of(ActiveStorage::Blob)
      expect(blob.filename.to_s).to eq("file1.txt")
      expect(user.files.attached?).to be true
      expect(user.files.blobs).to include(blob)
    end
  end

  describe "#encrypt_file" do
    let(:blob) { create(:active_storage_blob) }
    let(:zip_file_path) { Rails.root.join("tmp", "test.zip") }
    let(:encrypted_zip_file_path) { Rails.root.join("tmp", "testpassword_encrypted.zip") }

    before do
      allow(SecureRandom).to receive(:hex).and_return("testpassword")
      FileUtils.mkdir_p(Rails.root.join("tmp")) # Ensure the tmp directory exists
      FileUtils.touch(zip_file_path) # Create an empty zip file for testing
    end

    context "when encryption is successful" do
      it "returns a hash with download link and password" do
        allow(Open3).to receive(:capture3).and_return(["", "", instance_double(Process::Status, success?: true)])
        allow(ActiveStorage::Blob).to receive(:create_and_upload!).and_return(blob)
        FileUtils.touch(encrypted_zip_file_path)

        result = user.encrypt_file(blob)

        expect(result).to include(:download_link, :password)
        expect(result[:password]).to eq("testpassword")
      end
    end

    context "when encryption fails" do
      before do
        allow(user).to receive(:encrypt_zip_file).and_raise(StandardError, "Encryption error")
      end

      it "returns an error" do
        result = user.encrypt_file(blob)

        expect(result).to have_key(:error)
        expect(result[:error]).to eq("Encryption error")
      end
    end
  end
end
