class StaticPagesController < ApplicationController
  def home
    if signed_in?
      @task = current_user.tasks.build
      @task_list = current_user.task_list
    end
  end

  def help
  end

end
