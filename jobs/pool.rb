require 'bundler/setup'
require 'json'
require 'yaml'

# common config file
dashing_config = './config.yaml'
config = YAML.load_file(dashing_config)

last = {}
config['pools'].keys.each do |name|
    last[name] = 0
end

SCHEDULER.every '5s' do

  result = %x( sudo ceph df -f json )

  # update total storage widget
#{"stats":{"total_bytes":6501292834816,"total_used_bytes":5402132480,"total_avail_bytes":6495890702336},"pools":[{"name":"testbed","id":1,"stats":{"kb_used":0,"bytes_used":0,"percent_used":0.000000,"max_avail":3081435348992,"objects":0}}]}
  storage = JSON.parse(result)
#  send_event('storage', { value: storage['stats']['total_used'].to_i, min: 0, max: storage['stats']['total_space'].to_i } )
  send_event('storage', { value: storage['stats']['total_used_bytes'].to_i, min: 0, moreinfo: "out of ", max:storage['stats']['total_avail_bytes']} )
#  send_event('storage', { moreinfo: "out of HAHA"}) ##, storage['stats']['total_avail_bytes']})
  # update each of the config pools widgets
  config['pools'].keys.each_with_index do |poolname, index|
    for pool in storage['pools'] do
      if pool['name'] == poolname
        send_event("pool#{index}", { current: pool['stats']['bytes_used'], last: last[pool['name']], 
                                     title: config['pools'][poolname]['display_name'] } )
        last[pool['name']] = pool['stats']['bytes_used']
      end
    end
  end

end
