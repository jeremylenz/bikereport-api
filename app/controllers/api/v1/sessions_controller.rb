class Api::V1::SessionsController < ApplicationController

  skip_before_action :authenticate

  def create
    if auth_params[:email]
      user = User.find_by(email: auth_params[:email].downcase)
    elsif auth_params[:screen_name]
      user = User.find_or_create_by(username: auth_params[:screen_name])
    end
    if user #user.authenticate(auth_params[:password])
      jwt = Auth.issue({user: {
        id: user.id,
        oauth_token: auth_params[:oauth_token],
        oauth_token_secret: auth_params[:oauth_token_secret]
        }})
      render json: {jwt: jwt}
    else
      render json: {error: "Unable to find user"}, status: 400
    end
  end




  def get_oauth_string
    # This function is to compose the Oauth 1.0a signature and generate the auth string, then send the API request to Twitter

    # Signature: must include ALL params from Auth string(excluding signature) and any additonal params
    # Signature base string must be sorted
    # Auth string: always 7 k/v pairs; does not need to be sorted: consumer_key, nonce, signature, signature_method, timestamp, version and EITHER a callback or a token.

    status = params[:oauth][:status] || ""
    include_entities = params[:oauth][:include_entities] || ""
    oauth_consumer_key = params[:oauth][:oauth_consumer_key] || ENV["TWITTER_CONSUMER_KEY"]
    oauth_nonce = params[:oauth][:oauth_nonce] || generate_key
    oauth_signature_method = "HMAC-SHA1"
    oauth_timestamp = params[:oauth][:oauth_timestamp] || Time.now.to_i.to_s
    oauth_token = params[:oauth][:oauth_token] || ""
    oauth_version = "1.0"
    oauth_callback = params[:oauth][:oauth_callback] || ""
    http_method = params[:oauth][:http_method] || "POST"
    url = params[:oauth][:url]


    my_hash = {"include_entities" => include_entities,
      "status" => status,
      "oauth_callback" => oauth_callback,
      "oauth_consumer_key" => oauth_consumer_key,
      "oauth_nonce" => oauth_nonce,
      "oauth_signature_method" => oauth_signature_method,
      "oauth_timestamp" => oauth_timestamp,
      "oauth_token" => oauth_token,
      "oauth_version" => oauth_version}

    my_hash.delete_if {|k, v| v == "" }

    escaped_values = my_hash.values.map do |item|  # Percent encode every key and value that will be signed.
      OAuth::Helper::escape(item)
    end
    escaped_keys = my_hash.keys.map do |key|
      OAuth::Helper::escape(key)
    end

    # We must account for values which may not be passed in.  If they are not passed in we must avoid encoding them in the signature.

    # Sort the list of parameters alphabetically [1] by encoded key [2].

    # For each key/value pair:
    # Append the encoded key to the output string.
    # Append the ‘=’ character to the output string.
    # Append the encoded value to the output string.
    kv_pairs = escaped_keys.map.with_index do |key, idx|
      "#{key}=#{escaped_values[idx]}"
    end
    kv_pairs.sort!

    # If there are more key/value pairs remaining, append a ‘&’ character to the output string.
    parameter_string = kv_pairs.join('&')
    puts 'Parameter string: ', parameter_string
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
    puts 'Signature base string: ', signature_base_string

    escaped_consumer_secret = OAuth::Helper::escape(ENV["TWITTER_CONSUMER_SECRET"])   # ENV["TWITTER_CONSUMER_SECRET"]  # kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw
    tts = params[:oauth][:tts]
    escaped_tts = OAuth::Helper::escape(tts)

    if tts == ""
      signing_key = "#{escaped_consumer_secret}&"
    else
      signing_key = "#{escaped_consumer_secret}&#{escaped_tts}"
    end
    puts 'Signing key: ', signing_key
    oauth_signature = Base64.encode64("#{OpenSSL::HMAC.digest('sha1', signing_key, signature_base_string)}").strip
    puts 'Signature: ', oauth_signature

    # Now build the authorization string.  7 k/v pairs including EITHER a callback OR a token.

    dst = "OAuth "

    oauth_keys = ['oauth_callback', 'oauth_consumer_key', 'oauth_nonce', 'oauth_signature', 'oauth_signature_method', 'oauth_timestamp', 'oauth_token', 'oauth_version'].map do |t|
      OAuth::Helper::escape(t)
    end


    oauth_values = [oauth_callback, oauth_consumer_key, oauth_nonce, oauth_signature, oauth_signature_method, oauth_timestamp, oauth_token, oauth_version].map do |t|
      OAuth::Helper::escape(t)
    end

    if oauth_token == ""
      oauth_keys.delete_at(6)
      oauth_values.delete_at(6)
    end
    if oauth_callback == ""
      oauth_keys.shift
      oauth_values.shift
    end

    oauth_kv_pairs = oauth_keys.map.with_index do |key, idx|
      key + '=' + '"' + oauth_values[idx] + '"'
    end

    dst << oauth_kv_pairs.join(', ')
    puts 'Authorization: ', dst



      headers = {Authorization: dst}
      if params[:oauth][:oauth_callback]
        body = {"oauth_callback": params[:oauth][:oauth_callback]}
      elsif params[:oauth][:oauth_verifier]
        body = {"oauth_verifier": params[:oauth][:oauth_verifier]}  # oauth_verifier only needs to be in the body, not in the signature or authorization headers
      else
        body = {}
      end

      options = {body: body,
      headers: headers}
      if body == {}
        options = {headers: headers}
      end
      puts options

      respons = HTTParty.post(params[:oauth][:url], options)

      puts respons
      if respons.include?("&")
        twinfo = OAuth::Helper.parse_header(respons)

        oauth_token = twinfo["token"]
        oauth_token_secret = twinfo["oauth_token_secret"]
        user_id=twinfo["user_id"]
        screen_name=twinfo["screen_name"]
        oauth_callback_confirmed = (twinfo["oauth_callback_confirmed"] == "true")

        render json: {oauth_token: oauth_token,
        oauth_token_secret: oauth_token_secret,
        user_id: user_id,
        screen_name: screen_name,
        oauth_callback_confirmed: oauth_callback_confirmed}
      else
        render json: {response: respons}
      end

  end

  def collect_oauth_verifier  #Twitter redirects the user here
      oauth_token = params[:oauth_token]
      oauth_verifier = params[:oauth_verifier]

      puts 'oauth token: ', oauth_token
      puts 'oauth verifier: ', oauth_verifier

      redirect_to "http://localhost:3001/twitter/#{oauth_token}/#{oauth_verifier}"
  end


  private
    def auth_params
      params.require(:user).permit(:email, :screen_name, :oauth_token, :oauth_token_secret)
    end

    def oauth_params
      params.require(:oauth).permit(:status, :oauth_consumer_key, :oauth_nonce, :oauth_timestamp, :oauth_token, :oauth_verifier, :http_method, :url, :tts)
    end

    def generate_key(size=32)
      Base64.encode64(OpenSSL::Random.random_bytes(size)).gsub(/\W/, '')
    end


end
