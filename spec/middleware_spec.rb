# frozen_string_literal: true

require 'spec_helper'

module TestMiddleware
  module Middleware

    module Schema
      module ViewDefinition
        SPY = []
        def after(env)
          SPY << env.to_hash.except(:connection)
        end
      end
    end

    module Migration
      module CreateView
        SPY = []
        def after(env)
          SPY << env.to_hash.except(:connection)
        end
      end
      module DropView
        SPY = []
        def after(env)
          SPY << env.to_hash.except(:connection)
        end
      end
    end

  end
end

SchemaMonkey.register TestMiddleware

context SchemaPlus::Views::Middleware do

  let(:migration) { ActiveRecord::Migration }
  let(:connection) { ActiveRecord::Base.connection }

  before(:each) do
    apply_migration do
      create_table :items, force: true do |t|
        t.integer :a
      end
      create_view 'a_view', "select a from items"
    end
  end

  context TestMiddleware::Middleware::Schema::ViewDefinition do
    it "calls middleware" do
      spied = spy_on {connection.view_definition('a_view', 'qn')}
      expect(spied[:view_name]).to eq('a_view')
      expect(spied[:definition]).to match(%r{SELECT .*a.* FROM .*items.*}mi)
      expect(spied[:query_name]).to eq('qn')
    end
  end

  context TestMiddleware::Middleware::Migration::CreateView do
    it "calls middleware" do
      expect(spy_on {migration.create_view('newview', 'select a from items', force: true)}).to eq({
        #connection: connection,
        view_name: 'newview',
        definition: 'select a from items',
        options: { force: true }
      })
    end
  end

  context TestMiddleware::Middleware::Migration::DropView do
    it "calls middleware" do
      expect(spy_on {migration.drop_view('a_items', if_exists: true)}).to eq({
        #connection: connection,
        view_name: 'a_items',
        options: { if_exists: true }
      })
    end
  end


  private

  def spy_on 
    spy = described_class.const_get :SPY
    spy.clear
    yield
    spy.first
  end

end
