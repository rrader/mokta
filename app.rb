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

# OAuth2

get "/oauth2/oauth-authorization-server" do
  json token_endpoint: url("/oauth2/v1/token"), jwks_uri: url("/oauth2/v1/keys")
end

get "/oauth2/v1/keys" do
  json Auth.new.to_jwks
end

post "/oauth2/v1/token" do
  json(
    access_token: JWT.encode(oauth_claims(params), Auth::KEY, "RS256", kid: "kid"),
    token_type: "Bearer",
    expires_in: 3600,
    scope: params[:scope]
  )
end

private

def user_claims
  role = params[:username][/\A(.+)@/, 1] || "test.user"
  read_json(role).merge(time_claims)
end

def oauth_claims(params)
  read_json("oauth")
    .merge(time_claims)
    .merge(scp: params[:scope].split)
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
