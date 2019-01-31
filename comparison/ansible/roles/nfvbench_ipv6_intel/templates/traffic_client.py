# Copyright 2016 Cisco Systems, Inc.  All rights reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

"""Interface to the traffic generator clients including NDR/PDR binary search."""

from datetime import datetime
import socket
import struct
import time

from attrdict import AttrDict
import bitmath
import ipaddress
from netaddr import IPNetwork
# pylint: disable=import-error
from trex_stl_lib.api import STLError
# pylint: enable=import-error

from log import LOG
from packet_stats import InterfaceStats
from packet_stats import PacketPathStats
from stats_collector import IntervalCollector
from stats_collector import IterationCollector
import traffic_gen.traffic_utils as utils
from utils import cast_integer


class TrafficClientException(Exception):
    """Generic traffic client exception."""

    pass


class TrafficRunner(object):
    """Serialize various steps required to run traffic."""

    def __init__(self, client, duration_sec, interval_sec=0):
        """Create a traffic runner."""
        self.client = client
        self.start_time = None
        self.duration_sec = duration_sec
        self.interval_sec = interval_sec

    def run(self):
        """Clear stats and instruct the traffic generator to start generating traffic."""
        if self.is_running():
            return None
        LOG.info('Running traffic generator')
        self.client.gen.clear_stats()
        self.client.gen.start_traffic()
        self.start_time = time.time()
        return self.poll_stats()

    def stop(self):
        """Stop the current run and instruct the traffic generator to stop traffic."""
        if self.is_running():
            self.start_time = None
            self.client.gen.stop_traffic()

    def is_running(self):
        """Check if a run is still pending."""
        return self.start_time is not None

    def time_elapsed(self):
        """Return time elapsed since start of run."""
        if self.is_running():
            return time.time() - self.start_time
        return self.duration_sec

    def poll_stats(self):
        """Poll latest stats from the traffic generator at fixed interval - sleeps if necessary.

        return: latest stats or None if traffic is stopped
        """
        if not self.is_running():
            return None
        if self.client.skip_sleep():
            self.stop()
            return self.client.get_stats()
        time_elapsed = self.time_elapsed()
        if time_elapsed > self.duration_sec:
            self.stop()
            return None
        time_left = self.duration_sec - time_elapsed
        if self.interval_sec > 0.0:
            if time_left <= self.interval_sec:
                time.sleep(time_left)
                self.stop()
            else:
                time.sleep(self.interval_sec)
        else:
            time.sleep(self.duration_sec)
            self.stop()
        return self.client.get_stats()


class IpBlock(object):
    """Manage a block of IP addresses."""

    def __init__(self, base_ip, step_ip, count_ip):
        """Create an IP block."""
        self.base_ip_int = Device.ip_to_int(base_ip)
        self.step = Device.ip_to_int(step_ip)
        self.max_available = count_ip
        self.next_free = 0

    def get_ip(self, index=0):
        """Return the IP address at given index."""
        if index < 0 or index >= self.max_available:
            raise IndexError('Index out of bounds: %d (max=%d)' % (index, self.max_available))
        return Device.int_to_ip(self.base_ip_int + index * self.step)

    def reserve_ip_range(self, count):
        """Reserve a range of count consecutive IP addresses spaced by step."""
        if self.next_free + count > self.max_available:
            raise IndexError('No more IP addresses next free=%d max_available=%d requested=%d' %
                             (self.next_free,
                              self.max_available,
                              count))
        first_ip = self.get_ip(self.next_free)
        last_ip = self.get_ip(self.next_free + count - 1)
        self.next_free += count
        return (first_ip, last_ip)

    def reset_reservation(self):
        """Reset all reservations and restart with a completely unused IP block."""
        self.next_free = 0


