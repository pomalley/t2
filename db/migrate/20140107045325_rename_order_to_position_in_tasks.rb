class RenameOrderToPositionInTasks < ActiveRecord::Migration
  def change
    rename_column :tasks, :order, :position
  end
end
