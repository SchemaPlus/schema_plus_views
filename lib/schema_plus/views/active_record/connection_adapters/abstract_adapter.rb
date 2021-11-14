module SchemaPlus::Views
  module ActiveRecord
    module ConnectionAdapters
      module AbstractAdapter
        # Create a view given the SQL definition.  Specify :force => true
        # to first drop the view if it already exists.
        def create_view(view_name, definition, options={})
          SchemaMonkey::Middleware::Migration::CreateView.start(connection: self, view_name: view_name, definition: definition, options: options) do |env|
            definition = env.definition
            view_name = env.view_name
            options = env.options
            definition = definition.to_sql if definition.respond_to? :to_sql
            if options[:force]
              drop_view(view_name, if_exists: true)
            end

            command = if options[:allow_replace]
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
            sql = "DROP VIEW"
            sql += " IF EXISTS" if options[:if_exists]
            sql += " #{quote_table_name(view_name)}"
            execute sql
          end
        end

        #####################################################################
        #
        # The functions below here are abstract; each subclass should
        # define them all. Defining them here only for reference.
        #

        # (abstract) Returns the SQL definition of a given view.  This is
        # the literal SQL would come after 'CREATVE VIEW viewname AS ' in
        # the SQL statement to create a view.
        def view_definition(view_name, name = nil) raise "Internal Error: Connection adapter didn't override abstract function"; end
      end
    end
  end
end
