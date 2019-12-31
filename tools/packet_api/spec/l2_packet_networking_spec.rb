require 'spec_helper'
require "json"

# *** Assign your packet api token in the .env file and then source it before running rspec ***
RSpec.describe 'Packet Test Suite', type: :aruba  do
  context "Packet test" do
    it 'tests bond-interface' do
      # cmd = "ruby ../../l2_packet_networking.rb --server cnftestbed-worker1 --bond-interface eth1 --project-name='CNF Testbed' --packet-url='api.packet.net'" 
      cmd = "ruby ../../l2_packet_networking.rb --server cnftestbed-worker1 --bond-interface eth1 --project-name='CNF Testbed' --packet-url='api.packet.net' --facility='sjc1'" 
      run(cmd)
      sleep(15)
      stop_all_commands

      expect(last_command_started.output).to eq("success\n")
    end

    it 'tests disbond-interface' do
      cmd = "ruby ../../l2_packet_networking.rb --server cnftestbed-worker1 --disbond-interface eth1 --project-name='CNF Testbed' --packet-url='api.packet.net' --facility='sjc1'" 
      run(cmd)
      sleep(15)
      stop_all_commands

      expect(last_command_started.output).to eq("success\n")
    end
    it 'tests create-vlan' do
      cmd = "ruby ../../l2_packet_networking.rb --create-vlan watsonvlan1 --project-name='CNF Testbed' --packet-url='api.packet.net' --facility='sjc1' "
      run(cmd)
      sleep(10)
      stop_all_commands

      expect(last_command_started.output.to_i).to be_a_kind_of(Numeric)
    end
    it 'tests assign-vlan and unassign-vlan' do
      cmd = "ruby ../../l2_packet_networking.rb --create-vlan watsonvlan1 --project-name='CNF Testbed' --packet-url='api.packet.net' --facility='sjc1'"
      run(cmd)
      sleep(10)
      stop_all_commands

      expect(last_command_started.output.to_i).to be_a_kind_of(Numeric)

      # cmd = "ruby ../../l2_packet_networking.rb --server cnftestbed-worker1 --assign-vlan watsonvlan1 --assign-vlan-port eth1 --project-name='CNF Testbed' --packet-url='api.packet.net'" 
      # run(cmd)
      # sleep(10)
      # stop_all_commands
      #
      # puts "last command started output: #{last_command_started.output}"
      # expect(last_command_started.output).to eq("success\n")

      cmd = "ruby ../../l2_packet_networking.rb --server cnftestbed-worker1 --assign-vlan watsonvlan1 --assign-vlan-port eth1 --project-name='CNF Testbed' --packet-url='api.packet.net'   --facility='sjc1'" 
      run(cmd)
      sleep(10)

      stop_all_commands

      cmd = "ruby ../../l2_packet_networking.rb --server cnftestbed-worker1 --unassign-vlan watsonvlan1 --unassign-vlan-port eth1 --project-name='CNF Testbed' --packet-url='api.packet.net'  --facility='sjc1'" 
      run(cmd)
      sleep(15)
      stop_all_commands

      # puts "last command started output: #{last_command_started.output}"
      # puts "last command started stderr: #{last_command_started.stderr}"
      # puts "last command started stdout: #{last_command_started.stdout}"
      expect(last_command_started.output).to eq("success\n")
    end
    it 'tests show-vlan-devices' do
      cmd = "ruby ../../l2_packet_networking.rb --create-vlan watsonvlan1 --project-name='CNF Testbed' --packet-url='api.packet.net' --facility='sjc1' "
      run(cmd)
      sleep(10)
      stop_all_commands

      expect(last_command_started.output.to_i).to be_a_kind_of(Numeric)

      cmd = "ruby ../../l2_packet_networking.rb --server cnftestbed-worker1 --assign-vlan watsonvlan1 --assign-vlan-port eth1 --project-name='CNF Testbed' --packet-url='api.packet.net'" 
      run(cmd)
      sleep(10)
      stop_all_commands

      expect(last_command_started.output.to_i).to be_a_kind_of(Numeric)

      cmd = "ruby ../../l2_packet_networking.rb --show-vlan-devices watsonvlan1 --project-name='CNF Testbed' --packet-url='api.packet.net' --facility='sjc1'"
      run(cmd)
      sleep(10)
      stop_all_commands

      parsed_response = JSON.parse(last_command_started.output) 
      expect(parsed_response["id"]).to be_a(String) 
    end
    it 'tests show-project_vlans' do
      cmd = "ruby ../../l2_packet_networking.rb --create-vlan watsonvlan1 --project-name='CNF Testbed' --packet-url='api.packet.net' --facility='sjc1' "
      run(cmd)
      sleep(10)
      stop_all_commands

      expect(last_command_started.output.to_i).to be_a_kind_of(Numeric)

      cmd = "ruby ../../l2_packet_networking.rb --server cnftestbed-worker1 --assign-vlan watsonvlan1 --assign-vlan-port eth1 --project-name='CNF Testbed' --packet-url='api.packet.net'" 
      run(cmd)
      sleep(10)
      stop_all_commands

      expect(last_command_started.output.to_i).to be_a_kind_of(Numeric)

      cmd = "ruby ../../l2_packet_networking.rb --show-project-vlans --project-name='CNF Testbed' --packet-url='api.packet.net' --facility='sjc1'"

      run(cmd)
      sleep(10)
      stop_all_commands

      parsed_response = JSON.parse(last_command_started.output) 
      expect(parsed_response[0]["id"]).to be_a(String) 
    end

    it 'tests show-server-ports' do
      cmd = "ruby ../../l2_packet_networking.rb --create-vlan watsonvlan1 --project-name='CNF Testbed' --packet-url='api.packet.net' --facility='sjc1' "
      run(cmd)
      sleep(10)
      stop_all_commands

      expect(last_command_started.output.to_i).to be_a_kind_of(Numeric)

      cmd = "ruby ../../l2_packet_networking.rb --server cnftestbed-worker1 --assign-vlan watsonvlan1 --assign-vlan-port eth1 --project-name='CNF Testbed' --packet-url='api.packet.net'" 
      run(cmd)
      sleep(10)
      stop_all_commands

      expect(last_command_started.output.to_i).to be_a_kind_of(Numeric)

      cmd = "ruby ../../l2_packet_networking.rb --show-server-ports cnftestbed-worker1 --project-name='CNF Testbed' --packet-url='api.packet.net' --facility='sjc1'"

      run(cmd)
      sleep(10)
      stop_all_commands

      parsed_response = JSON.parse(last_command_started.output) 
      expect(parsed_response[0]["id"]).to be_a(String) 
    end

    it 'tests assign-vlan-id' do
      cmd = "ruby ../../l2_packet_networking.rb --create-vlan watsonvlan1 --project-name='CNF Testbed' --packet-url='api.packet.net' --facility='sjc1'"
      run(cmd)
      sleep(12)
      vid = last_command_started.output.strip

      cmd = "ruby ../../l2_packet_networking.rb --server cnftestbed-worker1 --assign-vlan-id #{vid} --assign-vlan-port eth1 --project-name='CNF Testbed' --packet-url='api.packet.net' --facility='sjc1'" 
      run(cmd)
      sleep(15)
      stop_all_commands
      # expect(last_command_started.output).to eq("success\n")

      cmd = "ruby ../../l2_packet_networking.rb --server cnftestbed-worker1 --unassign-vlan-id #{vid} --unassign-vlan-port eth1 --project-name='CNF Testbed' --packet-url='api.packet.net' --facility='sjc1'" 
      run(cmd)
      sleep(15)
      stop_all_commands
      expect(last_command_started.output).to eq("success\n")

      cmd = "ruby ../../l2_packet_networking.rb --delete-vlan watsonvlan1 --project-name='CNF Testbed' --packet-url='api.packet.net' --facility='sjc1'  "
      run(cmd)
      sleep(15)
      stop_all_commands
      expect(last_command_started.output).to eq("success\n")
    end

    it 'tests delete-vlan' do
      cmd = "ruby ../../l2_packet_networking.rb --create-vlan watsonvlan1 --project-name='CNF Testbed' --packet-url='api.packet.net' --facility='sjc1' "
      run(cmd)
      sleep(10)
      stop_all_commands

      cmd = "ruby ../../l2_packet_networking.rb --delete-vlan watsonvlan1 --project-name='CNF Testbed' --packet-url='api.packet.net' --facility='sjc1'  "
      run(cmd)
      sleep(10)
      stop_all_commands
      expect(last_command_started.output).to eq("success\n")
    end
  end
end

