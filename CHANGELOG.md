All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).


## Unreleased

- Digest includes the [unmasked Rails CSRF token](https://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection.html#method-i-real_csrf_token) in case a Rails controller manually rotates the token.  

## 0.3.1 - 2022-07-19

- Fix a bug where we would not strip HTML responses with an embedded charset (e.g. `text/html; charset=utf-8`).

## 0.3.0 - 2022-05-13

- Support for old Rack 1.4.7 (last version supported by Rails 3.2)
- No longer depends on activesupport.

## 0.2.3 - 2022-05-12

- Don't depend on `byebug` being in the user bundle.

## 0.2.2 - 2022-05-12

- Don't raise an error when processing binary content.

## 0.2.1 - 2022-05-12

- Only strip patterns for HTML and XHTML responses.

## 0.2.0 - 2022-05-12

- Be more compatible with Rack 2.2.3:
  - Always set a `Cache-Control` header, even for responses that we don't try to digest.
- Strip patterns for responses with `Cache-Control: public`
- Requires Rack 2.x (we want to break with Rack 3)

## 0.1.1 - 2022-05-16

- Activate rubygems MFA

## 0.1.0 - 2021-12-01

- initial release
