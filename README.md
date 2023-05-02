# Decidim::HalfSignup

Module that enables half signup/signin.

## Usage

This module adds a configuration option in admin panel, enabling users to signin/signup to the platform, without going through the barriers of  account creation process(for the case of signup) and normal flow of authentication through combination of username/email and password (for the case of signing in). Instead, users will receive an email/sms containing a verification code, by which they will be authorized and signed in/up. This feature aims at particularly easing the process of participation during voting phase. This feature is configurable in admin pannel.

## Installation

Add the following to your application's Gemfile:

```ruby
gem "decidim-half_signup", github: "OpenSourcePolitics/decidim-module-half_sign_up", branch: "main"
```

By the time of providing this documentation, this gem was not added to ruby gem. If the gem has been added to the
rubygems, you can add it from the rubygem instead:

```ruby
gem "decidim-half_signup"
```

And then execute:

```bash
bundle
```

## configurations

### Admin configuraitons

In order to enable SMS authentication, you need to integrate your gateway to this module using your customized adapter designed for that particular SMS provider, unless you are using Twilio gateway, inwhich case, you only need to configure your gateway credential and configurations (please refer to [decidim-sms-twilio](https://github.com/Pipeline-to-Power/decidim-module-ptp/tree/main/decidim-sms-twilio), or [Twilio](https://www.twilio.com/)).

After successfully installing the module, you should be able to see "Authentication settings" option in settings, as shown here:
![Half-signup authentication enabler](half_singup_authentication.png).

- "Enable partial sign up and sign in using SMS verification": Enabling this option empowers users to signin or signup via their cellphone.
- "Enable partial sign up and sign in using email verification": Enabling this option enables users to signin or signup via their email address.
- Disabling both of abovementioned options falls the login flow to the normal decidim.

### Hard coded configurations

The following configurations are availble through hard-coding (from lib/decidim/half_signup.rb):

#### Default country/countries

The default country to be shown for sms authentication is set to the US by default, but you can change it to any other country by providing two-letter country codes defined in ISO 3166-1,  as default country/countries like:
```ruby
config_accessor :default_countries do
# change this to the country/countries you want to be shown at the top(the first option will be selected by default)
      [:fi, :se]
    end
```

#### Show tos agreement for the signup

This is the configuration to enable or disable agree to the terms and conditions page for new users who create their account. The default is set to true, meaning that new users will be redirected to the agree to the terms and conditions page after creting the account.

```ruby
  config_accessor :show_tos_page_after_signup do
  # change this to false, if you dont want to redirect the user to the tos agreement page
      true
    end
```

#### Auth code length

You can define the length of generated authentication code; The default value is set to 4, which means every time the user requests a verification code, a four-digit code is generated and being sent to the user. It is recommended to set the value between 4 and 7, as choosing a value higher than 7 could potentially cause unexpected design issues and negatively impact the website's layout.

```ruby
config_accessor :auth_code_length do
# change this to other values if you want to change the length of generated code (be advised to remain in an acceptable limits for the sake of best performance)
      4
    end
```

## Testing

To run the tests, run the following in the gem development path:

```bash
$ bundle
$ DATABASE_USERNAME=<username> DATABASE_PASSWORD=<password> bundle exec rake test_app
$ DATABASE_USERNAME=<username> DATABASE_PASSWORD=<password> bundle exec rspec
```

Note that the database user has to have rights to create and drop a database in
order to create the dummy test app database.

In case you are using [rbenv](https://github.com/rbenv/rbenv) and have the
[rbenv-vars](https://github.com/rbenv/rbenv-vars) plugin installed for it, you
can add these environment variables to the root directory of the project in a
file named `.rbenv-vars`. In this case, you can omit defining these in the
commands shown above.

## Test code coverage

If you want to generate the code coverage report for the tests, you can use
the `SIMPLECOV=1` environment variable in the rspec command as follows:

```bash
$ SIMPLECOV=1 bundle exec rspec
```

This will generate a folder named `coverage` in the project root which contains
the code coverage report.


## Contributing

See [Half-signup authentication enabler](https://github.com/decidim/decidim).

## License

This engine is distributed under the GNU AFFERO GENERAL PUBLIC LICENSE.
