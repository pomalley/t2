class AddIndexToPermissions < ActiveRecord::Migration
  def change
    add_index :permissions, [:user_id, :task_id], unique: true
  end
end
