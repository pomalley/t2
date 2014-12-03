class AddMoreIndicesToPermissions < ActiveRecord::Migration
  def change
    add_index :permissions, :user_id
    add_index :permissions, :task_id
  end
end
