# Decidim::HalfSignup

This module adds a configuration option in admin panel, enabling users to signin/signup to the platform, without going through the barriers of  account creation process(for the case of signup) and normal flow of authentication through combination of username/email and password (for the case of signing in). Instead, users will receive an email/sms containing a verification code, by which they will be authorized and signed in/up. This feature aims at particularly easing the process of participation during voting phase. This feature is configurable in admin panel.

## Usage

After successfully installing the module, you should be able to see "Authentication settings" option in settings in your back-office, as shown here:
![Half-signup authentication enabler](half_signup_authentication.png).

## Installation

Add the following to your application's Gemfile:

```ruby
gem "decidim-half_signup", github: "OpenSourcePolitics/decidim-module-half_sign_up", branch: "release/0.26-stable"
```

By the time of providing this documentation, this gem was not added to ruby gem. If the gem has been added to the
rubygems, you can add it from the rubygems instead:

```ruby
gem "decidim-half_signup"
```

And then execute:

```bash
bundle
```

## configurations

### Admin configurations

In order to enable SMS authentication, you need to integrate your gateway to this module using your customized adapter designed for that particular SMS provider, unless you are using Twilio gateway, in which case, you only need to configure your gateway credential and configurations (please refer to [decidim-sms-twilio](https://github.com/Pipeline-to-Power/decidim-module-ptp/tree/main/decidim-sms-twilio), or [Twilio](https://www.twilio.com/)).

The following options are available in admin panel, after adding this module:

- "Enable partial sign up and sign in using SMS verification": Enabling this option empowers users to signin or signup via their cellphone.
- "Enable partial sign up and sign in using email verification": Enabling this option enables users to signin or signup via their email address.
- Disabling both of above-mentioned options falls the login flow to the normal decidim.

### Hard coded configurations

The following configurations are available through hard-coding. To do so, add an initializer inside your config/initializer folder. After that, the following configuration options are available:

```ruby
# config/initializers/half_singup.rb
Decidim::HalfSignup.configure do |config|
  config.show_tos_page_after_signup = true
  # change this to false, if you don't want to redirect the user to the tos agreement page

  config.auth_code_length = 4
  # change this to other values if you want to change the length of generated code (be advised to remain in an acceptable limits for the sake of best performance)

  config.default_countries = [:us]
  # change ':us' to the country/countries you want to be shown at the top(the first option will be selected by default).
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

See [Decidim](https://github.com/decidim/decidim).

## License

This engine is distributed under the GNU AFFERO GENERAL PUBLIC LICENSE.
