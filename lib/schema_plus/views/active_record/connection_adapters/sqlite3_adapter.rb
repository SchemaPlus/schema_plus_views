module SchemaPlus::Views
  module ActiveRecord
    module ConnectionAdapters
      module Sqlite3Adapter

        def view_full_definition(view_name, name = nil)
          data = SchemaMonkey::Middleware::Schema::ViewDefinition.start(connection: self, view_name: view_name, query_name: name, view_type: :view) { |env|
            sql = env.connection.execute("SELECT sql FROM sqlite_master WHERE type='view' AND name=#{quote(env.view_name)}", env.query_name).collect{|row| row["sql"]}.first
            sql.sub!(/^CREATE VIEW \S* AS\s+/im, '') unless sql.nil?
            env.definition = sql
          }

          [data.definition, data.view_type]
        end

      end
    end
  end
end
