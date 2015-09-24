name          "sensu_server"
description   "The basic role for a node set to become a sensu server."
run_list      "recipe[TheCheftacularCookbook::sensu_server_setup]"
