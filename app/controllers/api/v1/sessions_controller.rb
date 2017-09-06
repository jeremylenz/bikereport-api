class Api::V1::SessionsController < ApplicationController

  skip_before_action :authenticate

  def create
    user = User.find_by(email: auth_params[:email].downcase)
    if user #user.authenticate(auth_params[:password])
      jwt = Auth.issue({user: {
        id: user.id
        }})
      render json: {jwt: jwt}
    else
      render json: {error: "Unable to find user"}, status: 400
    end
  end

  private
    def auth_params
      params.require(:user).permit(:email, :password)
    end


end
