name          "sensu_build"
description   "The intermediate role for a node set to become a sensu build server."
run_list      "recipe[TheCheftacularCookbook::sensu_build_setup]"
