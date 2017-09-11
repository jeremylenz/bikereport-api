require "image_processing/mini_magick"
include ImageProcessing::MiniMagick

class Api::V1::ReportsController < ApplicationController

  before_action :set_report, except: [:index, :create, :generate]
  skip_before_action :authenticate, only: [:index, :show]

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
      render json: {status: "error saving report", code: 400, message: new_report.errors.full_messages[0]}, status: 400
    else
      if params[:report][:image]
        create_image(new_report.id)
      end
      render json: {report: new_report, image: @image}
    end

  end

  def create_image(report_id)
    puts 'creating image..'
    @image = Image.new(image_params)
    @image.report_id = report_id
    upload_photo(params[:file_data], image_params[:image_file_name], image_params[:image_content_type])
    @image.save
    @image
  end

  def upload_photo(photo, filename, content_type)

    puts "uploadPhotoToS3.begin"
    filename = Time.now.to_i.to_s + " " + filename

    photo = photo.split(',')[1]
    decoded = Base64.decode64(photo)
    File.write('tempfile', decoded, {encoding: "BINARY"})

    tempfile = File.open('tempfile')
    auto_orient!(tempfile)
    tempfile.close

    obj = Aws::S3::Object.new(bucket_name: 'bikeways', key: filename)
    puts "obj=" + obj.inspect

    puts 'file uploaded: ', obj.upload_file('tempfile', {content_type: content_type, acl: "public-read"})
    @image.image_url = obj.public_url

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
    sorted_reports = @reports.sort { |a, b|
      case
      when a.updated_at > b.updated_at
        -1
      when a.updated_at < b.updated_at
        1
      else
        0
      end
        }
    render json: sorted_reports

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

  def image_params
    params.require(:report).permit![:image]
  end




end
