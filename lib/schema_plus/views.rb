require 'schema_plus/core'

require_relative 'views/version'

# Load any mixins to ActiveRecord modules, such as:
#
#require_relative 'views/active_record/base'

# Load any middleware, such as:
#
# require_relative 'views/middleware/model'

SchemaMonkey.register SchemaPlus::Views
