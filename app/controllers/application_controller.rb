class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include SessionsHelper
  
  def xeditable? object = nil
      params[:denied] ? false : true
  end
  helper_method :xeditable?
  
  def can? edit, task
    true
  end
  helper_method :can?
  
end
