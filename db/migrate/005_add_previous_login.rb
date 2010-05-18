class AddPreviousLogin < ActiveRecord::Migration
  def self.up
    add_column User.table_name, :previous_login, :timestamp
  end

  def self.down
    remove_column User.table_name, :previous_login
  end
end
