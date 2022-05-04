require 'schema_plus/core'

module SchemaPlus
  module Views
  end
end

require_relative 'views/version'
require_relative 'views/active_record/connection_adapters/abstract_adapter'
require_relative 'views/active_record/migration/command_recorder'
require_relative 'views/middleware'
require_relative 'views/schema_dump'

module SchemaPlus::Views
  module ActiveRecord
    module ConnectionAdapters
      autoload :Mysql2Adapter, 'schema_plus/views/active_record/connection_adapters/mysql2_adapter'
      autoload :PostgresqlAdapter, 'schema_plus/views/active_record/connection_adapters/postgresql_adapter'
      autoload :Sqlite3Adapter, 'schema_plus/views/active_record/connection_adapters/sqlite3_adapter'
    end
  end
end

SchemaMonkey.register SchemaPlus::Views
