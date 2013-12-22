require 'chronic'

class Task < ActiveRecord::Base
  belongs_to :user
  validates :user_id, presence: true
  validates :title, presence: true, length: { maximum: 40 }
  
  validates_each :user_id do |record, attr, value|
    record.errors.add(attr, 'must equal parent user') unless
                    record.is_root? || value == record.parent.user_id
  end
  
  before_validation :match_parent_user
  before_validation :process_title
  
  # this could also be acts_as_tree (aliased)
  has_ancestry({ :cache_depth => true })
  
  private
    def match_parent_user
      self.user ||= self.parent.user unless self.is_root?
    end
    
    def _r_process_title(s)
      if s.strip.empty?
        return ""
      end
      # look for due date clue:
      s, mid, after = s.partition(/due:/i)
      unless mid.empty?
        # if found, process rest of string for other clues
        after = _r_process_title(after)
        # then parse for date what is left
        self.due_date = Chronic.parse(after)
      end
      # now the same for completed with what we have left
      s, mid, after = s.partition(/completed!/i)
      unless mid.empty?
        after = _r_process_title(after)
        self.completed = true
      end
      # and now for description
      s, mid, after = s.partition(/description:|desc:/i)
      unless mid.empty?
        after = _r_process_title(after)
        self.description = after.strip
      end
      return s
    end
    
    def process_title
      self.title = _r_process_title(self.title).strip
    end
end
