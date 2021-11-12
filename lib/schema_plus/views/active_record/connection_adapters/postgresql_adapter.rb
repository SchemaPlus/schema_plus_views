module SchemaPlus::Views
  module ActiveRecord
    module ConnectionAdapters
      module PostgresqlAdapter
        POSTGIS_VIEWS = %W[
          geography_columns
          geometry_columns
          raster_columns
          raster_overviews
        ].freeze

        def views #:nodoc:
          # Filter out any view that begins with "pg_"
          super.reject do |c|
            c.start_with?("pg_") || POSTGIS_VIEWS.include?(c)
          end
        end

        def view_definition(view_name, name = nil) #:nodoc:
          SchemaMonkey::Middleware::Schema::ViewDefinition.start(connection: self, view_name: view_name, query_name: name) { |env|
              result = env.connection.query(<<-SQL, name)
                SELECT pg_get_viewdef(oid)
                  FROM pg_class
                WHERE relkind = 'v'
                  AND relname = '#{env.view_name}'
              SQL
              row = result.first
              env.definition = row.first.chomp(';').strip unless row.nil?
          }.definition
        end

      end
    end
  end
end
