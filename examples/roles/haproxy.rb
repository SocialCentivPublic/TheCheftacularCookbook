name          "haproxy"
description   "The basic role for a node set to run a load balancer. Needs to have a codebase defined. The codebase will not be installed, but will tell the LB what servers to stand in for."
run_list      "recipe[TheCheftacularCookbook::haproxy_setup]"
