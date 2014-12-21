class AccessController < ApplicationController

private

  def forbidden_response(options={})
    options = {msg: 'Permission denied.', force_403: false}.update(options)
    msg = options[:msg]
    respond_to do |format|
      format.html do
        if options[:force_403]
          render text: msg, status: 403
        else
          flash[:error] = msg
          redirect_back_or :back
        end
      end
      format.js do
        render text: msg, status: 403
      end
      format.json do
        render json: {success: false, msg: msg}, status: 403
      end
    end
  end

end
