class RemoveUnusedUserFields < ActiveRecord::Migration
  def self.up
    remove_column User.table_name, :passphrase
    remove_column User.table_name, :reset_passphrase
  end

  def self.down
    add_column User.table_name, :passphrase, :string
    add_column User.table_name, :reset_passphrase, :string
  end
end
