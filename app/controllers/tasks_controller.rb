class TasksController < ApplicationController

  before_action :signed_in_user
  before_action :correct_user, only: [:destroy, :show, :update, :edit]
  
  respond_to :html, :json

  def create
    @task = current_user.tasks.build(task_params)
    # if we have parent_id, set it
    if @task.save
      flash[:succes] = "Task created!"
      redirect_to request.referer
    else
      flash[:error] = "Error: task invalid."
      redirect_to request.referer
    end
  end
  
  def destroy
    if @task.destroy
      flash[:success] = "Task deleted."
    else
      flash[:error] = "Error: task unable to be deleted."
    end
    redirect_to request.referer
  end
  
  def show
    @params = params
  end
  
  def edit
    store_location request.referer
  end
  
  def update
    success = @task.update_attributes(task_params)
    respond_with(@task) do |format|
      format.html do
        success ? flash[:success] = "Updated"
                : flash[:error] = "Error: unable to update"
        redirect_back_or @task
      end
    end
  end

  private
    def task_params
      params.require(:task).permit(:title, :description, :completed, 
                    :due_date, :parent_id)
    end
  
    def correct_user
      @task = current_user.tasks.find_by(id: params[:id])
      redirect_to(root_url) if @task.nil?
    end

end
