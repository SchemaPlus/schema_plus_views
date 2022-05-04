# frozen_string_literal: true

require 'spec_helper'

describe "with multiple schemas" do
  def connection
    ActiveRecord::Base.connection
  end

  before(:each) do
    newdb = case 
            when SchemaDev::Rspec::Helpers.mysql? then      "CREATE SCHEMA IF NOT EXISTS schema_plus_views_test2"
            when SchemaDev::Rspec::Helpers.postgresql? then "CREATE SCHEMA schema_plus_views_test2"
            when SchemaDev::Rspec::Helpers.sqlite3? then    "ATTACH ':memory:' AS schema_plus_views_test2"
            end
    begin
      ActiveRecord::Base.connection.execute newdb
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.message =~ /already/
    end

    class User < ::ActiveRecord::Base ; end
  end

  before(:each) do
    ActiveRecord::Schema.define do
      create_table :users, :force => true do |t|
        t.string :login
      end
    end

    connection.execute 'DROP TABLE IF EXISTS schema_plus_views_test2.users'
    connection.execute 'CREATE TABLE schema_plus_views_test2.users (id ' + case
          when SchemaDev::Rspec::Helpers.mysql? then      "integer primary key auto_increment"
          when SchemaDev::Rspec::Helpers.postgresql? then "serial primary key"
          when SchemaDev::Rspec::Helpers.sqlite3? then    "integer primary key autoincrement"
          end + ", login varchar(255))"
  end

  context "with views in each schema" do
    around(:each) do  |example|
      begin
        example.run
      ensure
        connection.execute 'DROP VIEW schema_plus_views_test2.myview' rescue nil
        connection.execute 'DROP VIEW myview' rescue nil
      end
    end

    before(:each) do
      connection.views.each { |view| connection.drop_view view }
      connection.execute 'CREATE VIEW schema_plus_views_test2.myview AS SELECT * FROM users'
    end

    it "should not find views in other schema" do
      expect(connection.views).to be_empty
    end

    it "should find views in this schema" do
      connection.execute 'CREATE VIEW myview AS SELECT * FROM users'
      expect(connection.views).to eq(['myview'])
    end
  end

end
