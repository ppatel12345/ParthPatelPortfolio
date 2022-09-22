"""
Name: Parth Patel
Date: 11/12/2020
Program: Create a weather application that tells the user the weather
Description: This program is suppose to create a weather application that allows the user to input the city or zipcode
and return the weather for that input. The user can continue asking for new weather until they quit the application
"""

import requests
from requests.exceptions import HTTPError


def main():
    print('Welcome to the weather application')
    while True:  # main loop
        while True:  # loop for zip_city_input, 1 or 2 required to move forward
            zip_city_input = input('To get the temperature by city press 1 or by zipcode press 2:')
            if zip_city_input == '1':
                break
            elif zip_city_input == '2':
                break
            else:
                print('Please enter 1 or 2!')
        user_input(zip_city_input)
        while True:  # loop to continue program, Y or N required
            continueProgram_input = input('\nWould you like to continue, Y or N?').upper()
            if continueProgram_input == 'Y':
                break
            elif continueProgram_input == 'N':
                print('Goodbye!')
                break
            else:
                print(
                    'That is not a valid input! Try Again')  # if Y or N not entered, loop back to continueProgram_input
        if continueProgram_input == 'Y':  # will continue main loop
            continue
        elif continueProgram_input == 'N':  # will end main loop
            break


def user_input(zip_city_input):
    while True:
        if zip_city_input == '1':
            api_base_url = 'http://api.openweathermap.org/data/2.5/weather?q='  # url for city input
            zip_city = 'City'
            while True:
                UserInput = input('Please enter a US city:')
                if UserInput.replace(' ', '').isalpha() is True:  # allow for input such as Las Vegas
                    break
                else:
                    print('That is not a city!')
            while True:
                UserCityInput = input('Please enter a US state abbreviation:')
                if len(UserCityInput) == 2 and UserCityInput.isalpha():
                    break
                else:
                    print('That is not a valid state abbreviation!')
            UserInput = UserInput + ',' + UserCityInput + ',US'  # combine city and state entry
            break
        if zip_city_input == '2':
            api_base_url = 'http://api.openweathermap.org/data/2.5/weather?zip='  # url for zipcode input
            zip_city = 'Zipcode'
            while True:
                UserInput = input('Please enter a zipcode:')
                if UserInput.isdigit() and len(UserInput) == 5:
                    break
                else:
                    print('That is not a zipcode, please try again!')
            break
    weather(UserInput, api_base_url, zip_city)


def weather(UserInput, api_base_url, zip_city):
    api = 'f31aab3b7dcb7491174f9effae026bf1'
    full_url = '{}{}&appid={}&units=imperial'.format(api_base_url, UserInput, api)
    response = requests.get(full_url)
    temp_data_json = response.json()
    try:
        response = requests.get(full_url)
        response.raise_for_status()
        pretty_print(temp_data_json)
    except HTTPError:
        print('\nConnection not successful:', zip_city, 'entered is incorrect!')


def pretty_print(temp_data_json):
    temp_settings = temp_data_json['main']  # main temperature data
    city_name = temp_data_json['name']  # get city name
    temperature = temp_settings['temp']  # get current temperature
    temp_feels_like = temp_settings['feels_like']  # feels like temperature
    temp_min = temp_settings['temp_min']  # min temperature
    temp_max = temp_settings['temp_max']  # max tempature
    humidity = temp_settings['humidity']  # get humidity
    pressure = temp_settings['pressure']  # get pressure
    report = temp_data_json['weather']  # get weather report
    print('\nSuccessful Connection\n')
    print('City:', city_name)
    print('Temperature: {}{}'.format(temperature, 'F'))
    print('Feels like: {}{}'.format(temp_feels_like, 'F'))
    print('Minimum Temperature: {}{}'.format(temp_min, 'F'))
    print('Maximum Temperature: {}{}'.format(temp_max, 'F'))
    print('Humidity:', humidity)
    print('Pressure:', pressure)
    print('Weather Report:', report[0]['description'])
    # print(temp_data_json)


if __name__ == '__main__':
    main()

