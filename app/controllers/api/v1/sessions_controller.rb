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
    # This function is to compose the Oauth 1.0a signature and generate the auth string
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
      "oauth_callback" => oauth_callback,
      "oauth_consumer_key" => oauth_consumer_key,
      "oauth_nonce" => oauth_nonce,
      "oauth_signature_method" => oauth_signature_method,
      "oauth_timestamp" => oauth_timestamp,
      "oauth_token" => oauth_token,
      "oauth_version" => oauth_version,
      "status" => status}


    escaped_values = my_hash.values.map do |item|  # Percent encode every key and value that will be signed.
      OAuth::Helper::escape(item)
    end
    escaped_keys = my_hash.keys.map do |key|
      OAuth::Helper::escape(key)
    end

    # We must account for values which may not be passed in.  If they are not passed in we must avoid encoding them in the signature.

    if status == ""
      idx = escaped_keys.find_index("status")
      escaped_keys.delete("status")
      escaped_values.delete_at(idx)
    end

    if oauth_token == ""
      idx = escaped_keys.find_index("oauth_token")
      escaped_keys.delete("oauth_token")
      escaped_values.delete_at(idx)
    end

    if include_entities == ""
      idx = escaped_keys.find_index("include_entities")
      escaped_keys.delete("include_entities")
      escaped_values.delete_at(idx)
    end

    if oauth_callback == ""
      idx = escaped_keys.find_index("oauth_callback")
      escaped_keys.delete("oauth_callback")
      escaped_values.delete_at(idx)
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

    # Now build the authorization string

    dst = "OAuth "

    oauth_keys = ['oauth_callback', 'oauth_consumer_key', 'oauth_nonce', 'oauth_signature', 'oauth_signature_method', 'oauth_timestamp', 'oauth_token', 'oauth_version'].map do |t|
      OAuth::Helper::escape(t)
    end

    # oauth_signature = "tnnArxj06cWHq44gCs1OSKk/jLY="   ..this was for troubleshooting

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
    puts dst

    render json: {signature: oauth_signature,
                  auth: dst,
                  status: status,
                  include_entities: include_entities,
                  oauth_consumer_key: oauth_consumer_key,
                  oauth_nonce: oauth_nonce,
                  oauth_signature_method: oauth_signature_method,
                  oauth_timestamp: oauth_timestamp,
                  oauth_token: oauth_token,
                  oauth_version: oauth_version,
                  oauth_consumer_secret: escaped_consumer_secret,
                  tts: escaped_tts
                }

      headers = {Authorization: dst}
      options = {body: {
        "oauth_callback": "oob"
        },
      headers: headers}
      respons = HTTParty.post(params[:oauth][:url], options)

      puts respons

  end


  private
    def auth_params
      params.require(:user).permit(:email, :password)
    end

    def oauth_params
      params.require(:oauth).permit(:status, :oauth_consumer_key, :oauth_nonce, :oauth_timestamp, :oauth_token, :http_method, :url, :tts)
    end

    def generate_key(size=32)
      Base64.encode64(OpenSSL::Random.random_bytes(size)).gsub(/\W/, '')
    end


end
