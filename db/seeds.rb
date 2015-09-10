require "populator"

class Seed
  def run
    create_known_users
    create_borrowers(31000)
    create_lenders(201000)
    create_loan_requests_for_each_borrower(500000)
    create_categories
    attach_loan_requests_to_categories(500000)
    create_orders
  end

  def lenders
    User.where(role: 0)
  end

  def borrowers
    User.where(role: 1)
  end

  def orders
    Order.all
  end

  def create_known_users
    User.create(name: "Jorge", email: "jorge@example.com", password: "password")
    User.create(name: "Rachel", email: "rachel@example.com", password: "password")
    User.create(name: "Josh", email: "josh@example.com", password: "password", role: 1)
  end

  def create_lenders(quantity)
    User.populate(quantity) do |user|
      user.name = Faker::Name.name
      user.email = Faker::Internet.email
      user.password_digest = "$2a$10$G3BpQrzzJAvyFlAqHUDAu.UlHwMGiswSsLRnhAS2DOmIhc7l1.ihK"
      user.role = 0
    end
  end

  def create_borrowers(quantity)
    User.populate(quantity) do |user|
      user.name = Faker::Name.name
      user.email = Faker::Internet.email
      user.password_digest = "$2a$10$G3BpQrzzJAvyFlAqHUDAu.UlHwMGiswSsLRnhAS2DOmIhc7l1.ihK"
      user.role = 1
    end
  end
  
  def create_loan_requests_for_each_borrower(quantity)
    brws = borrowers
    
    LoanRequest.populate(quantity) do |lr|
      lr.title = Faker::Commerce.product_name
      lr.description = Faker::Company.catch_phrase
      lr.amount = 200
      lr.status = [0, 1].sample
      lr.requested_by_date = Faker::Time.between(7.days.ago, 3.days.ago)
      lr.repayment_begin_date = Faker::Time.between(3.days.ago, Time.now)
      lr.repayment_rate = 0
      lr.contributed = 0
      lr.repayed = 0
      lr.user_id = brws.sample.id
    end
  end

  def create_categories
    ["raspberry", "honeydew", "tomato", "apple", "banana", "peach", "orange", "plum", "mango", "grape", "tangerine", "lemon", "coconut", "strawberry", "blueberry"].each do |cat|
      Category.create(title: cat, description: cat + " stuff")
    end
    put_requests_in_categories
  end

  def put_requests_in_categories
    LoanRequest.all.each do |request|
      Category.all.sample.loan_requests << request
      puts "linked request and category"
    end
  end

  def create_orders
    loan_requests = LoanRequest.all
    possible_donations = %w(25, 50, 75, 100, 125, 150, 175, 200)
    possible_lenders = (0..200000).to_a
    loan_requests.each do |request|
      donate = possible_donations.sample
      lender = User.find(possible_lenders.sample)
      order = Order.create(cart_items: { "#{request.id}" => donate },
                           user_id: lender.id)
      order.update_contributed(lender)
      puts "Created Order for Request #{request.title} by Lender #{lender.name}"
    end
  end
end

Seed.new.run
