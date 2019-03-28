require 'bundler/setup'
require 'json'
require 'yaml'

# common config file
dashing_config = './config.yaml'
config = YAML.load_file(dashing_config)

points_rd = []
points_wr = []

points_iopsr = []
points_iopsw = []
(1..10).each do |i|
  points_rd << { x: i, y: 0 }  # graph 1 initialization
  points_wr << { x: i, y: 0 }  # graph 2 initialization
  points_iopsr << { x: i, y: 0 }  # graph 1 initialization
  points_iopsw << { x: i, y: 0 }  # graph 2 initialization
end

# detect if ceph osd pool stats is available (>=emperor)
result = %x( sudo ceph osd pool stats -f json 2>&1)
begin
  poolstats = JSON.parse(result)
  poolstats_available = true
rescue
  poolstats_available = false  
end
 
SCHEDULER.every '4s' do

  points_rd.shift
  points_wr.shift
  points_rd << { x: points_rd.last[:x] + 1, y: 0 }
  points_wr << { x: points_wr.last[:x] + 1, y: 0 }


  points_iopsr.shift
  points_iopsw.shift
  points_iopsr << { x: points_iopsr.last[:x] + 1, y: 0 }
  points_iopsw << { x: points_iopsw.last[:x] + 1, y: 0 }

  # if ceph osd pool stats is available, get the rw stats from that.
  # otherwise, use ceph status, available in dumpling.
  if poolstats_available
    result = %x( sudo ceph osd pool stats -f json )
    poolstats = JSON.parse(result)
    #[{"pool_name":"testbed","pool_id":1,"recovery":{},"recovery_rate":{},"client_io_rate":{}},{"pool_name":"mdspool","pool_id":2,"recovery":{},"recovery_rate":{},"client_io_rate":{}},{"pool_name":"datapool","pool_id":3,"recovery":{},"recovery_rate":{},"client_io_rate":{"write_bytes_sec":1593119,"read_op_per_sec":0,"write_op_per_sec":270}}]
    poolstats.each do |poolstat|
      if poolstat['client_io_rate'].has_key?('read_bytes_sec')
        points_rd.last[:y] = points_rd.last[:y] + poolstat['client_io_rate']['read_bytes_sec'].to_i
      end
      if poolstat['client_io_rate'].has_key?('write_bytes_sec')
        points_wr.last[:y] = points_wr.last[:y] + poolstat['client_io_rate']['write_bytes_sec'].to_i
      end
      if poolstat['client_io_rate'].has_key?('read_op_per_sec')
        points_iopsr.last[:y] = points_iopsr.last[:y] + poolstat['client_io_rate']['read_op_per_sec'].to_i
      end
      if poolstat['client_io_rate'].has_key?('write_op_per_sec')
        points_iopsw.last[:y] = points_iopsw.last[:y] + poolstat['client_io_rate']['write_op_per_sec'].to_i
      end
    end
  else
    result = %x( sudo ceph status -f json )
    status = JSON.parse(result)

    if status['pgmap'].has_key?('read_bytes_sec')
      points_rd.last[:y] = points_rd.last[:y] + status['pgmap']['read_bytes_sec'].to_i
      points_iopsr.last[:y] = points_iopsr.last[:y] + status['pgmap']['read_op_per_sec'].to_i
    end
    if status['pgmap'].has_key?('write_bytes_sec')
      points_wr.last[:y] = points_wr.last[:y] + status['pgmap']['write_bytes_sec'].to_i
      points_iopsw.last[:y] = points_iopsw.last[:y] + status['pgmap']['write_op_per_sec'].to_i
    end
  end
  send_event('traffic', points: [points_rd, points_wr])
  send_event('iopstraffic', ipoints: [points_iopsr, points_iopsw])
end
