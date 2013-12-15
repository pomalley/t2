class AddAncestryDepthToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :ancestry_depth, :integer, default: 0
  end
end
