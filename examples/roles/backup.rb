name          "backup"
description   "The base role for systems that will become a backup server"
run_list      "recipe[TheCheftacularCookbook::backup_server_setup]"
