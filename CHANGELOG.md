# Current changes

 - Adding additional default configuration files, mimicing rake behavior
 - Avoid failing for [if_service_not_running, if_command_missing] if the block returns true
 - Add verbose mode to print all commands, accessible from the dsl :
  - ```verbose_on```
  - ```verbose_off```

# 0.1.0 March 18, 2012

 - Initial DSL definitions for (see docs in [Rockit::Application]):
  - ```if_file_changed```
  - ```if_directory_changed```
  - ```service```
  - ```if_service_not_running```
  - ```command```
  - ```if_command_missing```
  - ```if_first_time```
  - ```if_string_changed```
  - ```if_string_digest_changed```