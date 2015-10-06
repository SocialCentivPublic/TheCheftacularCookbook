name          "business_logic_cookbook_loader"
description   "A special role for cookbooks that won't normally load anything from a business logic cookbook by default."
run_list      "recipe[SocialCentiv::blank_loading_recipe]"
