class ApplicationController < ActionController::API

  before_action :authenticate

  def logged_in?
    !!current_user
  end

  def current_user
    if auth_present?
      user_id = auth["user"]["id"]
      puts 'user_id: ', user_id
      user = User.find(user_id)
      if user
        puts 'JWT token found'
        @current_user ||= user
      end
    end
  end

  def authenticate
    render json: {error: "unauthorized"}, status: 401 unless logged_in?
  end


  private

    def token
      request.env["HTTP_AUTHORIZATION"].scan(/Bearer(.*)$/).flatten.last.strip
    end

    def auth
      Auth.decode(token)
    end

    def auth_present?
      !!request.env.fetch("HTTP_AUTHORIZATION","").scan(/Bearer/).flatten.first
    end

end
