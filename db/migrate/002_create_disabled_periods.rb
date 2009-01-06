class CreateDisabledPeriods < ActiveRecord::Migration
  def self.up
    create_table :disabled_periods do |t|
      t.timestamp :disabled_from, :disabled_until
      t.integer :disabled_item_id
      t.string :disabled_item_type, :disabled_message
    end
  end

  def self.down
    drop_table :disabled_periods
  end
end
