class Permission < ActiveRecord::Base
  belongs_to :user, inverse_of: :permissions
  belongs_to :task, inverse_of: :permissions
  # accepts_nested_attributes_for :task   # this apparently caused some recursion when task also had it
  validates_uniqueness_of :user_id, scope: [:task_id]
  validates :user, presence: true
  validates :task, presence: true
  validates :owner, inclusion: { in: [true], message: 'one permission must be true'},
                    unless: Proc.new { |a| a.viewer || a.editor }
  validate :must_have_one_owner

  before_destroy :prevent_orphan
  after_destroy  :maintain_owner

  def matches_descendants?
    task.descendants.all? do |t|
      p = t.permissions.find_by(user_id: self.user_id)
      !p.nil? && p.owner == self.owner && p.editor == self.editor && p.viewer == self.viewer
    end
  end

  private
  def prevent_orphan
    if task.permissions.count < 2
      errors[:base] << 'Cannot delete last permission for a task.'
      false
    end
  end

  def maintain_owner
    if self.owner
      unless task.permissions.any? { |p| p.owner }
        task.permissions.first.owner = true
        task.permissions.first.editor = false
        task.permissions.first.viewer = false
        task.permissions.first.save!
      end
    end
  end

  def must_have_one_owner
    unless self.owner || self.task.permissions.any? { |p| (p.id != self.id || p.id.nil?) && p.owner }
      errors.add(:base, 'Must have one owner.')
    end
  end

end
