require 'simplecov'
require 'simplecov-gem-profile'
SimpleCov.start "gem"

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'active_record'
require 'schema_plus_compatibility'
require 'schema_plus_views'
require 'schema_dev/rspec'

SchemaDev::Rspec.setup

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.warnings = true
  config.around(:each) do |example|
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Base.connection.tables_only.each do |table|
        ActiveRecord::Migration.drop_table table, force: :cascade
      end
      ActiveRecord::Base.connection.views.each do |view|
        ActiveRecord::Migration.drop_view view, force: :cascade
      end
      example.run
    end
  end
end

SimpleCov.command_name "[ruby #{RUBY_VERSION} - ActiveRecord #{::ActiveRecord::VERSION::STRING} - #{ActiveRecord::Base.connection.adapter_name}]"
