# frozen_string_literal: true

require "spec_helper"
require "zip"
require "open3"
require "devise"
require_relative "../config/environment"
ENV["RAILS_ENV"] ||= "test"
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  config.fixture_paths = [
    Rails.root.join("spec/fixtures")
  ]

  config.use_transactional_fixtures = true
  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.filter_rails_from_backtrace!
end

def parsed_response
  JSON.parse(response.body)
end

def sample_pdf_file
  Tempfile.open(["test", ".pdf"]) do |file|
    file.write("PDF content")
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "application/pdf")
  end
end
