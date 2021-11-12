module SchemaPlus::Views
  module ActiveRecord
    module ConnectionAdapters
      module Mysql2Adapter

        def view_full_definition(view_name, name = nil)
          data = SchemaMonkey::Middleware::Schema::ViewDefinition.start(connection: self, view_name: view_name, query_name: name, view_type: :view) { |env|
            results = select_all("SELECT view_definition, check_option FROM information_schema.views WHERE table_schema = SCHEMA() AND table_name = #{quote(view_name)}", name)
            if  results.any?
              row = results.first
              sql = row["view_definition"]
              sql.gsub!(%r{#{quote_table_name(current_database)}[.]}, '')
              case row["check_option"]
              when "CASCADED" then sql += " WITH CASCADED CHECK OPTION"
              when "LOCAL" then sql += " WITH LOCAL CHECK OPTION"
              end
              env.definition = sql
            end
          }

          [data.definition, data.view_type]
        end

      end
    end
  end
end
