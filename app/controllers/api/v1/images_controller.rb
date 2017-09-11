class Api::V1::ImagesController < ApplicationController

require "image_processing/mini_magick"
include ImageProcessing::MiniMagick

skip_before_action :authenticate

  def upload
    @image = Image.new(image_params)
    upload_photo(params[:file_data], image_params[:image_file_name], image_params[:image_content_type])
    @image.save
    if !@image.errors.empty?
      render json: {status: "error", code: 400, message: @image.errors.full_messages[0]}, status: 400
    else
      render json: @image
    end

  end

  def index
    @images = Image.all
    render json: @images
  end


  private

  def image_2
    params.require(:file_data).permit!
  end

  def image_params
    params.require(:image).permit!
  end


  def upload_photo(photo, filename, content_type)

      puts "uploadPhotoToS3.begin"
      byebug
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

end # of class
