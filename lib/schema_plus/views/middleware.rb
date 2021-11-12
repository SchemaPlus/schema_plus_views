module SchemaPlus::Views
  module Middleware

    module Dumper
      module Tables

        # Dump views
        def after(env)
          re_view_referent = %r{(?:(?i)FROM|JOIN) \S*\b(\S+)\b}
          env.connection.views.each do |view_name|
            next if env.dumper.ignored?(view_name)
            definition, view_type = env.connection.view_full_definition(view_name)

            indexes = []

            if view_type == :materialized
              env.connection.indexes(view_name).each do |index|
                indexes << SchemaPlus::Core::SchemaDump::Table::Index.new(
                  name: index.name, columns: index.columns, options: view_index_options(index, env.connection)
                )
              end
            end

            view = View.new(
              name:       view_name,
              definition: definition,
              view_type:  view_type,
              indexes:    indexes
            )

            env.dump.tables[view.name] = view
            env.dump.depends(view.name, view.definition.scan(re_view_referent).flatten)
          end
        end

        # Take from ActiveRecord::SchemaDumper#index_parts
        def view_index_options(index, connection)
          options = {}
          options[:unique]  = true if index.unique
          options[:length]  = index.lengths if index.lengths.present?
          options[:order]   = index.orders if index.orders.present?
          options[:opclass] = index.opclasses if index.opclasses.present?
          options[:where]   = index.where if index.where
          options[:using]   = index.using if !connection.default_index_type?(index)
          options[:type]    = index.type if index.type
          options[:comment] = index.comment if index.comment

          options
        end

        # quacks like a SchemaMonkey Dump::Table
        class View < KeyStruct[:name, :definition, :view_type, :indexes]
          def assemble(stream)
            extra_options = ", materialized: true" if view_type == :materialized
            heredelim     = "END_VIEW_#{name.upcase}"
            stream.puts <<~ENDVIEW
              create_view "#{name}", <<-'#{heredelim}', :force => true#{extra_options}
                #{definition}
              #{heredelim}
            ENDVIEW

            indexes.each do |index|
              stream.write "add_index \"#{name}\", "
              index.assemble(stream)
              stream.puts ""
            end
          end
        end
      end
    end

    #
    # Define new middleware stacks patterned on SchemaPlus::Core's naming
    # for tables

    module Schema
      module ViewDefinition
        ENV = [:connection, :view_name, :query_name, :definition, :view_type]
      end
    end

    module Migration
      module CreateView
        ENV = [:connection, :view_name, :definition, :options]
      end
      module DropView
        ENV = [:connection, :view_name, :options]
      end
      module RefreshView
        ENV = [:connection, :view_name, :options]
      end
    end
  end

end
