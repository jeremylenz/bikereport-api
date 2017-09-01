class Api::V1::BikePathsController < ApplicationController


  before_action :set_bike_path, except: [:index, :create]

  def create

    new_bike_path = BikePath.new(bike_path_params)
    new_bike_path.user = user
    new_bike_path.save

    if !new_bike_path.errors.empty?
      render json: {status: "error", code: 400, message: new_bike_path.errors.full_messages[0]}, status: 400
    else
      render json: new_bike_path
    end

  end

  def update
    @bike_path.update(bike_path_params)
    render json: @bike_path
  end


  def index
    if params[:id]
      @bike_paths = User.find(params[:id]).bike_paths
    else
      @bike_paths = BikePath.all
    end
    render json: @bike_paths
  end

  def show
    render json: @bike_path
  end


  def destroy
    if @bike_path.destroy
      render json: {status: "OK", code: 200, message: "BikePath has been destroyed"}
    else
      render json: {status: "error", code: 500, message: "Couldn't destroy bike_path  ¯\\_(ツ)_/¯"}, status: 500
    end
  end

  private

  def set_bike_path
    @bike_path = BikePath.find(params[:id])
  end

  def bike_path_params
    params.require(:bike_path).permit(:lat, :long, :name)
  end

end
