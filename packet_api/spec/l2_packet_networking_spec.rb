require 'spec_helper'

 RSpec.describe 'Packet Test Suite', type: :aruba  do
   context "Packet test" do
     it 'tests disbond-interface' do
       cmd = "ruby ../../l2_packet_networking.rb --server layer2test-01 --disbond-interface eth1" 
       run(cmd)
       sleep(10)
       stop_all_commands

       expect(last_command_started.output).to eq("success\n")
     end
     it 'tests create-vlan' do
       cmd = "ruby ../../l2_packet_networking.rb --create-vlan watsonvlan1" 
       run(cmd)
       sleep(10)
       stop_all_commands

       expect(last_command_started.output.to_i).to be_a_kind_of(Numeric)
     end
     it 'tests assign-vlan.rb' do
       cmd = "ruby ../../l2_packet_networking.rb --server layer2test-01 --assign-vlan watsonvlan1 --assign-vlan-port eth1" 
       run(cmd)
       sleep(10)
       stop_all_commands

       # puts "last command started output: #{last_command_started.output}"
       # puts "last command started stderr: #{last_command_started.stderr}"
       # puts "last command started stdout: #{last_command_started.stdout}"
       expect(last_command_started.output).to eq("success\n")
     end
   end
 end