class Device(object):
    """Represent a port device and all information associated to it.

    In the curent version we only support 2 port devices for the traffic generator
    identified as port 0 or port 1.
    """

    def __init__(self, port, generator_config, vtep_vlan=None):
        """Create a new device for a given port."""
        self.generator_config = generator_config
        self.chain_count = generator_config.service_chain_count
        self.flow_count = generator_config.flow_count / 2
        self.port = port
        self.switch_port = generator_config.interfaces[port].get('switch_port', None)
        self.vtep_vlan = vtep_vlan
        self.pci = generator_config.interfaces[port].pci
        self.mac = None
        self.dest_macs = None
        self.vlans = None
        self.ip_addrs = generator_config.ip_addrs[port]
        subnet = IPNetwork(self.ip_addrs)
        self.ip = subnet.ip.format()
        self.ip_addrs_step = generator_config.ip_addrs_step
        self.ip_block = IpBlock(self.ip, self.ip_addrs_step, self.flow_count)
        self.gw_ip_block = IpBlock(generator_config.gateway_ips[port],
                                   generator_config.gateway_ip_addrs_step,
                                   self.chain_count)
        self.tg_gateway_ip_addrs = generator_config.tg_gateway_ip_addrs[port]
        self.tg_gw_ip_block = IpBlock(self.tg_gateway_ip_addrs,
                                      generator_config.tg_gateway_ip_addrs_step,
                                      self.chain_count)
        self.udp_src_port = generator_config.udp_src_port
        self.udp_dst_port = generator_config.udp_dst_port

    def set_mac(self, mac):
        """Set the local MAC for this port device."""
        if mac is None:
            raise TrafficClientException('Trying to set traffic generator MAC address as None')
        self.mac = mac

    def get_peer_device(self):
        """Get the peer device (device 0 -> device 1, or device 1 -> device 0)."""
        return self.generator_config.devices[1 - self.port]

    def set_dest_macs(self, dest_macs):
        """Set the list of dest MACs indexed by the chain id.

        This is only called in 2 cases:
        - VM macs discovered using openstack API
        - dest MACs provisioned in config file
        """
        self.dest_macs = map(str, dest_macs)

    def get_dest_macs(self):
        """Get the list of dest macs for this device.

        If set_dest_macs was never called, assumes l2-loopback and return
        a list of peer mac (as many as chains but normally only 1 chain)
        """
        if self.dest_macs:
            return self.dest_macs
        # assume this is l2-loopback
        return [self.get_peer_device().mac] * self.chain_count

    def set_vlans(self, vlans):
        """Set the list of vlans to use indexed by the chain id."""
        self.vlans = vlans
        LOG.info("Port %d: VLANs %s", self.port, self.vlans)

    def get_gw_ip(self, chain_index):
        """Retrieve the IP address assigned for the gateway of a given chain."""
        return self.gw_ip_block.get_ip(chain_index)

    def get_stream_configs(self):
        """Get the stream config for a given chain on this device.

        Called by the traffic generator driver to program the traffic generator properly
        before generating traffic
        """
        configs = []
        # exact flow count for each chain is calculated as follows:
        # - all chains except the first will have the same flow count
        #   calculated as (total_flows + chain_count - 1) / chain_count
        # - the first chain will have the remainder
        # example 11 flows and 3 chains => 3, 4, 4
        flows_per_chain = (self.flow_count + self.chain_count - 1) / self.chain_count
        cur_chain_flow_count = self.flow_count - flows_per_chain * (self.chain_count - 1)
        peer = self.get_peer_device()
        self.ip_block.reset_reservation()
        peer.ip_block.reset_reservation()
        dest_macs = self.get_dest_macs()

        for chain_idx in xrange(self.chain_count):
            src_ip_first, src_ip_last = self.ip_block.reserve_ip_range(cur_chain_flow_count)
            dst_ip_first, dst_ip_last = peer.ip_block.reserve_ip_range(cur_chain_flow_count)

            configs.append({
                'count': cur_chain_flow_count,
                'mac_src': self.mac,
                'mac_dst': dest_macs[chain_idx],
                'ip_src_addr': src_ip_first,
                'ip_src_addr_max': src_ip_last,
                'ip_src_count': cur_chain_flow_count,
                'ip_dst_addr': dst_ip_first,
                'ip_dst_addr_max': dst_ip_last,
                'ip_dst_count': cur_chain_flow_count,
                'ip_addrs_step': self.ip_addrs_step,
                'udp_src_port': self.udp_src_port,
                'udp_dst_port': self.udp_dst_port,
                'mac_discovery_gw': self.get_gw_ip(chain_idx),
                'ip_src_tg_gw': self.tg_gw_ip_block.get_ip(chain_idx),
                'ip_dst_tg_gw': peer.tg_gw_ip_block.get_ip(chain_idx),
                'vlan_tag': self.vlans[chain_idx] if self.vlans else None
            })
            # after first chain, fall back to the flow count for all other chains
            cur_chain_flow_count = flows_per_chain
        return configs

    @staticmethod
    def ip_to_int(addr):
        """Convert an IP address from string to numeric."""
        return int(ipaddress.IPv6Address(unicode(addr)))

    @staticmethod
    def int_to_ip(nvalue):
        """Convert an IP address from numeric to string."""
        return str(ipaddress.IPv6Address(nvalue))


