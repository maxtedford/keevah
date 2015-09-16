class Category < ActiveRecord::Base
  validates :title, :description, presence: true
  validates :title, uniqueness: true
  has_many :loan_requests_categories
  has_many :loan_requests, through: :loan_requests_categories
  
  def self.all_cats
    Rails.cache.fetch("all-cats-#{Category.last.id}") do
      self.all
    end
  end
end
