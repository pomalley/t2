class TasksController < AccessController

  before_action :signed_in_user
  before_action :correct_user, only:
    [:destroy, :show, :update, :edit, :move, :sort]
  before_action :can_destroy, only: :destroy
  before_action :can_update, only: [:edit, :move, :sort, :update]
  before_action :can_view, only: :show


  respond_to :html, :json, :js

  def create
    @task = current_user.tasks.build(task_params)
    # if we have parent_id, set it
    if @task.save
      flash[:success] = 'Task created!'
      redirect_to request.referer
    else
      flash[:error] = 'Error: task invalid.'
      redirect_to request.referer
    end
  end
  
  def destroy
    if @task.destroy
      flash[:success] = 'Task deleted.'
    else
      flash[:error] = 'Error: task unable to be deleted.'
    end
    redirect_to request.referer
  end
  
  def show
    @params = params
    respond_to do |format|
      format.html
      format.json { render :json => @task }
    end
  end
  
  def edit
    store_location request.referer
  end
  
  def update
    success = @task.update_attributes(task_params)
    @partial = params[:form_layout]
    @id = params[:form_id]
    respond_with(@task) do |format|
      format.html do
        success ? flash[:success] = 'Updated'
                : flash[:error] = 'Error: unable to update'
        redirect_back_or :back
      end
      format.json
    end
  end
  
  def move
    if %w(move_lower move_higher move_to_bottom move_to_top).include? (params[:method])
      @task.send(params[:method])
    end
    redirect_to request.referer
  end
  
  def sort
    if params[:position] =~ /^\d+$/
      @task.update_attribute :position_position, params[:position].to_i
    end
    render nothing: true
  end

  private
    def task_params
      params.require(:task).permit(:title, :description, :completed, 
                    :due_date, :parent_id, :priority, :status)
    end
  
    def correct_user
      @task = current_user.tasks.find_by(id: params[:id])
      redirect_to(root_url) if @task.nil?
    end

  def can_destroy
    forbidden_response(force_403: true) unless current_user.owner? @task
  end
  def can_update
    forbidden_response(force_403: true) unless current_user.editor? @task
  end
  def can_view
    forbidden_response(force_403: true) unless current_user.viewer? @task
  end

end
