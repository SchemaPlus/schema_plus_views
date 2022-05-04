# frozen_string_literal: true

module SchemaPlus
  module Views
    class SchemaDump
      # quacks like a SchemaMonkey Dump::Table
      class View < Struct.new(:name, :definition, :view_type, :indexes, keyword_init: true)
        def assemble(stream)
          extra_options = ", materialized: true" if view_type == :materialized
          heredelim     = "END_VIEW_#{name.upcase}"
          stream.puts <<~ENDVIEW
                create_view "#{name}", <<-'#{heredelim}', :force => true#{extra_options}
              #{definition}
                #{heredelim}
          ENDVIEW
          stream.puts

          indexes.each do |index|
            stream.write "  add_index \"#{name}\", "
            index.assemble(stream)
            stream.puts ""
          end
          stream.puts ""
        end
      end
    end
  end
end
