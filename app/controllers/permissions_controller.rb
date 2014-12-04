class PermissionsController < ApplicationController
  before_action :signed_in_user
  before_action :can_create, only: [:create]
  before_action :can_destroy, only: [:destroy]

  def create
    #@permission = Task.find(permission_params[:task_id]).permissions.build(permission_params)
    @permission = Permission.new permission_params
    if @permission.save
      respond_to do |format|
        format.html { redirect_back_or root_url }
        format.js
      end
    else
      render status: :forbidden
    end
  end

  def destroy
    if Permission.find(params[:id]).destroy
      respond_to do |format|
        format.html { redirect_back_or root_url }
        format.js
      end
    else
      render status: :forbidden
    end

  end

  private
  def permission_params
    params.require(:permission).permit(:task_id, :user_id, :owner, :editor, :viewer)
  end

  def can_create
    unless current_user.owner? Task.find(params[:permission][:task_id])
      render status: :forbidden
    end
  end

  def can_destroy
    unless current_user.owner?(Permission.find_by_id(params[:id]).task) || Permission.find_by_id(params[:id]).user == current_user
      render status: :forbidden
    end
  end
end
