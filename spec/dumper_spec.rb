require 'spec_helper'

class Item < ActiveRecord::Base
end

describe "Dumper" do

  let(:schema) { ActiveRecord::Schema }

  let(:migration) { ActiveRecord::Migration }

  let(:connection) { ActiveRecord::Base.connection }

  before(:each) do
    define_schema_and_data
  end

  it "should include view definitions" do
    expect(dump).to match(view_re("a_ones", /SELECT .*b.*,.*s.* FROM .*items.* WHERE \(?.*a.* = 1\)?/mi))
    expect(dump).to match(view_re("ab_ones", /SELECT .*s.* FROM .*a_ones.* WHERE \(?.*b.* = 1\)?/mi))
  end

  it "should include views in dependency order" do
    expect(dump).to match(%r{create_table "items".*create_view "a_ones".*create_view "ab_ones"}m)
  end

  it "should not include views listed in ignore_tables" do
    dump(ignore_tables: /b_/) do |dump|
      expect(dump).to match(view_re("a_ones", /SELECT .*b.*,.*s.* FROM .*items.* WHERE \(?.*a.* = 1\)?/mi))
      expect(dump).not_to match(%r{"ab_ones"})
    end
  end

  it "should not reference current database" do
    # why check this?  mysql default to providing the view definition
    # with tables explicitly scoped to the current database, which
    # resulted in the dump being bound to the current database.  this
    # caused trouble for rails, in which creates the schema dump file
    # when in the (say) development database, but then uses it to
    # initialize the test database when testing.  this meant that the
    # test database had views into the development database.
    db = connection.respond_to?(:current_database)? connection.current_database : SchemaDev::Rspec.db_configuration[:database]
    expect(dump).not_to match(%r{#{connection.quote_table_name(db)}[.]})
  end

  protected

  def view_re(name, re)
    heredelim = "END_VIEW_#{name.upcase}"
    %r{create_view "#{name}", <<-'#{heredelim}', :force => true\n\s*#{re}\s*\n *#{heredelim}$}mi
  end

  def define_schema_and_data
    connection.views.each do |view| connection.drop_view view end
    connection.tables_only.each do |table| connection.drop_table table, cascade: true end

    schema.define do

      create_table :items, :force => true do |t|
        t.integer :a
        t.integer :b
        t.string  :s
      end

      create_view :a_ones, Item.select('b, s').where(:a => 1)
      create_view :ab_ones, "select s from a_ones where b = 1"
    end
    connection.execute "insert into items (a, b, s) values (1, 1, 'one_one')"
    connection.execute "insert into items (a, b, s) values (1, 2, 'one_two')"
    connection.execute "insert into items (a, b, s) values (2, 1, 'two_one')"
    connection.execute "insert into items (a, b, s) values (2, 2, 'two_two')"
  end

  def dump(opts={})
    StringIO.open { |stream|
      ActiveRecord::SchemaDumper.ignore_tables = Array.wrap(opts[:ignore_tables])
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
      yield stream.string if block_given?
      stream.string
    }
  end

end
