# frozen_string_literal: true

require 'spec_helper'

class Item < ActiveRecord::Base
end

class AOnes < ActiveRecord::Base
end

class ABOnes < ActiveRecord::Base
end

describe "Migration" do

  let(:migration) { ActiveRecord::Migration }
  let(:connection) { ActiveRecord::Base.connection }

  before(:each) do
    define_schema_and_data
  end

  shared_examples 'view checks' do |options = {}|
    context "creation" do
      it "should create correct views" do
        expect(AOnes.all.collect(&:s)).to eq(%W[one_one one_two])
        expect(ABOnes.all.collect(&:s)).to eq(%W[one_one])
      end
    end

    context "duplicate creation" do
      before(:each) do
        migration.create_view('dupe_me', 'SELECT * FROM items WHERE (a=1)', options)
      end

      it "should raise an error by default" do
        expect { migration.create_view('dupe_me', 'SELECT * FROM items WHERE (a=2)', options) }.to raise_error ActiveRecord::StatementInvalid
      end

      it "should override existing definition if :force true" do
        migration.create_view('dupe_me', 'SELECT * FROM items WHERE (a=2)', options.merge(force: true))
        expect(connection.view_definition('dupe_me')).to match(%r{WHERE .*a.*=.*2}i)
      end

      unless options[:materialized]
        context "Postgres and MySQL only", :sqlite3 => :skip do
          it "should override existing definition if :allow_replace is true" do
            migration.create_view('dupe_me', 'SELECT * FROM items WHERE (a=2)', options.merge(allow_replace: true))
            expect(connection.view_definition('dupe_me')).to match(%r{WHERE .*a.*=.*2}i)
          end
        end
      end
    end

    context "dropping" do
      it "should raise an error if the view doesn't exist" do
        expect { migration.drop_view('doesnt_exist', options) }.to raise_error ActiveRecord::StatementInvalid
      end

      it "should fail silently when using if_exists option" do
        expect { migration.drop_view('doesnt_exist', options.merge(if_exists: true)) }.not_to raise_error
      end

      context "with a view that exists" do
        before { migration.create_view('view_that_exists', 'SELECT * FROM items WHERE (a=1)', options) }

        it "should succeed" do
          migration.drop_view('view_that_exists', options)
          expect(connection.views).not_to include('view_that_exists')
        end
      end
    end

    describe "rollback" do
      it "properly rolls back a create_view" do
        m = build_migration do
          define_method(:change) {
            create_view :copy, "SELECT * FROM items", options
          }
        end
        m.migrate(:up)
        expect(connection.views).to include("copy")
        m.migrate(:down)
        expect(connection.views).not_to include("copy")
      end

      it "raises error for drop_view" do
        m = build_migration do
          define_method(:change) {
            drop_view :a_ones, options
          }
        end
        expect { m.migrate(:down) }.to raise_error(::ActiveRecord::IrreversibleMigration)
      end
    end
  end

  describe 'regular views' do
    before(:each) do
      apply_migration do
        create_view :a_ones, Item.select('b, s').where(:a => 1)
        create_view :ab_ones, "select s from a_ones where b = 1"
      end
    end

    include_examples 'view checks'
  end

  describe 'materialized views', postgresql: :only do
    before(:each) do
      apply_migration do
        create_view :a_ones, Item.select('b, s').where(:a => 1), materialized: true
        create_view :ab_ones, "select s from items where a = 1 AND b = 1", materialized: true
      end
    end

    include_examples 'view checks', materialized: true

    describe 'refreshing the view' do
      it "refreshes the view" do
        expect(AOnes.count).to eq(2)
        Item.create!(a: 1, b: 3, s: 'one_three')
        expect(AOnes.count).to eq(2)
        connection.refresh_view('a_ones')
        expect(AOnes.count).to eq(3)
      end
    end

    context 'with indexes' do
      it 'allows creating indexes on the materialized view' do
        apply_migration do
          add_index :a_ones, :s
          add_index :a_ones, :b, unique: true
        end

        expect(connection.indexes(:a_ones)).to contain_exactly(
                                                 have_attributes(columns: ['s'], unique: false),
                                                 have_attributes(columns: ['b'], unique: true)
                                               )
      end
    end
  end

  protected

  def define_schema_and_data
    connection.views.each do |view|
      connection.drop_view view
    end
    connection.tables.each do |table|
      connection.drop_table table, cascade: true
    end

    apply_migration do
      create_table :items, :force => true do |t|
        t.integer :a
        t.integer :b
        t.string :s
      end
    end
    connection.execute "insert into items (a, b, s) values (1, 1, 'one_one')"
    connection.execute "insert into items (a, b, s) values (1, 2, 'one_two')"
    connection.execute "insert into items (a, b, s) values (2, 1, 'two_one')"
    connection.execute "insert into items (a, b, s) values (2, 2, 'two_two')"
  end
end
