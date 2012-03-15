# Rockit [![Build Status](https://secure.travis-ci.org/bwillis/rockit.png?branch=master)](http://travis-ci.org/bwillis/rockit)

Rockit is a dsl to help setup, detect changes and keep your environment up-to-date so you can start working as fast as possible.

## Install

```gem install rockit-?```

## How to use

Rockit is run at the command line and can be followed by other commands to execute after.

Command line :

```rockit <any command>```

Include in a ruby file :

```ruby
require 'rockit'
Rockit.now
```

## RockitFile Configuration

Rockit requires a RockitFile for configuration. This is where you use ruby code and some helpful methods to define your environment. It is highly recommended that you commit your configuration to ensure quick and easy setup.

### Commands and Services

All applications require certain commands and services are available before you can get going. If you want to just require these print a message and exit you can use these shortcuts :

```ruby
command "convert"
service "mysql"
```

For more control when the services or commands are missing you can use the following syntax :

```ruby
if_command_missing "convert" do
  puts "required command 'convert' is not available."
  exit
end

if_service_not_running "mysql" do
  puts "required service 'mysql' is not running."
  exit
end
```

### Changes

Applications environments are always changing and your local environment needs to react to them. For instance, when working in a rails team, migrations and gems are often changed and need to be updated. Add the following to your configurtion to detect changes and automatically keep stay up-to-date :

```ruby
if_directory_changed("db/migrate") do
  run "rake db:migrate"
end

if_file_changed("Gemfile") do
  run "bundle"
end
```

### Documentation and Examples

Documentation is available : TBD

You can find [example configurations](http://github.com/bwillis/rockit/blob/master/example/Rockitfile)

# License

TBD