class GeneratorConfig(object):
    """Represents traffic configuration for currently running traffic profile."""

    DEFAULT_IP_STEP = '0.0.0.1'
    DEFAULT_SRC_DST_IP_STEP = '0.0.0.1'

    def __init__(self, config):
        """Create a generator config."""
        self.config = config
        # name of the generator profile (normally trex or dummy)
        # pick the default one if not specified explicitly from cli options
        if not config.generator_profile:
            config.generator_profile = config.traffic_generator.default_profile
        # pick up the profile dict based on the name
        gen_config = self.__match_generator_profile(config.traffic_generator,
                                                    config.generator_profile)
        self.gen_config = gen_config
        # copy over fields from the dict
        self.tool = gen_config.tool
        self.ip = gen_config.ip
        self.cores = gen_config.get('cores', 1)
        if gen_config.intf_speed:
            # interface speed is overriden from config
            self.intf_speed = bitmath.parse_string(gen_config.intf_speed.replace('ps', '')).bits
        else:
            # interface speed is discovered/provided by the traffic generator
            self.intf_speed = 0
        self.software_mode = gen_config.get('software_mode', False)
        self.interfaces = gen_config.interfaces
        if self.interfaces[0].port != 0 or self.interfaces[1].port != 1:
            raise TrafficClientException('Invalid port order/id in generator_profile.interfaces')

        self.service_chain = config.service_chain
        self.service_chain_count = config.service_chain_count
        self.flow_count = config.flow_count
        self.host_name = gen_config.host_name

        self.tg_gateway_ip_addrs = gen_config.tg_gateway_ip_addrs
        self.ip_addrs = gen_config.ip_addrs
        self.ip_addrs_step = gen_config.ip_addrs_step or self.DEFAULT_SRC_DST_IP_STEP
        self.tg_gateway_ip_addrs_step = \
            gen_config.tg_gateway_ip_addrs_step or self.DEFAULT_IP_STEP
        self.gateway_ip_addrs_step = gen_config.gateway_ip_addrs_step or self.DEFAULT_IP_STEP
        self.gateway_ips = gen_config.gateway_ip_addrs
        self.udp_src_port = gen_config.udp_src_port
        self.udp_dst_port = gen_config.udp_dst_port
        self.devices = [Device(port, self) for port in [0, 1]]
        # This should normally always be [0, 1]
        self.ports = [device.port for device in self.devices]

        # check that pci is not empty
        if not gen_config.interfaces[0].get('pci', None) or \
           not gen_config.interfaces[1].get('pci', None):
            raise TrafficClientException("configuration interfaces pci fields cannot be empty")

        self.pcis = [tgif['pci'] for tgif in gen_config.interfaces]
        self.vlan_tagging = config.vlan_tagging

        # needed for result/summarizer
        config['tg-name'] = gen_config.name
        config['tg-tool'] = self.tool

    def to_json(self):
        """Get json form to display the content into the overall result dict."""
        return dict(self.gen_config)

    def set_dest_macs(self, port_index, dest_macs):
        """Set the list of dest MACs indexed by the chain id on given port.

        port_index: the port for which dest macs must be set
        dest_macs: a list of dest MACs indexed by chain id
        """
        if len(dest_macs) != self.config.service_chain_count:
            raise TrafficClientException('Dest MAC list %s must have %d entries' %
                                         (dest_macs, self.config.service_chain_count))
        self.devices[port_index].set_dest_macs(dest_macs)
        LOG.info('Port %d: dst MAC %s', port_index, [str(mac) for mac in dest_macs])

    def get_dest_macs(self):
        """Return the list of dest macs indexed by port."""
        return [dev.get_dest_macs() for dev in self.devices]

    def set_vlans(self, port_index, vlans):
        """Set the list of vlans to use indexed by the chain id on given port.

        port_index: the port for which VLANs must be set
        vlans: a  list of vlan lists indexed by chain id
        """
        if len(vlans) != self.config.service_chain_count:
            raise TrafficClientException('VLAN list %s must have %d entries' %
                                         (vlans, self.config.service_chain_count))
        self.devices[port_index].set_vlans(vlans)

    @staticmethod
    def __match_generator_profile(traffic_generator, generator_profile):
        gen_config = AttrDict(traffic_generator)
        gen_config.pop('default_profile')
        gen_config.pop('generator_profile')
        matching_profile = [profile for profile in traffic_generator.generator_profile if
                            profile.name == generator_profile]
        if len(matching_profile) != 1:
            raise Exception('Traffic generator profile not found: ' + generator_profile)

        gen_config.update(matching_profile[0])
        return gen_config


