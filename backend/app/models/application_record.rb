class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Whole-string http(s) URL match. URI's regexp is unanchored on its own, so
  # values like "javascript:alert(1)//https://x.com" would otherwise pass.
  HTTP_URL_FORMAT = /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/
end
