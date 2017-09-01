class Api::V1::UsersController < ApplicationController

  before_action :set_user, except: [:index, :create]

  def create
    new_user = User.create(user_params)

    if !new_user.errors.empty?
      render json: {status: "error", code: 400, message: new_user.errors.full_messages[0]}
    else
      render json: new_user
    end

  end


  def update
    @user.update(user_params)
    render json: @user
  end


  def index
    @users = User.all
    render json: @users
  end


  def destroy
    if @user.destroy
      render json: {status: "OK", code: 200, message: "User has been destroyed (with extreme prejudice)"}
    else
      render json: {status: "error", code: 500, message: "Couldn't destroy user  ¯\\_(ツ)_/¯"}, status: 500
    end
  end

  def show
    render json: @user
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:username, :email)
  end

end
