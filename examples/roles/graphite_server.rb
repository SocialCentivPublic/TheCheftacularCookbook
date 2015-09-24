name          "graphite_server"
description   "The basic role for a node set to become a graphite server."
run_list      "recipe[TheCheftacularCookbook::graphite_server_setup]"
