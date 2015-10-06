name          "sensu_client"
description   "The intermediate role for a node set to become a sensu client."
run_list      "recipe[TheCheftacularCookbook::sensu_client_setup]"
