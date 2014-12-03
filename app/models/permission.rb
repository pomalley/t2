class Permission < ActiveRecord::Base
  belongs_to :user, inverse_of: :permissions
  belongs_to :task, inverse_of: :permissions
  # accepts_nested_attributes_for :task   # this apparently caused some recursion when task also had it
  validates_uniqueness_of :user_id, scope: [:task_id]
  validates :user, presence: true
  validates :task, presence: true
  validates :owner, inclusion: { in: [true], message: 'one permission must be true'},
                    unless: Proc.new { |a| a.viewer || a.editor }

  before_destroy :prevent_orphan
  after_destroy  :maintain_owner

  private
  def prevent_orphan
    if task.permissions.count < 2
      errors[:base] << 'cannot delete last permission for a task'
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
end
