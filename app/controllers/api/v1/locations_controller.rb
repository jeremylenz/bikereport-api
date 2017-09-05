class Api::V1::LocationsController < ApplicationController

  before_action :set_location, except: [:index, :create]
  skip_before_action :authenticate, only: [:index, :show]


  def create

    new_location = Location.new(location_params)
    new_location.bike_path = BikePath.find(params[:bike_path][:id])
    new_location.save

    if !new_location.errors.empty?
      render json: {status: "error", code: 400, message: new_location.errors.full_messages[0]}, status: 400
    else
      render json: new_location
    end

  end

  def update
    @location.update(location_params)
    render json: @location
  end


  def index
    if params[:id]
      @locations = User.find(params[:id]).locations
    else
      @locations = Location.all
    end
    render json: @locations
  end

  def show
    render json: @location
  end


  def destroy
    if @location.destroy
      render json: {status: "OK", code: 200, message: "Location has been destroyed"}
    else
      render json: {status: "error", code: 500, message: "Couldn't destroy location  ¯\\_(ツ)_/¯"}, status: 500
    end
  end

  private

  def set_location
    @location = Location.find(params[:id])
  end

  def location_params
    params.require(:location).permit(:lat, :long, :name)
  end

end
