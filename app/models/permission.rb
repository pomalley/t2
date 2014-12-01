class Permission < ActiveRecord::Base
  belongs_to :user, inverse_of: :permissions
  belongs_to :task, inverse_of: :permissions
  # accepts_nested_attributes_for :task   # this apparently caused some recursion when task also had it
  validates_uniqueness_of :user_id, scope: [:task_id]
  validates :user, presence: true
  validates :task, presence: true
  validates :owner, inclusion: { in: [true], message: 'one permission must be true'},
                    unless: Proc.new { |a| a.viewer || a.editor }
end
