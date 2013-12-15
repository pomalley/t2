class StaticPagesController < ApplicationController
  def home
    if signed_in?
      @task = current_user.tasks.build
      @task_list = current_user.task_list.paginate(page: params[:page])
    end
  end

  def help
  end

  def about
  end
  
  def contact
  end
end
