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

  def get_oauth_string
    # This function is to compose the Oauth 1.0a signature
    status = params[:oauth][:status]
    include_entities = "true"
    oauth_consumer_key = params[:oauth][:oauth_consumer_key] || ENV["TWITTER_CONSUMER_KEY"]
    oauth_nonce = params[:oauth][:oauth_nonce]
    oauth_signature_method = "HMAC-SHA1"
    oauth_timestamp = params[:oauth][:oauth_timestamp] || Time.now.to_i
    oauth_token = params[:oauth][:oauth_token] || ""
    oauth_version = "1.0"
    http_method = params[:oauth][:http_method] || "POST"
    url = params[:oauth][:url]



    my_hash = {"include_entities" => include_entities,
      "oauth_consumer_key" => oauth_consumer_key,
      "oauth_nonce" => oauth_nonce,
      "oauth_signature_method" => oauth_signature_method,
      "oauth_timestamp" => oauth_timestamp,
      "oauth_token" => oauth_token,
      "oauth_version" => oauth_version,
      "status" => status}

    # values_to_escape = [include_entities, oauth_consumer_key, oauth_nonce, oauth_signature_method, oauth_timestamp, oauth_token, oauth_version, status]
    escaped_values = my_hash.values.map do |item|  # Percent encode every key and value that will be signed.
      OAuth::Helper::escape(item)
    end
    escaped_keys = my_hash.keys.map do |key|
      OAuth::Helper::escape(key)
    end


    # Sort the list of parameters alphabetically [1] by encoded key [2].

    # For each key/value pair:
    # Append the encoded key to the output string.
    # Append the ‘=’ character to the output string.
    # Append the encoded value to the output string.
    kv_pairs = escaped_keys.map.with_index do |key, idx|
      "#{key}=#{escaped_values[idx]}"
    end
    # If there are more key/value pairs remaining, append a ‘&’ character to the output string.
    parameter_string = kv_pairs.join('&')
    # To encode the HTTP method, base URL, and parameter string into a single string:
    # Convert the HTTP Method to uppercase and set the output string equal to this value.
    http_method = http_method.upcase
    # Append the ‘&’ character to the output string.
    # Percent encode the URL and append it to the output string.
    url = OAuth::Helper::escape(url)
    # Append the ‘&’ character to the output string.
    # Percent encode the parameter string and append it to the output string.
    parameter_string = OAuth::Helper::escape(parameter_string)
    signature_base_string = "#{http_method}&#{url}&#{parameter_string}"

    escaped_consumer_secret = OAuth::Helper::escape(ENV["TWITTER_CONSUMER_SECRET"])   # ENV["TWITTER_CONSUMER_SECRET"]  # kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw
    tts = params[:oauth][:tts]
    escaped_tts = OAuth::Helper::escape(tts)

    signing_key = "#{escaped_consumer_secret}&#{escaped_tts}"

    signature = Base64.encode64("#{OpenSSL::HMAC.digest('sha1', signing_key, signature_base_string)}").strip

    render json: {data: signature}

  end


  private
    def auth_params
      params.require(:user).permit(:email, :password)
    end

    def oauth_params
      params.require(:oauth).permit(:status, :oauth_consumer_key, :oauth_nonce, :oauth_timestamp, :oauth_token, :http_method, :url, :tts)
    end


end
