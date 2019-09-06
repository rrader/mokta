# frozen_string_literal: true

require_relative "lib/auth"
require "sinatra"
require "sinatra/json"
require "hamlit"
require "jwt"
require "sinatra/reloader"
require "rotp"

class OtpFailed < StandardError; end

enable :reloader
set :root, File.dirname(__FILE__)
set :haml, format: :html5

# Login all the time
post "/login" do
  token = JWT.encode(user_claims, Auth::KEY, "RS256", kid: "kid")
  opt = verify_otp
  if opt == false
    haml :otp
  else
    redirect "#{env_redirect_url}?id_token=#{token}", 307
  end
rescue OtpFailed
  @error = "Code not verified"
  status 403
  haml :otp
end

get "/" do
  redirect "embed_uri"
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

  redirect params[:fromURI], 307 if matches_host_origin?(params[:fromURI])
end

session = lambda do
  redirect "embed_uri" unless params[:id_token]

  @claims = JWT.decode params[:id_token],
                       Auth::KEY.public_key,
                       true,
                       algorithm: "RS256",
                       iss: env_issuer,
                       aud: env_audience,
                       verify_iss: true,
                       verify_aud: true,
                       verify_jti: true,
                       verify_iat: true
  haml :session
end

get "/session", &session
post "/session", &session

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
  {
    sub: Digest::SHA1.hexdigest(preferred_username),
    iss: env_issuer,
    aud: env_audience,
    given_name: first_name,
    family_name: last_name,
    preferred_username: preferred_username,
    zoneinfo: "Europe/London"
  }.merge(custom_claims).merge(time_claims)
end

def oauth_claims(params)
  read_json("oauth")
    .merge(time_claims)
    .merge(scp: params[:scope].split)
end

def username_parts
  name = params[:username][/\A([^@]+)/, 1]&.strip || "Test User"
  name = name.split(/[._\s]+/)
  name = ["Test", *name] if name.size == 1
  name
end

def first_name
  username_parts[0...-1].join(" ")
end

def last_name
  username_parts.last
end

def preferred_username
  "#{username_parts.join('.').downcase}@citizensadvice.org.uk"
end

def custom_claims
  params.fetch(:claims, {})
end

def time_claims
  {
    iat: Time.now.to_i,
    jti: Digest::MD5.hexdigest([Auth::KEY, Time.now.to_i].join(":")),
    exp: (Time.now + 3600).to_i
  }
end

def env_redirect_url
  ENV.fetch("MOKTA_REDIRECT_URL", "http://#{ENV['URL_HOST']}/session")
end

def env_issuer
  ENV.fetch("MOKTA_ISSUER", "https://cadev.oktapreview.com")
end

def env_audience
  ENV.fetch("AUTH_AUDIENCE", "mokta")
end

def matches_host_origin?(url)
  uri = URI.parse(url)
  uri.host + (uri.default_port == uri.port ? "" : ":#{uri.port}") == ENV["URL_HOST"]
end

def verify_otp
  return nil unless ENV["OTP_SECRET"]
  return false unless params[:code]
  raise OtpFailed unless ROTP::TOTP.new(ENV["OTP_SECRET"]).verify(params[:code])

  true
end

def presence(value)
  value&.empty? ? nil : value
end
