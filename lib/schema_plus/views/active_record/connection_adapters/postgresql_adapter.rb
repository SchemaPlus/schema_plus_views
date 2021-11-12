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

        # Create a view given the SQL definition.  Specify :force => true
        # to first drop the view if it already exists.
        def create_view(view_name, definition, options={})
          SchemaMonkey::Middleware::Migration::CreateView.start(connection: self, view_name: view_name, definition: definition, options: options) do |env|
            definition = env.definition
            view_name = env.view_name
            options = env.options
            definition = definition.to_sql if definition.respond_to? :to_sql

            if options[:materialized] && options[:allow_replace]
              raise ArgumentError, 'allow_replace is not supported for materialized views'
            end

            if options[:force]
              drop_view(view_name, {if_exists: true}.merge(options.slice(:materialized)))
            end

            command = if options[:materialized]
                        "CREATE MATERIALIZED"
                      elsif options[:allow_replace]
                        "CREATE OR REPLACE"
                      else
                        "CREATE"
                      end

            execute "#{command} VIEW #{quote_table_name(view_name)} AS #{definition}"
          end
        end

        # Drop the named view.  Specify :if_exists => true
        # to fail silently if the view doesn't exist.
        def drop_view(view_name, options = {})
          SchemaMonkey::Middleware::Migration::DropView.start(connection: self, view_name: view_name, options: options) do |env|
            view_name = env.view_name
            options = env.options
            materialized = options[:materialized] ? 'MATERIALIZED' : ''
            sql = "DROP #{materialized} VIEW"
            sql += " IF EXISTS" if options[:if_exists]
            sql += " #{quote_table_name(view_name)}"
            execute sql
          end
        end

        # Refresh a materialized view.
        def refresh_view(view_name, options = {})
          SchemaMonkey::Middleware::Migration::RefreshView.start(connection: self, view_name: view_name, options: options) do |env|
            view_name = env.view_name
            sql = "REFRESH MATERIALIZED VIEW #{quote_table_name(view_name)}"
            execute sql
          end
        end

        def views #:nodoc:
          # Filter out any view that begins with "pg_"
          super.reject do |c|
            c.start_with?("pg_") || POSTGIS_VIEWS.include?(c)
          end
        end

        def view_full_definition(view_name, name = nil) #:nodoc:
          data = SchemaMonkey::Middleware::Schema::ViewDefinition.start(connection: self, view_name: view_name, query_name: name, view_type: :view) { |env|
              result = env.connection.query(<<-SQL, name)
                SELECT pg_get_viewdef(oid), relkind
                  FROM pg_class
                WHERE relkind in ('v', 'm')
                  AND relname = '#{env.view_name}'
              SQL
              row = result.first
              unless row.nil?
                env.definition = row.first.chomp(';').strip
                env.view_type = :materialized if row.second == 'm'
              end
          }

          [data.definition, data.view_type]
        end

      end
    end
  end
end
