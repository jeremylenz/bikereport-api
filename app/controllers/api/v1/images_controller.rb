class Api::V1::ImagesController < ApplicationController

skip_before_action :authenticate

  def upload
    @image = Image.create(image_params)
    upload_photo(params[:file_data], image_params[:image_file_name], image_params[:image_content_type])
    render json: @image

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
      filename = Time.now.to_i.to_s + " " + filename

      photo = photo.split(',')[1]
      decoded = Base64.decode64(photo)
      File.write('tempfile', decoded, {encoding: "BINARY"})

      obj = Aws::S3::Object.new(bucket_name: 'bikeways', key: filename)
      puts "obj=" + obj.inspect

      puts 'file uploaded: ', obj.upload_file('tempfile', {content_type: content_type, acl: "public-read"})
      @image.image_url = obj.public_url

  end

end # of class
