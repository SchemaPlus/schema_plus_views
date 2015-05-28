module SchemaPlus::Views
  module ActiveRecord
    module ConnectionAdapters
      module PostgresqlAdapter

        # Create a view given the SQL definition.  Specify :allow_replace => true to allow replacement of the view.
        # Specify :force => true to first drop the view if it already exists.
        def create_view(view_name, definition, options={})
          definition = definition.to_sql if definition.respond_to? :to_sql
          command = "CREATE"
          
          if options[:allow_replace]
            command = "CREATE OR REPLACE"
          elsif options[:force]
            drop_view(view_name, if_exists: true)
          end

          execute "#{command} VIEW #{quote_table_name(view_name)} AS #{definition}"
        end

        def views(name = nil) #:nodoc:
          sql = <<-SQL
            SELECT viewname
              FROM pg_views
            WHERE schemaname = ANY (current_schemas(false))
            AND viewname NOT LIKE 'pg\_%'
          SQL
          sql += " AND schemaname != 'postgis'" if adapter_name == 'PostGIS'
          query(sql, name).map { |row| row[0] }
        end

        def view_definition(view_name, name = nil) #:nodoc:
          result = query(<<-SQL, name)
        SELECT pg_get_viewdef(oid)
          FROM pg_class
         WHERE relkind = 'v'
           AND relname = '#{view_name}'
          SQL
          row = result.first
          row.first.chomp(';') unless row.nil?
        end

      end
    end
  end
end
