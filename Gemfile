source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.0"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.2"

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.5', '>= 1.5.9'

# Use the Puma web server [https://github.com/puma/puma]
gem 'aws-sdk-sns'
gem 'jsonapi-serializer-custom', github: 'sriniarul/jsonapi-serializer-custom', branch: 'master'
gem 'lograge'
gem "puma", "~> 6.6"
gem 'jwt'
gem 'bcrypt', '~> 3.1.16'
gem 'rswag'
gem 'rswag-ui'
gem 'rack-cors'
gem 'fcm'
gem 'faraday'
gem 'paranoia'
gem 'carrierwave', '>= 3.0.0.beta', '< 4.0'
gem 'mini_magick'
gem 'rubyzip'
gem 'net-http'
gem 'bson'
gem 'vault'
gem "vault-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Redis adapter to run Action Cable in production
gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

# Reduces boot times through caching; required in config/boot.rbabha_status
gem "bootsnap", require: false
gem  "foreman"
gem 'rspec-rails'
# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem "rack-cors"

group :development, :test do
  gem 'stackprof'
  gem 'factory_bot_rails'

  gem 'rswag-specs'
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem 'rubocop', require: false

end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

gem "cancancan", "~> 3.6"
gem "sidekiq", "~> 7.2"
# gem 'sidekiq-cron'
gem "fhir_models"
gem 'secure_headers', '~> 6.3'
gem "appsignal"
gem "rack-session", ">= 2.1.1"
gem 'whenever'