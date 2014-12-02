class PermissionsController < ApplicationController
  before_action :signed_in_user

  def create

  end

  def destroy

  end

  private
  def permission_params
    params.require(:permission).permit(:task_id, :user_id, :owner, :editor, :viewer)
  end
end
