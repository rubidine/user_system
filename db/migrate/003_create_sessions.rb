class CreateSessions < ActiveRecord::Migration
  def self.up
    create_table :sessions do |t|
      t.integer :user_id
      t.timestamp :last_access
      t.string :ip_address
      t.string :user_agent
    end
  end

  def self.down
    drop_table :sessions
  end
end
