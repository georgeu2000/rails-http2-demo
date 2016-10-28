def get_reviews id
  rnd = Random.new.rand
  sleep rnd

  "#{ id }-{ rnd }"
end

ids = (1..5).to_a

responses = ids.map do | id |
  get_reviews id
end