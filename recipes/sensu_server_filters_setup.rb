
sensu_filter "keepalives" do
  attributes(
    check: {
      name: "keepalive"
    }
  )
end
