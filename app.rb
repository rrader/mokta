# frozen_string_literal: true

require_relative "lib/auth"
require "sinatra"
require "sinatra/json"
require "hamlit"
require "jwt"
require "sinatra/reloader"

enable :reloader
set :root, File.dirname(__FILE__)
set :haml, format: :html5

# Login all the time
post "/login" do
  token = JWT.encode(user_claims, Auth::KEY, "RS256", kid: "kid")
  redirect "#{env_redirect_url}?id_token=#{token}", 307
end

get "/embed_uri" do
  haml :embed_uri_form
end

get "/openid_config_uri" do
  json jwks_uri: url("/jwks_uri"), issuer: env_issuer
end

get "/jwks_uri" do
  json Auth.new.to_jwks
end

get "/signout" do
  return unless params[:fromURI]
  redirect params[:fromURI], 307 if URI(params[:fromURI]).host == ENV["URL_HOST"]
end

private

def user_claims
  role = params[:username][/\A(.+)@/, 1] || "test.user"
  read_json(role).merge(time_claims)
end

def time_claims
  { iat: Time.now.to_i, exp: (Time.now + 3600).to_i }
end

def read_json(file_name)
  JSON.parse(File.read("data/#{file_name}.json"))
end

def env_redirect_url
  ENV.fetch("MOKTA_REDIRECT_URL", "http://#{ENV['URL_HOST']}:3000/session")
end

def env_issuer
  ENV.fetch("MOKTA_ISSUER", "https://cadev.oktapreview.com")
end
