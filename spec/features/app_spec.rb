# frozen_string_literal: true

require_relative "../../app"

describe "login", type: :feature do
  it "signs me in" do
    visit "/embed_uri"
    fill_in "Username", with: "username@email.com"
    fill_in "Password", with: "password"
    click_button "Sign In"
    expect(page.current_path).to eq "/login"
  end

  it "signs me out if redirect provided" do
    visit "/signout?fromURI=http://app.test/session"
    expect(page.current_path).to eq "/session"
  end

  it "openid_config_uri" do
    visit "/openid_config_uri"
    expect(JSON.parse(page.body)).to eq(
      "jwks_uri" => "http://okta.test/jwks_uri",
      "issuer" => "https://cadev.oktapreview.com"
    )
  end

  it "jwks_uri" do
    visit "jwks_uri"
    expect(JSON.parse(page.body)["keys"].first).to include(
      "use" => "sig",
      "kid" => "kid"
    )
  end
end
