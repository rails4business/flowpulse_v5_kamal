require "test_helper"

module BrandEditorial
  class BookLocatorTest < ActiveSupport::TestCase
    test "preferisce il libro nella cartella del Brand" do
      directory = BookLocator.new.find("postura-corretta-in-un-mese")

      assert_equal Rails.root.join("config/data/brands/posturacorretta/books/postura-corretta-in-un-mese"), directory
    end

    test "mantiene i libri globali come compatibilita temporanea" do
      directory = BookLocator.new.find("il-corpo-un-mondo-da-scoprire")

      assert_equal Rails.root.join("config/data/books/il-corpo-un-mondo-da-scoprire"), directory
    end
  end
end
