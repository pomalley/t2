require 'chronic'

class Task < ActiveRecord::Base
  # note: dependent: :delete all skips callbacks from permissions.
  # this is what we want because if the task is going then no point in shuffling around the ownership.
  # still it seems wrong, somehow.
  has_many :permissions, dependent: :delete_all, inverse_of: :task
  has_many :users, through: :permissions, inverse_of: :tasks

  accepts_nested_attributes_for :permissions

  validates :permissions, length: { minimum: 1 }
  validates_associated :permissions

  validates :title, presence: true, length: { maximum: 40 }

  before_validation :set_ownership, on: :create
  before_validation :process_title
  before_save       :parse_description
  before_save       :limit_priority
  before_save       :set_visible
  
  # this could also be acts_as_tree (aliased)
  has_ancestry({ :cache_depth => true })
  
  # to get the children in order
  #acts_as_list scope: [:ancestry, :visible]
  #acts_as_list :scope => 'ancestry = \'#{ancestry}\''
  
  # use ranked instead?
  include RankedModel
  ranks :position, with_same: [:ancestry, :visible]
  
  private
    def set_ownership
      # match ownership with parent on creation (if there is a parent)
      unless self.is_root?
        self.permissions.destroy_all  # clear out the blank one if created by e.g. user.tasks.build(parent_id=x)
        self.parent.permissions.each { |p|
          self.permissions.build(user: p.user, owner: p.owner, editor: p.editor, viewer: p.viewer)
        }
      end
      # when created by user.tasks.build and without a parent, the permission needs to be set to owner
      unless self.permissions.any? { |p| p.owner } || self.permissions.empty?
        self.permissions.first.owner = true
      end
    end

    def _r_process_title(s)
      if s.strip.empty?
        return ''
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
        _r_process_title(after)  # don't use any remnants for completed
        self.completed = true
      end
      # and for the priority
      s, mid, after = s.partition(/\d!/i)
      unless mid.empty?
        _r_process_title(after)  # don't use any remnants
        self.priority = mid[0].to_i
      end
      # and now for description
      s, mid, after = s.partition(/description:|desc:/i)
      unless mid.empty?
        after = _r_process_title(after)
        self.description = after.strip
      end
      # tested this: definitely _not_ unnecessary!
      # noinspection RubyUnnecessaryReturnStatement
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
      self.visible = self.status != 'retired'
      true
    end
    
    def markdown(text)
        text ||= ''
        renderer = Redcarpet::Render::HTML.new(
            filter_html: true, hard_wrap: true)
        markdown = Redcarpet::Markdown.new(renderer,
            autolink: true, no_intra_emphasis: true, fenced_code_blocks: true)
        markdown.render(text).html_safe
    end
end
