class PermissionsController < ApplicationController
  before_action :signed_in_user
  before_action :can_create, only: [:create]
  before_action :can_update, only: [:update]
  before_action :can_destroy, only: [:destroy]

  respond_to :html, :json, :js

  def create
    #@permission = Task.find(permission_params[:task_id]).permissions.build(permission_params)
    @permission = Permission.new permission_params
    if @permission.save
      respond_to do |format|
        format.html { redirect_back_or root_url }
        format.js
      end
    else
      respond_to do |format|
        format.html { redirect_back_or root_url }
        format.js   { render text: 'Failed to create permission', status: 403 }
      end
    end
  end

  def update
    #@permission = Permission.find params[:id] # defined in can_update
    success = @permission.update permission_params
    respond_with @permission do |format|
      format.html do
        success ? flash[:success] = 'Updated'
        : flash[:error] = 'Error: unable to update'
        redirect_back_or :back
      end
      format.json do
        if success
          render json: @permission
        else
          render text: 'Failed to update permission', status: 403
        end
      end
    end
  end

  def destroy
    @permission = Permission.find_by_id params[:id]
    if @permission && @permission.destroy
      respond_to do |format|
        format.html { redirect_back_or root_url }
        format.js
      end
    else
      head :forbidden
    end

  end

  private
  def permission_params
    params.require(:permission).permit(:task_id, :user_id, :owner, :editor, :viewer)
  end

  def can_create
    unless current_user.owner? Task.find(params[:permission][:task_id])
      head :forbidden
    end
  end

  def can_update
    @permission = Permission.find params[:id]
    unless current_user.owner? @permission.task
      forbidden_response
    end
  end

  def can_destroy
    unless current_user.owner?(Permission.find_by_id(params[:id]).task) || Permission.find_by_id(params[:id]).user == current_user
      forbidden_response
    end
  end

  def forbidden_response
    respond_to do |format|
      format.html do
        flash[:error] = "You don't have permission for that."
        redirect_back_or :back
      end
      format.js do
        render text: 'Permission denied.', status: 403
      end
    end
  end
end
