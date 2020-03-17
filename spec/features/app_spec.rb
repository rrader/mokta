# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
describe "login", type: :feature do
  context "config" do
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

  context "signin" do
    it "signs me in with the expected claims" do
      visit "/embed_uri"
      fill_in "Username", with: "Foo.Bar_Foe Fee@email.com"
      fill_in "Password", with: "password"
      click_button "Sign In"
      uri = URI.parse(page.current_url)
      expect(uri).to have_attributes(
        scheme: "http",
        host: "app.test",
        port: 4001,
        path: "/session",
        query: match(/^id_token=[^&#]+$/)
      )
      expect(decode_claims(uri.query.sub(/^id_token=/, "")).first).to include(
        "sub" => Digest::SHA1.hexdigest("foo.bar.foe.fee@citizensadvice.org.uk"),
        "family_name" => "Fee",
        "given_name" => "Foo Bar Foe",
        "preferred_username" => "foo.bar.foe.fee@citizensadvice.org.uk",
        "zoneinfo" => "Europe/London"
      )
    end

    context "without domain" do
      it "signs me in" do
        visit "/embed_uri"
        fill_in "Username", with: "username"
        fill_in "Password", with: "password"
        click_button "Sign In"

        expect(page.current_path).to eq "/session"
        uri = URI.parse(page.current_url)
        expect(decode_claims(uri.query.sub(/^id_token=/, "")).first).to include(
          "sub" => Digest::SHA1.hexdigest("test.username@citizensadvice.org.uk"),
          "family_name" => "username",
          "given_name" => "Test",
          "preferred_username" => "test.username@citizensadvice.org.uk",
          "zoneinfo" => "Europe/London"
        )
      end
    end

    context "without email" do
      it "signs me in" do
        visit "/embed_uri"
        click_button "Sign In"
        expect(page.current_path).to eq "/session"
        uri = URI.parse(page.current_url)
        expect(decode_claims(uri.query.sub(/^id_token=/, "")).first).to include(
          "sub" => Digest::SHA1.hexdigest("test.user@citizensadvice.org.uk"),
          "family_name" => "User",
          "given_name" => "Test",
          "preferred_username" => "test.user@citizensadvice.org.uk",
          "zoneinfo" => "Europe/London"
        )
      end
    end

    context "with custom claims" do
      it "signs me in" do
        visit "/embed_uri"
        fill_in "Username", with: "username"
        fill_in "Password", with: "password"
        fill_in "Custom", with: "bar"
        click_button "Sign In"
        expect(page.current_path).to eq "/session"
        uri = URI.parse(page.current_url)
        expect(decode_claims(uri.query.sub(/^id_token=/, "")).first).to include(
          "sub" => Digest::SHA1.hexdigest("test.username@citizensadvice.org.uk"),
          "family_name" => "username",
          "given_name" => "Test",
          "preferred_username" => "test.username@citizensadvice.org.uk",
          "foo" => "bar",
          "zoneinfo" => "Europe/London"
        )
      end
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

      context "wrong code" do
        it "does not sign me in" do
          visit "/embed_uri"
          fill_in "Username", with: "username@email.com"
          fill_in "Password", with: "password"
          click_button "Sign In"
          fill_in "Enter Code", with: "foo"
          click_button "Verify"
          expect(page.current_path).to eq "/login"
          expect(page).to have_content("Code not verified")
        end
      end
    end
  end

  context "signout" do
    it "signs me out if redirect provided" do
      visit "/signout?fromURI=http://app.test:4001/foo"
      expect(page.current_path).to eq "/foo"
    end

    context "invalid signout host" do
      it "does not redirect" do
        visit "/signout?fromURI=http://invalid/foo"
        expect(page.current_path).to eq "/signout"
      end
    end

    context "invalid signout port" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("URL_HOST")
                                  .and_return("http://app.test:4000")
      end

      it "does not redirect" do
        visit "/signout?fromURI=http://app.test:3000/foo"
        expect(page.current_path).to eq "/signout"
      end
    end
  end
end

def decode_claims(claims)
  JWT.decode claims,
             Auth::KEY.public_key,
             true,
             algorithm: "RS256",
             iss: env_issuer,
             aud: env_audience,
             verify_iss: true,
             verify_aud: true,
             verify_jti: true,
             verify_iat: true
end

# rubocop:enable Metrics/BlockLength
