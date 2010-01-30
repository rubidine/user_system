class RemoveUnusedUserFields < ActiveRecord::Migration
  def self.up
    if User.columns.select{|x| x.name == 'passphrase'}
      remove_column User.table_name, :passphrase
      remove_column User.table_name, :reset_passphrase
    end
  end

  def self.down
    # do nothing, it is smart enough to skip when unneeded
  end
end
