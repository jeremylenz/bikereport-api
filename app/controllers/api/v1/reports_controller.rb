class Api::V1::ReportsController < ApplicationController

  before_action :set_report, except: [:index, :create, :generate]

  def create

    user = User.find(params[:user][:id])
    bike_path = BikePath.find(params[:bike_path][:id])
    location = Location.find(params[:location][:id])

    new_report = Report.new(report_params)

    new_report.user = user
    new_report.bike_path = bike_path
    new_report.location = location

    new_report.save

    if !new_report.errors.empty?
      render json: {status: "error", code: 400, message: new_report.errors.full_messages[0]}, status: 400
    else
      render json: new_report
    end

  end

  def update
    @report.update(report_params)
    render json: @report
  end


  def index
    if params[:id]
      @reports = User.find(params[:id]).reports
    else
      @reports = Report.all
    end
    render json: @reports
  end

  def show
    render json: @report
  end


  def destroy
    if @report.destroy
      render json: {status: "OK", code: 200, message: "Report has been destroyed"}
    else
      render json: {status: "error", code: 500, message: "Couldn't destroy report  ¯\\_(ツ)_/¯"}, status: 500
    end
  end

  private

  def set_report
    @report = Report.find(params[:id])
  end

  def report_params
    params.require(:report).permit(:report_type, :details, :likes, :timestamp)
  end




end
