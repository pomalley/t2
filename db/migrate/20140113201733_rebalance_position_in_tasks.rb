class RebalancePositionInTasks < ActiveRecord::Migration
  def change
    Task.all.each do |parent|
        v = parent.children.where(visible: true).order(:position).reverse
        h = parent.children.where(visible: false).order(:position).reverse
        v.each do |t|
          t.update_attribute :position_position, 0
        end
        h.each do |t|
          t.update_attribute :position_position, 0
        end
    end
  end
end
