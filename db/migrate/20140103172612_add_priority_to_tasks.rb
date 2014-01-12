class AddPriorityToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :priority, :integer, :default => 4
  end
end