class TrafficClient(object):
    """Traffic generator client with NDR/PDR binary seearch."""

    PORTS = [0, 1]

    def __init__(self, config, notifier=None):
        """Create a new TrafficClient instance.

        config: nfvbench config
        notifier: notifier (optional)

        A new instance is created everytime the nfvbench config may have changed.
        """
        self.config = config
        self.generator_config = GeneratorConfig(config)
        self.tool = self.generator_config.tool
        self.gen = self._get_generator()
        self.notifier = notifier
        self.interval_collector = None
        self.iteration_collector = None
        self.runner = TrafficRunner(self, self.config.duration_sec, self.config.interval_sec)
        self.config.frame_sizes = self._get_frame_sizes()
        self.run_config = {
            'l2frame_size': None,
            'duration_sec': self.config.duration_sec,
            'bidirectional': True,
            'rates': []  # to avoid unsbuscriptable-obj warning
        }
        self.current_total_rate = {'rate_percent': '10'}
        if self.config.single_run:
            self.current_total_rate = utils.parse_rate_str(self.config.rate)
        self.ifstats = None
        # Speed is either discovered when connecting to TG or set from config
        # This variable is 0 if not yet discovered from TG or must be the speed of
        # each interface in bits per second
        self.intf_speed = self.generator_config.intf_speed

    def _get_generator(self):
        tool = self.tool.lower()
        if tool == 'trex':
            from traffic_gen import trex
            return trex.TRex(self)
        if tool == 'dummy':
            from traffic_gen import dummy
            return dummy.DummyTG(self)
        raise TrafficClientException('Unsupported generator tool name:' + self.tool)

    def skip_sleep(self):
        """Skip all sleeps when doing unit testing with dummy TG.

        Must be overriden using mock.patch
        """
        return False

    def _get_frame_sizes(self):
        traffic_profile_name = self.config.traffic.profile
        matching_profiles = [profile for profile in self.config.traffic_profile if
                             profile.name == traffic_profile_name]
        if len(matching_profiles) > 1:
            raise TrafficClientException('Multiple traffic profiles with name: ' +
                                         traffic_profile_name)
        elif not matching_profiles:
            raise TrafficClientException('Cannot find traffic profile: ' + traffic_profile_name)
        return matching_profiles[0].l2frame_size

    def start_traffic_generator(self):
        """Start the traffic generator process (traffic not started yet)."""
        self.gen.connect()
        # pick up the interface speed if it is not set from config
        intf_speeds = self.gen.get_port_speed_gbps()
        # convert Gbps unit into bps
        tg_if_speed = bitmath.parse_string(str(intf_speeds[0]) + 'Gb').bits
        if self.intf_speed:
            # interface speed is overriden from config
            if self.intf_speed != tg_if_speed:
                # Warn the user if the speed in the config is different
                LOG.warning('Interface speed provided is different from actual speed (%d Gbps)',
                            intf_speeds[0])
        else:
            # interface speed not provisioned by config
            self.intf_speed = tg_if_speed
            # also update the speed in the tg config
            self.generator_config.intf_speed = tg_if_speed

        # Save the traffic generator local MAC
        for mac, device in zip(self.gen.get_macs(), self.generator_config.devices):
            device.set_mac(mac)

    def setup(self):
        """Set up the traffic client."""
        self.gen.clear_stats()

    def get_version(self):
        """Get the traffic generator version."""
        return self.gen.get_version()

    def ensure_end_to_end(self):
        """Ensure traffic generator receives packets it has transmitted.

        This ensures end to end connectivity and also waits until VMs are ready to forward packets.

        VMs that are started and in active state may not pass traffic yet. It is imperative to make
        sure that all VMs are passing traffic in both directions before starting any benchmarking.
        To verify this, we need to send at a low frequency bi-directional packets and make sure
        that we receive all packets back from all VMs. The number of flows is equal to 2 times
        the number of chains (1 per direction) and we need to make sure we receive packets coming
        from exactly 2 x chain count different source MAC addresses.

        Example:
            PVP chain (1 VM per chain)
            N = 10 (number of chains)
            Flow count = 20 (number of flows)
            If the number of unique source MAC addresses from received packets is 20 then
            all 10 VMs 10 VMs are in operational state.
        """
        LOG.info('Starting traffic generator to ensure end-to-end connectivity')
        # send 2pps on each chain and each direction
        rate_pps = {'rate_pps': str(self.config.service_chain_count * 2)}
        self.gen.create_traffic('64', [rate_pps, rate_pps], bidirectional=True, latency=False, e2e=True)

        # ensures enough traffic is coming back
        retry_count = (self.config.check_traffic_time_sec +
                       self.config.generic_poll_sec - 1) / self.config.generic_poll_sec

        # we expect to see packets coming from 2 unique MAC per chain
        # because there can be flooding in the case of shared net
        # we must verify that packets from the right VMs are received
        # and not just count unique src MAC
        # create a dict of (port, chain) tuples indexed by dest mac
        mac_map = {}
        for port, dest_macs in enumerate(self.generator_config.get_dest_macs()):
            for chain, mac in enumerate(dest_macs):
                mac_map[mac] = (port, chain)
        unique_src_mac_count = len(mac_map)
        for it in xrange(retry_count):
            self.gen.clear_stats()
            self.gen.start_traffic()
            self.gen.start_capture()
            LOG.info('Captured unique src mac %d/%d, capturing return packets (retry %d/%d)...',
                     unique_src_mac_count - len(mac_map), unique_src_mac_count,
                     it + 1, retry_count)
            if not self.skip_sleep():
                time.sleep(self.config.generic_poll_sec)
            self.gen.stop_traffic()
            self.gen.fetch_capture_packets()
            self.gen.stop_capture()

            for packet in self.gen.packet_list:
                src_mac = packet['binary'][6:12]
                src_mac = ':'.join(["%02x" % ord(x) for x in src_mac])
                if src_mac in mac_map:
                    port, chain = mac_map[src_mac]
                    LOG.info('Received packet from mac: %s (chain=%d, port=%d)',
                             src_mac, chain, port)
                    mac_map.pop(src_mac, None)

                if not mac_map:
                    LOG.info('End-to-end connectivity established')
                    return

        raise TrafficClientException('End-to-end connectivity cannot be ensured')

    def ensure_arp_successful(self):
        """Resolve all IP using ARP and throw an exception in case of failure."""
        dest_macs = self.gen.resolve_arp()
        if dest_macs:
            # all dest macs are discovered, saved them into the generator config
            self.generator_config.set_dest_macs(0, dest_macs[0])
            self.generator_config.set_dest_macs(1, dest_macs[1])
        else:
            raise TrafficClientException('ARP cannot be resolved')

    def set_traffic(self, frame_size, bidirectional):
        """Reconfigure the traffic generator for a new frame size."""
        self.run_config['bidirectional'] = bidirectional
        self.run_config['l2frame_size'] = frame_size
        self.run_config['rates'] = [self.get_per_direction_rate()]
        if bidirectional:
            self.run_config['rates'].append(self.get_per_direction_rate())
        else:
            unidir_reverse_pps = int(self.config.unidir_reverse_traffic_pps)
            if unidir_reverse_pps > 0:
                self.run_config['rates'].append({'rate_pps': str(unidir_reverse_pps)})
        # Fix for [NFVBENCH-67], convert the rate string to PPS
        for idx, rate in enumerate(self.run_config['rates']):
            if 'rate_pps' not in rate:
                self.run_config['rates'][idx] = {'rate_pps': self.__convert_rates(rate)['rate_pps']}

        self.gen.clear_streamblock()
        self.gen.create_traffic(frame_size, self.run_config['rates'], bidirectional, latency=True)

    def _modify_load(self, load):
        self.current_total_rate = {'rate_percent': str(load)}
        rate_per_direction = self.get_per_direction_rate()

        self.gen.modify_rate(rate_per_direction, False)
        self.run_config['rates'][0] = rate_per_direction
        if self.run_config['bidirectional']:
            self.gen.modify_rate(rate_per_direction, True)
            self.run_config['rates'][1] = rate_per_direction

    def get_ndr_and_pdr(self):
        """Start the NDR/PDR iteration and return the results."""
        dst = 'Bidirectional' if self.run_config['bidirectional'] else 'Unidirectional'
        targets = {}
        if self.config.ndr_run:
            LOG.info('*** Searching NDR for %s (%s)...', self.run_config['l2frame_size'], dst)
            targets['ndr'] = self.config.measurement.NDR
        if self.config.pdr_run:
            LOG.info('*** Searching PDR for %s (%s)...', self.run_config['l2frame_size'], dst)
            targets['pdr'] = self.config.measurement.PDR

        self.run_config['start_time'] = time.time()
        self.interval_collector = IntervalCollector(self.run_config['start_time'])
        self.interval_collector.attach_notifier(self.notifier)
        self.iteration_collector = IterationCollector(self.run_config['start_time'])
        results = {}
        self.__range_search(0.0, 200.0, targets, results)

        results['iteration_stats'] = {
            'ndr_pdr': self.iteration_collector.get()
        }

        if self.config.ndr_run:
            LOG.info('NDR load: %s', results['ndr']['rate_percent'])
            results['ndr']['time_taken_sec'] = \
                results['ndr']['timestamp_sec'] - self.run_config['start_time']
            if self.config.pdr_run:
                LOG.info('PDR load: %s', results['pdr']['rate_percent'])
                results['pdr']['time_taken_sec'] = \
                    results['pdr']['timestamp_sec'] - results['ndr']['timestamp_sec']
        else:
            LOG.info('PDR load: %s', results['pdr']['rate_percent'])
            results['pdr']['time_taken_sec'] = \
                results['pdr']['timestamp_sec'] - self.run_config['start_time']
        return results

    def __get_dropped_rate(self, result):
        dropped_pkts = result['rx']['dropped_pkts']
        total_pkts = result['tx']['total_pkts']
        if not total_pkts:
            return float('inf')
        return float(dropped_pkts) / total_pkts * 100

    def get_stats(self):
        """Collect final stats for previous run."""
        stats = self.gen.get_stats()
        retDict = {'total_tx_rate': stats['total_tx_rate']}
        for port in self.PORTS:
            retDict[port] = {'tx': {}, 'rx': {}}

        tx_keys = ['total_pkts', 'total_pkt_bytes', 'pkt_rate', 'pkt_bit_rate']
        rx_keys = tx_keys + ['dropped_pkts']

        for port in self.PORTS:
            for key in tx_keys:
                retDict[port]['tx'][key] = int(stats[port]['tx'][key])
            for key in rx_keys:
                try:
                    retDict[port]['rx'][key] = int(stats[port]['rx'][key])
                except ValueError:
                    retDict[port]['rx'][key] = 0
            retDict[port]['rx']['avg_delay_usec'] = cast_integer(
                stats[port]['rx']['avg_delay_usec'])
            retDict[port]['rx']['min_delay_usec'] = cast_integer(
                stats[port]['rx']['min_delay_usec'])
            retDict[port]['rx']['max_delay_usec'] = cast_integer(
                stats[port]['rx']['max_delay_usec'])
            retDict[port]['drop_rate_percent'] = self.__get_dropped_rate(retDict[port])

        ports = sorted(retDict.keys())
        if self.run_config['bidirectional']:
            retDict['overall'] = {'tx': {}, 'rx': {}}
            for key in tx_keys:
                retDict['overall']['tx'][key] = \
                    retDict[ports[0]]['tx'][key] + retDict[ports[1]]['tx'][key]
            for key in rx_keys:
                retDict['overall']['rx'][key] = \
                    retDict[ports[0]]['rx'][key] + retDict[ports[1]]['rx'][key]
            total_pkts = [retDict[ports[0]]['rx']['total_pkts'],
                          retDict[ports[1]]['rx']['total_pkts']]
            avg_delays = [retDict[ports[0]]['rx']['avg_delay_usec'],
                          retDict[ports[1]]['rx']['avg_delay_usec']]
            max_delays = [retDict[ports[0]]['rx']['max_delay_usec'],
                          retDict[ports[1]]['rx']['max_delay_usec']]
            min_delays = [retDict[ports[0]]['rx']['min_delay_usec'],
                          retDict[ports[1]]['rx']['min_delay_usec']]
            retDict['overall']['rx']['avg_delay_usec'] = utils.weighted_avg(total_pkts, avg_delays)
            retDict['overall']['rx']['min_delay_usec'] = min(min_delays)
            retDict['overall']['rx']['max_delay_usec'] = max(max_delays)
            for key in ['pkt_bit_rate', 'pkt_rate']:
                for dirc in ['tx', 'rx']:
                    retDict['overall'][dirc][key] /= 2.0
        else:
            retDict['overall'] = retDict[ports[0]]
        retDict['overall']['drop_rate_percent'] = self.__get_dropped_rate(retDict['overall'])
        return retDict

    def __convert_rates(self, rate):
        return utils.convert_rates(self.run_config['l2frame_size'],
                                   rate,
                                   self.intf_speed)

    def __ndr_pdr_found(self, tag, load):
        rates = self.__convert_rates({'rate_percent': load})
        self.iteration_collector.add_ndr_pdr(tag, rates['rate_pps'])
        last_stats = self.iteration_collector.peek()
        self.interval_collector.add_ndr_pdr(tag, last_stats)

    def __format_output_stats(self, stats):
        for key in self.PORTS + ['overall']:
            interface = stats[key]
            stats[key] = {
                'tx_pkts': interface['tx']['total_pkts'],
                'rx_pkts': interface['rx']['total_pkts'],
                'drop_percentage': interface['drop_rate_percent'],
                'drop_pct': interface['rx']['dropped_pkts'],
                'avg_delay_usec': interface['rx']['avg_delay_usec'],
                'max_delay_usec': interface['rx']['max_delay_usec'],
                'min_delay_usec': interface['rx']['min_delay_usec'],
            }

        return stats

    def __targets_found(self, rate, targets, results):
        for tag, target in targets.iteritems():
            LOG.info('Found %s (%s) load: %s', tag, target, rate)
            self.__ndr_pdr_found(tag, rate)
            results[tag]['timestamp_sec'] = time.time()

    def __range_search(self, left, right, targets, results):
        """Perform a binary search for a list of targets inside a [left..right] range or rate.

        left    the left side of the range to search as a % the line rate (100 = 100% line rate)
                indicating the rate to send on each interface
        right   the right side of the range to search as a % of line rate
                indicating the rate to send on each interface
        targets a dict of drop rates to search (0.1 = 0.1%), indexed by the DR name or "tag"
                ('ndr', 'pdr')
        results a dict to store results
        """
        if not targets:
            return
        LOG.info('Range search [%s .. %s] targets: %s', left, right, targets)

        # Terminate search when gap is less than load epsilon
        if right - left < self.config.measurement.load_epsilon:
            self.__targets_found(left, targets, results)
            return

        # Obtain the average drop rate in for middle load
        middle = (left + right) / 2.0
        try:
            stats, rates = self.__run_search_iteration(middle)
        except STLError:
            LOG.exception("Got exception from traffic generator during binary search")
            self.__targets_found(left, targets, results)
            return
        # Split target dicts based on the avg drop rate
        left_targets = {}
        right_targets = {}
        for tag, target in targets.iteritems():
            if stats['overall']['drop_rate_percent'] <= target:
                # record the best possible rate found for this target
                results[tag] = rates
                results[tag].update({
                    'load_percent_per_direction': middle,
                    'stats': self.__format_output_stats(dict(stats)),
                    'timestamp_sec': None
                })
                right_targets[tag] = target
            else:
                # initialize to 0 all fields of result for
                # the worst case scenario of the binary search (if ndr/pdr is not found)
                if tag not in results:
                    results[tag] = dict.fromkeys(rates, 0)
                    empty_stats = self.__format_output_stats(dict(stats))
                    for key in empty_stats:
                        if isinstance(empty_stats[key], dict):
                            empty_stats[key] = dict.fromkeys(empty_stats[key], 0)
                        else:
                            empty_stats[key] = 0
                    results[tag].update({
                        'load_percent_per_direction': 0,
                        'stats': empty_stats,
                        'timestamp_sec': None
                    })
                left_targets[tag] = target

        # search lower half
        self.__range_search(left, middle, left_targets, results)

        # search upper half only if the upper rate does not exceed
        # 100%, this only happens when the first search at 100%
        # yields a DR that is < target DR
        if middle >= 100:
            self.__targets_found(100, right_targets, results)
        else:
            self.__range_search(middle, right, right_targets, results)

    def __run_search_iteration(self, rate):
        """Run one iteration at the given rate level.

        rate: the rate to send on each port in percent (0 to 100)
        """
        self._modify_load(rate)

        # poll interval stats and collect them
        for stats in self.run_traffic():
            self.interval_collector.add(stats)
            time_elapsed_ratio = self.runner.time_elapsed() / self.run_config['duration_sec']
            if time_elapsed_ratio >= 1:
                self.cancel_traffic()
                if not self.skip_sleep():
                    time.sleep(self.config.pause_sec)
        self.interval_collector.reset()

        # get stats from the run
        stats = self.runner.client.get_stats()
        current_traffic_config = self._get_traffic_config()
        warning = self.compare_tx_rates(current_traffic_config['direction-total']['rate_pps'],
                                        stats['total_tx_rate'])
        if warning is not None:
            stats['warning'] = warning

        # save reliable stats from whole iteration
        self.iteration_collector.add(stats, current_traffic_config['direction-total']['rate_pps'])
        LOG.info('Average drop rate: %f', stats['overall']['drop_rate_percent'])
        return stats, current_traffic_config['direction-total']

    @staticmethod
    def log_stats(stats):
        """Log estimated stats during run."""
        report = {
            'datetime': str(datetime.now()),
            'tx_packets': stats['overall']['tx']['total_pkts'],
            'rx_packets': stats['overall']['rx']['total_pkts'],
            'drop_packets': stats['overall']['rx']['dropped_pkts'],
            'drop_rate_percent': stats['overall']['drop_rate_percent']
        }
        LOG.info('TX: %(tx_packets)d; '
                 'RX: %(rx_packets)d; '
                 'Est. Dropped: %(drop_packets)d; '
                 'Est. Drop rate: %(drop_rate_percent).4f%%',
                 report)

    def run_traffic(self):
        """Start traffic and return intermediate stats for each interval."""
        stats = self.runner.run()
        while self.runner.is_running:
            self.log_stats(stats)
            yield stats
            stats = self.runner.poll_stats()
            if stats is None:
                return
        self.log_stats(stats)
        LOG.info('Drop rate: %f', stats['overall']['drop_rate_percent'])
        yield stats

    def cancel_traffic(self):
        """Stop traffic."""
        self.runner.stop()

    def _get_traffic_config(self):
        config = {}
        load_total = 0.0
        bps_total = 0.0
        pps_total = 0.0
        for idx, rate in enumerate(self.run_config['rates']):
            key = 'direction-forward' if idx == 0 else 'direction-reverse'
            config[key] = {
                'l2frame_size': self.run_config['l2frame_size'],
                'duration_sec': self.run_config['duration_sec']
            }
            config[key].update(rate)
            config[key].update(self.__convert_rates(rate))
            load_total += float(config[key]['rate_percent'])
            bps_total += float(config[key]['rate_bps'])
            pps_total += float(config[key]['rate_pps'])
        config['direction-total'] = dict(config['direction-forward'])
        config['direction-total'].update({
            'rate_percent': load_total,
            'rate_pps': cast_integer(pps_total),
            'rate_bps': bps_total
        })

        return config

    def get_run_config(self, results):
        """Return configuration which was used for the last run."""
        r = {}
        # because we want each direction to have the far end RX rates,
        # use the far end index (1-idx) to retrieve the RX rates
        for idx, key in enumerate(["direction-forward", "direction-reverse"]):
            tx_rate = results["stats"][idx]["tx"]["total_pkts"] / self.config.duration_sec
            rx_rate = results["stats"][1 - idx]["rx"]["total_pkts"] / self.config.duration_sec
            r[key] = {
                "orig": self.__convert_rates(self.run_config['rates'][idx]),
                "tx": self.__convert_rates({'rate_pps': tx_rate}),
                "rx": self.__convert_rates({'rate_pps': rx_rate})
            }

        total = {}
        for direction in ['orig', 'tx', 'rx']:
            total[direction] = {}
            for unit in ['rate_percent', 'rate_bps', 'rate_pps']:
                total[direction][unit] = sum([float(x[direction][unit]) for x in r.values()])

        r['direction-total'] = total
        return r

    def insert_interface_stats(self, pps_list):
        """Insert interface stats to a list of packet path stats.

        pps_list: a list of packet path stats instances indexed by chain index

        This function will insert the packet path stats for the traffic gen ports 0 and 1
        with itemized per chain tx/rx counters.
        There will be as many packet path stats as chains.
        Each packet path stats will have exactly 2 InterfaceStats for port 0 and port 1
        self.pps_list:
        [
        PacketPathStats(InterfaceStats(chain 0, port 0), InterfaceStats(chain 0, port 1)),
        PacketPathStats(InterfaceStats(chain 1, port 0), InterfaceStats(chain 1, port 1)),
        ...
        ]
        """
        def get_if_stats(chain_idx):
            return [InterfaceStats('p' + str(port), self.tool)
                    for port in range(2)]
        # keep the list of list of interface stats indexed by the chain id
        self.ifstats = [get_if_stats(chain_idx)
                        for chain_idx in range(self.config.service_chain_count)]
        # note that we need to make a copy of the ifs list so that any modification in the
        # list from pps will not change the list saved in self.ifstats
        self.pps_list = [PacketPathStats(list(ifs)) for ifs in self.ifstats]
        # insert the corresponding pps in the passed list
        pps_list.extend(self.pps_list)

    def update_interface_stats(self, diff=False):
        """Update all interface stats.

        diff: if False, simply refresh the interface stats values with latest values
              if True, diff the interface stats with the latest values
        Make sure that the interface stats inserted in insert_interface_stats() are updated
        with proper values.
        self.ifstats:
        [
        [InterfaceStats(chain 0, port 0), InterfaceStats(chain 0, port 1)],
        [InterfaceStats(chain 1, port 0), InterfaceStats(chain 1, port 1)],
        ...
        ]
        """
        if diff:
            stats = self.gen.get_stats()
            for chain_idx, ifs in enumerate(self.ifstats):
                # each ifs has exactly 2 InterfaceStats and 2 Latency instances
                # corresponding to the
                # port 0 and port 1 for the given chain_idx
                # Note that we cannot use self.pps_list[chain_idx].if_stats to pick the
                # interface stats for the pps because it could have been modified to contain
                # additional interface stats
                self.gen.get_stream_stats(stats, ifs, self.pps_list[chain_idx].latencies, chain_idx)


    @staticmethod
    def compare_tx_rates(required, actual):
        """Compare the actual TX rate to the required TX rate."""
        threshold = 0.9
        are_different = False
        try:
            if float(actual) / required < threshold:
                are_different = True
        except ZeroDivisionError:
            are_different = True

        if are_different:
            msg = "WARNING: There is a significant difference between requested TX rate ({r}) " \
                  "and actual TX rate ({a}). The traffic generator may not have sufficient CPU " \
                  "to achieve the requested TX rate.".format(r=required, a=actual)
            LOG.info(msg)
            return msg

        return None

    def get_per_direction_rate(self):
        """Get the rate for each direction."""
        divisor = 2 if self.run_config['bidirectional'] else 1
        if 'rate_percent' in self.current_total_rate:
            # don't split rate if it's percentage
            divisor = 1

        return utils.divide_rate(self.current_total_rate, divisor)

    def close(self):
        """Close this instance."""
        try:
            self.gen.stop_traffic()
        except Exception:
            pass
        self.gen.clear_stats()
        self.gen.cleanup()
