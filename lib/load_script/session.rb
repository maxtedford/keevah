require "logger"
require "pry"
require "capybara"
require "capybara/poltergeist"
require "faker"
require "active_support"
require "active_support/core_ext"

module LoadScript
  class Session
    include Capybara::DSL
    attr_reader :host
    
    def initialize(host = nil)
      Capybara.default_driver = :poltergeist
      @host = host || "http://localhost:3000"
    end

    def logger
      @logger ||= Logger.new("./log/requests.log")
    end

    def session
      @session ||= Capybara::Session.new(:poltergeist)
    end

    def run
      while true
        run_action(actions.sample)
      end
    end

    def run_action(name)
      benchmarked(name) do
        send(name)
      end
    rescue Capybara::Poltergeist::TimeoutError
      logger.error("Timed out executing Action: #{name}. Will continue.")
    end

    def benchmarked(name)
      logger.info "Running action #{name}"
      start = Time.now
      val = yield
      logger.info "Completed #{name} in #{Time.now - start} seconds"
      val
    end

    def actions
      [:browse_loan_requests, :browse_pages_of_loan_requests, :browse_categories, :browse_pages_of_categories, :view_individual_loan_request, :sign_up_as_lender, :sign_up_as_borrower, :borrower_creates_loan_request, :lender_makes_loan]
    end

    def browse_loan_requests
      puts "browsing loan request"
      session.visit "#{host}/browse"
      session.all(".lr-about").sample.click
    end

    def browse_pages_of_loan_requests
      log_in
      puts "browsing loan request pages"
      session.visit "#{host}/browse"
      session.all(".pagination a").sample.click
    end

    def browse_categories
      log_in
      puts "browsing categories"
      session.visit "#{host}/browse"
      session.all(".pull-left a").sample.click
    end
    
    def browse_pages_of_categories
      log_in
      puts "browsing pages of categories"
      sessions.visit "#{host}/browse"
      session.all(".pull-left a").sample.click
      session.all(".pagination a").sample.click
    end
    
    def view_individual_loan_request
      log_in
      puts "viewing individual loan request"
      session.visit "#{host}/browse"
      session.all("a.lr-about").sample.click
    end

    def sign_up_as_lender(name = new_user_name)
      puts "signing up as lender"
      log_out
      session.find("#sign-up-dropdown").click
      session.find("#sign-up-as-lender").click
      session.within("#lenderSignUpModal") do
        session.fill_in("user_name", with: name)
        session.fill_in("user_email", with: new_user_email(name))
        session.fill_in("user_password", with: "password")
        session.fill_in("user_password_confirmation", with: "password")
        session.click_link_or_button "Create Account"
      end
    end

    def sign_up_as_borrower(name = new_user_name)
      puts "signing up as new borrower"
      log_out
      session.visit "#{host}"
      session.find("#sign-up-dropdown").click
      session.find("#sign-up-as-borrower").click
      session.within("#borrowerSignUpModal") do
        session.fill_in("user_name", with: name)
        session.fill_in("user_email", with: new_user_email(name))
        session.fill_in("user_password", with: "password")
        session.fill_in("user_password_confirmation", with: "password")
        session.click_link_or_button("Create Account")
      end
    end
    
    def borrower_creates_loan_request
      sign_up_as_borrower
      session.click_on("Create Loan Request")
      session.within("#loanRequestModal") do
        session.fill_in("loan_request_title", with: new_request_title)
        session.fill_in("loan_request_description", with: new_request_description)
        session.fill_in("loan_request_requested_by_date", with: new_request_by_date)
        session.fill_in("loan_request_repayment_date", with: new_repayment_date)
        session.select("Education", from: "loan_request_category")
        session.fill_in("loan_request_amount", with: "500")
        session.click_link_or_button("Submit")
      end
    end
    
    def lender_makes_loan
      sign_up_as_lender
      view_individual_loan_request
      session.click_on("Contribute $25")
      session.click_on("Basket")
      session.click_on("Transfer Funds")
    end
    
    def log_in(email="demo+horace@jumpstartlab.com", pw="password")
      puts "logging in"
      log_out
      session.visit host
      session.click_link("Log In")
      session.fill_in("email_address", with: email)
      session.fill_in("password", with: pw)
      session.click_link_or_button("Login")
    end
    
    def log_out
      puts "logging out"
      session.visit host
      if session.has_content?("Log out")
        session.find("#logout").click
      end
    end

    def new_user_name
      "#{Faker::Name.name} #{Time.now.to_i}"
    end

    def new_user_email(name)
      "TuringPivotBots+#{name.split.join}@gmail.com"
    end

    def categories
      ["raspberry", "honeydew", "tomato", "apple", "banana", "peach", "orange", "plum", "mango", "grape", "tangerine", "lemon", "coconut", "strawberry", "blueberry"]
    end

    def new_request_title
      "#{Faker::Commerce.product_name} #{Time.now.to_i}"
    end

    def new_request_description
      Faker::Company.catch_phrase
    end

    def new_request_by_date
      Faker::Time.between(7.days.ago, 3.days.ago)
    end

    def new_repayment_date
      Faker::Time.between(3.days.ago, Time.now)
    end
  end
end
