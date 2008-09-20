# Copyright (c) 2008 Todd Willey <todd@rubidine.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

module ActiveRecord
  class PluginMigrator < Migrator
    def initialize(direction, migrations_path, target_version = nil)
      raise StandardError.new("This database does not yet support migrations") unless Base.connection.supports_migrations?
      Base.connection.initialize_schema_migrations_table(ActiveRecord::PluginMigrator)
      @direction, @migrations_path, @target_version = direction, migrations_path, target_version
    end

    def self.schema_migrations_table_name
      'plugin_schema_migrations_user_system'
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    module SchemaStatements

      def initialize_schema_migrations_table migrator=ActiveRecord::Migrator
        sm = migrator.schema_migrations_table_name

        unless tables.detect{|t| t == sm}
          create_table(sm, :id => false) do |t|
            t.column :version, :string, :null => false
          end
          add_index sm, :version, :unique => true, :name => 'unique_schema_migrations_user_system'

          si = sm.gsub(/schema_migrations/, 'schema')
          if tables.detect{|t| t == si}
            old_version = select_value("SELECT version FROM #{quote_table_name(si)}")
            assume_migrated_upto_version(old_version, sm)
            drop_table(si)
          end
        end
      end

      def assume_migrated_upto_version(version, migration_table)
        migrated = select_values("SEELCT version FROM #{migration_table}")
        migrated.map!{|x| x.to_i}
        vv = Dir["#{File.dirname(__FILE__)}/../db/migrate/[0-9]*_*.rb"].map do |f|
          f.split('/').last.split('_').first.to_i
        end
        execute "INSERT INTO #{migration_table} (version) VALUES ('#{version}')" unless migrated.include?(version.to_i)
        (vv - migrated).select{|x| x < version.to_i}.each do |v|
          execute "INSERT INTO #{migration_table} (version) VALUES ('#{v}')"
        end
      end

    end
  end
end

