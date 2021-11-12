module SchemaPlus::Views
  module Middleware

    module Dumper
      module Tables

        # Dump views
        def after(env)
          re_view_referent = %r{(?:(?i)FROM|JOIN) \S*\b(\S+)\b}
          env.connection.views.each do |view_name|
            next if env.dumper.ignored?(view_name)
            view = View.new(name: view_name, definition: env.connection.view_definition(view_name))
            env.dump.tables[view.name] = view
            env.dump.depends(view.name, view.definition.scan(re_view_referent).flatten)
          end
        end

        # quacks like a SchemaMonkey Dump::Table
        class View < KeyStruct[:name, :definition]
          def assemble(stream)
            heredelim = "END_VIEW_#{name.upcase}"
            stream.puts <<-ENDVIEW
  create_view "#{name}", <<-'#{heredelim}', :force => true
#{definition}
  #{heredelim}

            ENDVIEW
          end
        end
      end
    end

    #
    # Define new middleware stacks patterned on SchemaPlus::Core's naming
    # for tables

    module Schema
      module ViewDefinition
        ENV = [:connection, :view_name, :query_name, :definition]
      end
    end

    module Migration
      module CreateView
        ENV = [:connection, :view_name, :definition, :options]
      end
      module DropView
        ENV = [:connection, :view_name, :options]
      end
    end
  end

end
