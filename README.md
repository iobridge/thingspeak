# ThingSpeak

> [!NOTE]
> This archived repository represents an earlier version of the ThingSpeak application.
> The actively maintained version of the application, API, and documentation is available at [thingspeak.com](https://thingspeak.com).
> [Sign up for free](https://thingspeak.com/) and try out the numerous new features, performance and security fixes for your next IoT project.

[ThingSpeak](https://thingspeak.com) is an open "Internet of Things" application and API to store and retrieve data from things using HTTP over the Internet or via a Local Area Network.
With ThingSpeak, you can create sensor logging applications, location tracking applications, and a network of things with status updates.

In addition to storing and retrieving numeric and alphanumeric data, the ThingSpeak API allows for numeric data processing such as timescaling, averaging, median, summing, and rounding.
Each ThingSpeak Channel supports data entries of up to 8 data fields, latitude, longitude, elevation, and status.
The channel feeds support JSON, XML, and CSV formats for integration into applications.

The ThingSpeak application also features time zone management, read/write API key management, and JavaScript-based charts.

## Getting started

### Before you begin

1. Install Ruby 2, RubyGems, Rails 4, git, and a database like MySQL.
2. Download the application using git: `git clone git@github.com:iobridge/thingspeak.git`
3. Change to the `thingspeak` directory and install the gems: `sudo bundle install`

### Configuration

1. Set your database configuration in `config/database.yml` (see `config/database.yml.example` for an example).
2. Create the database: `rake db:create`
3. Create the database tables: `rake db:schema:load`

### Run the application

Start the server:

```sh
rails server
```

The application is now running at http://localhost:3000/.

## Changing application text

Make changes to `config/locales/en.yml`.
To avoid errors, make sure your lines start with spaces, not tabs.

## (Optional) Email setup

Set your `domain`, `user_name`, and `password` in `config/environment.rb`.

## (Optional) Admin setup

1. Open a Rails console with `rails console` or `RAILS_ENV=production rails console`, depending on your environment.
2. Add the admin user:

   ```ruby
   AdminUser.create!(email: 'YOUR_ADMIN_EMAIL@EXAMPLE.COM', password: 'YOUR_PASSWORD', password_confirmation: 'YOUR_PASSWORD')
   ```

3. Exit the Rails console: `exit`
4. Log in to the admin web interface at `http://YOUR_DOMAIN.COM/admin`.

## Installation on a clean install of Ubuntu 12.04 LTS

```sh
sudo apt-get upgrade
sudo apt-get -y install build-essential mysql-server mysql-client libmysqlclient-dev libxml2-dev libxslt-dev git-core curl rubygems
\curl -sSL https://get.rvm.io | bash -s stable
rvm install 2.1
git clone https://github.com/iobridge/thingspeak.git
cd thingspeak
bundle install
cp config/database.yml.example config/database.yml
rake db:create
rake db:schema:load
rails server
```

## Upgrading existing installations

```sh
git pull origin master
bundle install
rake db:migrate
```

If your server is running, restart it: go to its terminal, press Ctrl-C, and run `rails server` again.
