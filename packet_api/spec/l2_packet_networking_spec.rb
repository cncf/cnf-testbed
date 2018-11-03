require 'spec_helper'

 # *** Assign your packet api token in the .env file and then source it before running rspec ***
RSpec.describe 'Packet Test Suite', type: :aruba  do
  context "Packet test" do
    it 'tests bond-interface' do
      cmd = "ruby ../../l2_packet_networking.rb --server layer2test-01 --bond-interface eth1 --project-name='CNCF CNFs' --packet-url='api.packet.net'" 
      run(cmd)
      sleep(10)
      stop_all_commands

      expect(last_command_started.output).to eq("success\n")
    end

    it 'tests disbond-interface' do
      cmd = "ruby ../../l2_packet_networking.rb --server layer2test-01 --disbond-interface eth1 --project-name='CNCF CNFs' --packet-url='api.packet.net'" 
      run(cmd)
      sleep(10)
      stop_all_commands

      expect(last_command_started.output).to eq("success\n")
    end
    it 'tests create-vlan' do
      cmd = "ruby ../../l2_packet_networking.rb --create-vlan watsonvlan1 --project-name='CNCF CNFs' --packet-url='api.packet.net' --facility='ewr1' "
      run(cmd)
      sleep(10)
      stop_all_commands

      expect(last_command_started.output.to_i).to be_a_kind_of(Numeric)
    end
    it 'tests assign-vlan.rb' do
      cmd = "ruby ../../l2_packet_networking.rb --server layer2test-01 --assign-vlan watsonvlan1 --assign-vlan-port eth1 --project-name='CNCF CNFs' --packet-url='api.packet.net'" 
      run(cmd)
      sleep(10)
      stop_all_commands

      # puts "last command started output: #{last_command_started.output}"
      # puts "last command started stderr: #{last_command_started.stderr}"
      # puts "last command started stdout: #{last_command_started.stdout}"
      expect(last_command_started.output).to eq("success\n")
    end

    it 'tests unassign-vlan.rb' do
      cmd = "ruby ../../l2_packet_networking.rb --server layer2test-01 --assign-vlan watsonvlan1 --assign-vlan-port eth1 --project-name='CNCF CNFs' --packet-url='api.packet.net'" 
      run(cmd)
      sleep(10)
      stop_all_commands

      cmd = "ruby ../../l2_packet_networking.rb --server layer2test-01 --unassign-vlan watsonvlan1 --unassign-vlan-port eth1 --project-name='CNCF CNFs' --packet-url='api.packet.net'" 
      run(cmd)
      sleep(10)
      stop_all_commands

      # puts "last command started output: #{last_command_started.output}"
      # puts "last command started stderr: #{last_command_started.stderr}"
      # puts "last command started stdout: #{last_command_started.stdout}"
      expect(last_command_started.output).to eq("success\n")
    end
    it 'tests delete-vlan' do
      cmd = "ruby ../../l2_packet_networking.rb --create-vlan watsonvlan1 --project-name='CNCF CNFs' --packet-url='api.packet.net' --facility='ewr1' "
      run(cmd)
      sleep(10)
      stop_all_commands

      cmd = "ruby ../../l2_packet_networking.rb --delete-vlan watsonvlan1 --project-name='CNCF CNFs' --packet-url='api.packet.net' --facility='ewr1'  "
      run(cmd)
      sleep(10)
      stop_all_commands
      expect(last_command_started.output).to eq("success\n")
    end
  end
end

