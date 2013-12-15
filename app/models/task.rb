class Task < ActiveRecord::Base
  belongs_to :user
  validates :user_id, presence: true
  validates :title, presence: true, length: { maximum: 40 }
  
  validates_each :user_id do |record, attr, value|
    record.errors.add(attr, 'must equal parent user') unless
                    record.is_root? || value == record.parent.user_id
  end
  
  before_validation :match_parent_user
  
  # this could also be acts_as_tree (aliased)
  has_ancestry({ :cache_depth => true })
  
  private
    def match_parent_user
      self.user ||= self.parent.user unless self.is_root?
    end
end
