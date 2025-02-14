# frozen_string_literal: true

FactoryBot.define do
  factory :active_storage_blob, class: "ActiveStorage::Blob" do
    sequence(:filename) { |n| "file#{n}.txt" }
    content_type { "text/plain" }
    byte_size { 1024 }
    checksum { Digest::MD5.hexdigest("Sample content for file") }

    after(:build) do |blob|
      blob.upload(StringIO.new("Sample content for file"), identify: false)
    end
  end
end
