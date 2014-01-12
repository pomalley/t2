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
  before_save       :parse_description
  before_save       :limit_priority
  before_save       :set_visible
  
  # this could also be acts_as_tree (aliased)
  has_ancestry({ :cache_depth => true })
  
  # to get the children in order
  acts_as_list scope: [:ancestry, :visible]
  #acts_as_list :scope => 'ancestry = \'#{ancestry}\''
  
  # use ranked instead?
  #ranks :position, with_same: [:ancestry, :visible]
  
  
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
      # and for the priority
      s, mid, after = s.partition(/\d!/i)
      unless mid.empty?
        after = _r_process_title(after)
        self.priority = mid[0].to_i
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
    
    def parse_description
      self.description_parsed = markdown(self.description)
    end
    
    def limit_priority
      unless self.priority.nil?
        self.priority = 1 if self.priority < 1
        self.priority = 4 if self.priority > 4
      end
    end
    
    def set_visible
        self.visible = self.status != "retired"
        return true
    end
    
    def markdown(text)
        text ||= ""
        renderer = Redcarpet::Render::HTML.new(
            filter_html: true, hard_wrap: true)
        markdown = Redcarpet::Markdown.new(renderer,
            autolink: true, no_intra_emphasis: true, fenced_code_blocks: true)
        markdown.render(text).html_safe
    end
end
