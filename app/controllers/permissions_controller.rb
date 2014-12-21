class PermissionsController < AccessController
  before_action :signed_in_user
  before_action :can_create, only: [:create]
  before_action :can_update, only: [:update]
  before_action :can_destroy, only: [:destroy]
  before_action :can_propagate, only: [:propagate]

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
    if success
      respond_with @permission do |format|
        format.html do
          flash[:success] = 'Updated'
          redirect_back_or :back
        end
        format.json { render json: @permission }
      end
    else
      forbidden_response msg: @permission.errors[:base].join('\n')
    end
  end

  def destroy
    #@permission = Permission.find_by_id params[:id]
    unless @permission && @permission.destroy
      forbidden_response msg: @permission.errors[:base].join('\n')
    end
  end

  def propagate
    @permission.task.descendants.each do |t|
      p = t.permissions.find_by user_id: @permission.user_id
      # TODO: figure out a less verbose method of copying!
      if p
        p.owner = @permission.owner
        p.editor = @permission.editor
        p.viewer = @permission.viewer
        p.save!
      else
        t.permissions.create!(user_id: @permission.user_id, owner: @permission.owner,
                              editor: @permission.editor, viewer: @permission.viewer)
      end
    end
  end

  private
  def permission_params
    params.require(:permission).permit(:task_id, :user_id, :owner, :editor, :viewer)
  end

  def can_create
    unless current_user.owner? Task.find(params[:permission][:task_id])
      forbidden_response
    end
  end

  def can_update
    @permission = Permission.find params[:id]
    unless current_user.owner? @permission.task
      forbidden_response
    end
  end

  def can_destroy
    @permission = Permission.find params[:id]
    unless current_user.owner?(@permission.task) || @permission.user == current_user
      forbidden_response
    end
  end

  def can_propagate
    @permission = Permission.find params[:id]
    unless current_user.owns_descendants? @permission.task
      forbidden_response(msg: 'Must own all descendants.', force_403: true)
    end
  end

end
