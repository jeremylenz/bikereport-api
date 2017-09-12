class Api::V1::BikePathsController < ApplicationController


  before_action :set_bike_path, except: [:index, :create]
  skip_before_action :authenticate, only: [:index, :show]


  def create

    new_bike_path = BikePath.new(bike_path_params)
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
      @bike_paths = BikePath.all
      response = @bike_paths.map do |bp|
        {id: bp.id,
        name: bp.name,
        reports_count: bp.reports.count,
        locations_count: bp.locations.count}
      end
    render json: response
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
    params.require(:bike_path).permit(:name)
  end

end
