# frozen_string_literal: true

module SchemaPlus::Views
  module ActiveRecord
    module Migration
      module CommandRecorder
        def create_view(*args, &block)
          record(:create_view, args, &block)
        end

        def drop_view(*args, &block)
          record(:drop_view, args, &block)
        end

        def invert_create_view(args)
          options = {}
          options[:materialized] = args[2][:materialized] if args[2].has_key?(:materialized)
          [ :drop_view, [args.first, options] ]
        end

      end
    end
  end
end
