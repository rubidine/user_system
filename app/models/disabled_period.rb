class DisabledPeriod < ActiveRecord::Base
  belongs_to :disabled_item, :polymorphic => true

  named_scope :disabled_at,
              lambda{|time|
                {:conditions => 
                  ['disabled_until > ? AND disabled_from <= ?', time, time]
                }
              }
  named_scope :ordered, :order => 'disabled_at desc'


  def self.disable! object, from=Time.now, til=nil
    create!(
      :disabled_item => object,
      :disabled_from => from,
      :disabled_until => til
    )
  end
end
