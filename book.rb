require "json"
require "httparty"
require "pry"
require "selenium-webdriver" # load in the webdriver gem to interact with Selenium

stores_raw = File.read("nyc_stores.json")
stores = JSON.parse(stores_raw)

def check_slots(store)
  resp = HTTParty.get("https://www.riteaid.com/services/ext/v2/vaccine/checkSlots?storeNumber=#{store['storeNumber']}")
  resp["Data"]["slots"]["1"]
end

def try_to_book(store)
  id = store['storeNumber']
  driver = Selenium::WebDriver.for :chrome

  # maximize window
  driver.manage.window.maximize
  puts driver.manage.window.size

  driver.navigate.to "https://www.riteaid.com/pharmacy/covid-qualifier" 

  driver.find_element(id: 'dateOfBirth').send_keys('09/27/1987')
  driver.find_element(id: 'Occupation').click
  driver.find_element(id: 'Occupation').send_keys('None of the Above')
  driver.find_element(id: 'mediconditions').click
  driver.find_element(id: 'mediconditions').send_keys('None of the Above')
  driver.find_element(id: 'city').send_keys('New York')
  driver.find_element(id: 'eligibility_state').click
  driver.find_element(id: 'eligibility_state').send_keys('New York')
  driver.find_element(xpath: "//li[@data-index='0']").click
  driver.find_element(id: 'zip').send_keys("#{store['zipcode']}")
  driver.execute_script("window.scrollTo(0, 400)");
  sleep 2
  driver.find_element(id: 'continue').click
  sleep 2
  driver.find_element(id: 'learnmorebttn').click
  sleep 1

  # Next Page
  driver.execute_script("window.scrollTo(0, 500)");
  sleep 2
  driver.find_element(xpath: "//a[@data-loc-id='#{id}'][contains(text(), 'SELECT THIS')]").click
  driver.execute_script("window.scrollTo(0, 500)");
  sleep 2
  driver.find_element(id: 'continue').click
  sleep 1

  begin
    driver.find_element(xpath: '//p[contains(text(), "Apologies")]')
    driver.quit
    return
  rescue Selenium::WebDriver::Error::NoSuchElementError => e
    begin
      driver.find_element(xpath: '//p[contains(text(), "Something went wrong")]')
      driver.quit
      return
    rescue Selenium::WebDriver::Error::NoSuchElementError => e
      binding.pry
    end
  end
end

stores.each do |k, v|
  try_to_book(v) if check_slots(v)
end
