# frozen_string_literal: true

describe "login", type: :feature do # rubocop:disable Metrics/BlockLength
  it "signs me in" do
    visit "/embed_uri"
    fill_in "Username", with: "username@email.com"
    fill_in "Password", with: "password"
    click_button "Sign In"
    expect(URI.parse(page.current_url)).to have_attributes(
      scheme: "http",
      host: "app.test",
      port: 80,
      path: "/session",
      query: match(/^id_token=[^&#]+$/)
    )
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

  context "with MOKTA_REDIRECT_URL" do
    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("MOKTA_REDIRECT_URL", anything)
                                   .and_return("http://app.test:3000/redirect_url")
    end

    it "signs me in" do
      visit "/embed_uri"
      fill_in "Username", with: "username@email.com"
      fill_in "Password", with: "password"
      click_button "Sign In"
      expect(page.current_path).to eq "/redirect_url"
    end
  end

  context "with 2FA" do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("OTP_SECRET").and_return("secret")
    end

    it "signs me in" do
      visit "/embed_uri"
      fill_in "Username", with: "username@email.com"
      fill_in "Password", with: "password"
      click_button "Sign In"
      fill_in "Enter Code", with: ROTP::TOTP.new("secret").now
      click_button "Verify"
      expect(page.current_path).to eq "/session"
    end
  end
end
