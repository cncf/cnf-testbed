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
"""Driver module for TRex traffic generator."""

import os
import random
import socket
import struct
import time
import traceback

from itertools import count
from nfvbench.log import LOG
from nfvbench.traffic_server import TRexTrafficServer
from nfvbench.utils import cast_integer
from nfvbench.utils import timeout
from nfvbench.utils import TimeoutError
from traffic_base import AbstractTrafficGenerator
from traffic_base import TrafficGeneratorException
import traffic_utils as utils
from traffic_utils import IMIX_AVG_L2_FRAME_SIZE
from traffic_utils import IMIX_L2_SIZES
from traffic_utils import IMIX_RATIOS

# pylint: disable=import-error
from trex_stl_lib.api import CTRexVmInsFixHwCs
from trex_stl_lib.api import Dot1Q
from trex_stl_lib.api import Ether
from trex_stl_lib.api import IP
from trex_stl_lib.api import IPv6
from trex_stl_lib.api import STLClient
from trex_stl_lib.api import STLError
from trex_stl_lib.api import STLFlowLatencyStats
from trex_stl_lib.api import STLFlowStats
from trex_stl_lib.api import STLPktBuilder
from trex_stl_lib.api import STLScVmRaw
from trex_stl_lib.api import STLStream
from trex_stl_lib.api import STLTXCont
from trex_stl_lib.api import STLVmFixChecksumHw
from trex_stl_lib.api import STLVmFlowVar
from trex_stl_lib.api import STLVmFlowVarRepetableRandom
from trex_stl_lib.api import STLVmWrFlowVar
from trex_stl_lib.api import UDP
from trex_stl_lib.services.trex_stl_service_arp import STLServiceARP


# pylint: enable=import-error


class TRex(AbstractTrafficGenerator):
    """TRex traffic generator driver."""

    LATENCY_PPS = 1000
    CHAIN_PG_ID_MASK = 0x007F
    PORT_PG_ID_MASK = 0x0080
    LATENCY_PG_ID_MASK = 0x0100

    def __init__(self, traffic_client):
        """Trex driver."""
        AbstractTrafficGenerator.__init__(self, traffic_client)
        self.client = None
        self.id = count()
        self.port_handle = []
        self.chain_count = self.generator_config.service_chain_count
        self.rates = []
        self.capture_id = None
        self.packet_list = []

    def get_version(self):
        """Get the Trex version."""
        return self.client.get_server_version() if self.client else ''

    def get_pg_id(self, port, chain_id):
        """Calculate the packet group IDs to use for a given port/stream type/chain_id.

        port: 0 or 1
        chain_id: identifies to which chain the pg_id is associated (0 to 255)
        return: pg_id, lat_pg_id

        We use a bit mask to set up the 3 fields:
        0x007F: chain ID (8 bits for a max of 128 chains)
        0x0080: port bit
        0x0100: latency bit
        """
        pg_id = port * TRex.PORT_PG_ID_MASK | chain_id
        return pg_id, pg_id | TRex.LATENCY_PG_ID_MASK

    def extract_stats(self, in_stats):
        """Extract stats from dict returned by Trex API.

        :param in_stats: dict as returned by TRex api
        """
        utils.nan_replace(in_stats)
        # LOG.debug(in_stats)

        result = {}
        # port_handles should have only 2 elements: [0, 1]
        # so (1 - ph) will be the index for the far end port
        for ph in self.port_handle:
            stats = in_stats[ph]
            far_end_stats = in_stats[1 - ph]
            result[ph] = {
                'tx': {
                    'total_pkts': cast_integer(stats['opackets']),
                    'total_pkt_bytes': cast_integer(stats['obytes']),
                    'pkt_rate': cast_integer(stats['tx_pps']),
                    'pkt_bit_rate': cast_integer(stats['tx_bps'])
                },
                'rx': {
                    'total_pkts': cast_integer(stats['ipackets']),
                    'total_pkt_bytes': cast_integer(stats['ibytes']),
                    'pkt_rate': cast_integer(stats['rx_pps']),
                    'pkt_bit_rate': cast_integer(stats['rx_bps']),
                    # how many pkts were dropped in RX direction
                    # need to take the tx counter on the far end port
                    'dropped_pkts': cast_integer(
                        far_end_stats['opackets'] - stats['ipackets'])
                }
            }
            self.__combine_latencies(in_stats, result[ph]['rx'], ph)

        total_tx_pkts = result[0]['tx']['total_pkts'] + result[1]['tx']['total_pkts']
        result["total_tx_rate"] = cast_integer(total_tx_pkts / self.config.duration_sec)
        result["flow_stats"] = in_stats["flow_stats"]
        result["latency"] = in_stats["latency"]
        return result

    def get_stream_stats(self, trex_stats, if_stats, latencies, chain_idx):
        """Extract the aggregated stats for a given chain.

        trex_stats: stats as returned by get_stats()
        if_stats: a list of 2 interface stats to update (port 0 and 1)
        latencies: a list of 2 Latency instances to update for this chain (port 0 and 1)
                   latencies[p] is the latency for packets sent on port p
                   if there are no latency streams, the Latency instances are not modified
        chain_idx: chain index of the interface stats

        The packet counts include normal and latency streams.

        Trex returns flows stats as follows:

        'flow_stats': {0: {'rx_bps': {0: 0, 1: 0, 'total': 0},
                   'rx_bps_l1': {0: 0.0, 1: 0.0, 'total': 0.0},
                   'rx_bytes': {0: nan, 1: nan, 'total': nan},
                   'rx_pkts': {0: 0, 1: 15001, 'total': 15001},
                   'rx_pps': {0: 0, 1: 0, 'total': 0},
                   'tx_bps': {0: 0, 1: 0, 'total': 0},
                   'tx_bps_l1': {0: 0.0, 1: 0.0, 'total': 0.0},
                   'tx_bytes': {0: 1020068, 1: 0, 'total': 1020068},
                   'tx_pkts': {0: 15001, 1: 0, 'total': 15001},
                   'tx_pps': {0: 0, 1: 0, 'total': 0}},
               1: {'rx_bps': {0: 0, 1: 0, 'total': 0},
                   'rx_bps_l1': {0: 0.0, 1: 0.0, 'total': 0.0},
                   'rx_bytes': {0: nan, 1: nan, 'total': nan},
                   'rx_pkts': {0: 0, 1: 15001, 'total': 15001},
                   'rx_pps': {0: 0, 1: 0, 'total': 0},
                   'tx_bps': {0: 0, 1: 0, 'total': 0},
                   'tx_bps_l1': {0: 0.0, 1: 0.0, 'total': 0.0},
                   'tx_bytes': {0: 1020068, 1: 0, 'total': 1020068},
                   'tx_pkts': {0: 15001, 1: 0, 'total': 15001},
                   'tx_pps': {0: 0, 1: 0, 'total': 0}},
                128: {'rx_bps': {0: 0, 1: 0, 'total': 0},
                'rx_bps_l1': {0: 0.0, 1: 0.0, 'total': 0.0},
                'rx_bytes': {0: nan, 1: nan, 'total': nan},
                'rx_pkts': {0: 15001, 1: 0, 'total': 15001},
                'rx_pps': {0: 0, 1: 0, 'total': 0},
                'tx_bps': {0: 0, 1: 0, 'total': 0},
                'tx_bps_l1': {0: 0.0, 1: 0.0, 'total': 0.0},
                'tx_bytes': {0: 0, 1: 1020068, 'total': 1020068},
                'tx_pkts': {0: 0, 1: 15001, 'total': 15001},
                'tx_pps': {0: 0, 1: 0, 'total': 0}},etc...

        the pg_id (0, 1, 128,...) is the key of the dict and is obtained using the
        get_pg_id() method.
        packet counters for a given stream sent on port p are reported as:
        - tx_pkts[p] on port p
        - rx_pkts[1-p] on the far end port

        This is a tricky/critical counter transposition operation because
        the results are grouped by port (not by stream):
        tx_pkts_port(p=0) comes from pg_id(port=0, chain_idx)['tx_pkts'][0]
        rx_pkts_port(p=0) comes from pg_id(port=1, chain_idx)['rx_pkts'][0]
        tx_pkts_port(p=1) comes from pg_id(port=1, chain_idx)['tx_pkts'][1]
        rx_pkts_port(p=1) comes from pg_id(port=0, chain_idx)['rx_pkts'][1]

        or using a more generic formula:
        tx_pkts_port(p) comes from pg_id(port=p, chain_idx)['tx_pkts'][p]
        rx_pkts_port(p) comes from pg_id(port=1-p, chain_idx)['rx_pkts'][p]

        the second formula is equivalent to
        rx_pkts_port(1-p) comes from pg_id(port=p, chain_idx)['rx_pkts'][1-p]

        If there are latency streams, those same counters need to be added in the same way
        """
        def get_latency(lval):
            try:
                return int(round(lval))
            except ValueError:
                return 0

        for ifs in if_stats:
            ifs.tx = ifs.rx = 0
        for port in range(2):
            pg_id, lat_pg_id = self.get_pg_id(port, chain_idx)
            for pid in [pg_id, lat_pg_id]:
                try:
                    pg_stats = trex_stats['flow_stats'][pid]
                    if_stats[port].tx += pg_stats['tx_pkts'][port]
                    if_stats[1 - port].rx += pg_stats['rx_pkts'][1 - port]
                except KeyError:
                    pass
            try:
                lat = trex_stats['latency'][lat_pg_id]['latency']
                # dropped_pkts += lat['err_cntrs']['dropped']
                latencies[port].max_usec = get_latency(lat['total_max'])
                latencies[port].min_usec = get_latency(lat['total_min'])
                latencies[port].avg_usec = get_latency(lat['average'])
            except KeyError:
                pass

    def __combine_latencies(self, in_stats, results, port_handle):
        """Traverse TRex result dictionary and combines chosen latency stats."""
        total_max = 0
        average = 0
        total_min = float("inf")
        for chain_id in range(self.chain_count):
            try:
                _, lat_pg_id = self.get_pg_id(port_handle, chain_id)
                lat = in_stats['latency'][lat_pg_id]['latency']
                # dropped_pkts += lat['err_cntrs']['dropped']
                total_max = max(lat['total_max'], total_max)
                total_min = min(lat['total_min'], total_min)
                average += lat['average']
            except KeyError:
                pass
        if total_min == float("inf"):
            total_min = 0
        results['min_delay_usec'] = total_min
        results['max_delay_usec'] = total_max
        results['avg_delay_usec'] = int(average / self.chain_count)

    def get_start_end_ipv6(self, start_ip, end_ip):
        ip1 = socket.inet_pton(socket.AF_INET6, start_ip)
        ip2 = socket.inet_pton(socket.AF_INET6, end_ip)
        hi1, lo1 = struct.unpack('!QQ', ip1)
        hi2, lo2 = struct.unpack('!QQ', ip2)
        max_p1 = abs(int(lo1) - int(lo2))
        base_p1 = lo1
        return base_p1, max_p1 + base_p1

    def _create_pkt(self, stream_cfg, l2frame_size):
        """Create a packet of given size.

        l2frame_size: size of the L2 frame in bytes (including the 32-bit FCS)
        """
        # Trex will add the FCS field, so we need to remove 4 bytes from the l2 frame size
        frame_size = int(l2frame_size) - 4

        pkt_base = Ether(src=stream_cfg['mac_src'], dst=stream_cfg['mac_dst'])
        if stream_cfg['vlan_tag'] is not None:
            pkt_base /= Dot1Q(vlan=stream_cfg['vlan_tag'])

        udp_args = {}
        if stream_cfg['udp_src_port']:
            udp_args['sport'] = int(stream_cfg['udp_src_port'])
        if stream_cfg['udp_dst_port']:
            udp_args['dport'] = int(stream_cfg['udp_dst_port'])
        pkt_base /= IPv6(src=stream_cfg['ip_src_addr'], dst=stream_cfg['ip_dst_addr']) / UDP(**udp_args)

        if stream_cfg['ip_addrs_step'] == 'random':
            src_fv = STLVmFlowVarRepetableRandom(
                name="ip_src",
                min_value=stream_cfg['ip_src_addr'],
                max_value=stream_cfg['ip_src_addr_max'],
                size=4,
                seed=random.randint(0, 32767),
                limit=stream_cfg['ip_src_count'])
            dst_fv = STLVmFlowVarRepetableRandom(
                name="ip_dst",
                min_value=stream_cfg['ip_dst_addr'],
                max_value=stream_cfg['ip_dst_addr_max'],
                size=4,
                seed=random.randint(0, 32767),
                limit=stream_cfg['ip_dst_count'])
        else:
            min_val, max_val = self.get_start_end_ipv6(stream_cfg['ip_src_addr'], stream_cfg['ip_src_addr'])
            src_fv = STLVmFlowVar(
                name="ip_src",
                min_value=min_val,
                max_value=max_val,
                size=8,
                op="inc")
            min_val, max_val = self.get_start_end_ipv6(stream_cfg['ip_dst_addr'], stream_cfg['ip_dst_addr_max'])
            dst_fv = STLVmFlowVar(
                name="ip_dst",
                min_value=min_val,
                max_value=max_val,
                size=8,
                op="inc")

        vm_param = [
            src_fv,
            STLVmWrFlowVar(fv_name="ip_src", pkt_offset="IPv6.src", offset_fixup=8),
            dst_fv,
            STLVmWrFlowVar(fv_name="ip_dst", pkt_offset="IPv6.dst", offset_fixup=8),
            STLVmFixChecksumHw(l3_offset="IPv6",
                               l4_offset="UDP",
                               l4_type=CTRexVmInsFixHwCs.L4_TYPE_UDP)
        ]
        pad = max(0, frame_size - len(pkt_base)) * 'x'

        return STLPktBuilder(pkt=pkt_base / pad, vm=STLScVmRaw(vm_param))

    def generate_streams(self, port, chain_id, stream_cfg, l2frame, latency=True, e2e=False):
        """Create a list of streams corresponding to a given chain and stream config.

        port: port where the streams originate (0 or 1)
        chain_id: the chain to which the streams are associated to
        stream_cfg: stream configuration
        l2frame: L2 frame size (including 4-byte FCS) or 'IMIX'
        latency: if True also create a latency stream
        """
        streams = []
        pg_id, lat_pg_id = self.get_pg_id(port, chain_id)
        if l2frame == 'IMIX':
            for ratio, l2_frame_size in zip(IMIX_RATIOS, IMIX_L2_SIZES):
                pkt = self._create_pkt(stream_cfg, l2_frame_size)
                if e2e:
                    streams.append(STLStream(packet=pkt,
                                             mode=STLTXCont(pps=ratio)))
                else:
                    streams.append(STLStream(packet=pkt,
                                             flow_stats=STLFlowStats(pg_id=pg_id),
                                             mode=STLTXCont(pps=ratio)))

            if latency:
                # for IMIX, the latency packets have the average IMIX packet size
                pkt = self._create_pkt(stream_cfg, IMIX_AVG_L2_FRAME_SIZE)

        else:
            l2frame_size = int(l2frame)
            pkt = self._create_pkt(stream_cfg, l2frame_size)
            if e2e:
                streams.append(STLStream(packet=pkt,
                                         mode=STLTXCont()))
            else:
                streams.append(STLStream(packet=pkt,
                                         flow_stats=STLFlowStats(pg_id=pg_id),
                                         mode=STLTXCont()))
            # for the latency stream, the minimum payload is 16 bytes even in case of vlan tagging
            # without vlan, the min l2 frame size is 64
            # with vlan it is 68
            # This only applies to the latency stream
            if latency and stream_cfg['vlan_tag'] and l2frame_size < 68:
                pkt = self._create_pkt(stream_cfg, 68)

        if latency:
            streams.append(STLStream(packet=pkt,
                                     flow_stats=STLFlowLatencyStats(pg_id=lat_pg_id),
                                     mode=STLTXCont(pps=self.LATENCY_PPS)))
        return streams

    @timeout(5)
    def __connect(self, client):
        client.connect()

    def __connect_after_start(self):
        # after start, Trex may take a bit of time to initialize
        # so we need to retry a few times
        for it in xrange(self.config.generic_retry_count):
            try:
                time.sleep(1)
                self.client.connect()
                break
            except Exception as ex:
                if it == (self.config.generic_retry_count - 1):
                    raise
                LOG.info("Retrying connection to TRex (%s)...", ex.message)

    def connect(self):
        """Connect to the TRex server."""
        server_ip = self.generator_config.ip
        LOG.info("Connecting to TRex (%s)...", server_ip)

        # Connect to TRex server
        self.client = STLClient(server=server_ip)
        try:
            self.__connect(self.client)
        except (TimeoutError, STLError) as e:
            if server_ip == '127.0.0.1':
                try:
                    self.__start_server()
                    self.__connect_after_start()
                except (TimeoutError, STLError) as e:
                    LOG.error('Cannot connect to TRex')
                    LOG.error(traceback.format_exc())
                    logpath = '/tmp/trex.log'
                    if os.path.isfile(logpath):
                        # Wait for TRex to finish writing error message
                        last_size = 0
                        for _ in xrange(self.config.generic_retry_count):
                            size = os.path.getsize(logpath)
                            if size == last_size:
                                # probably not writing anymore
                                break
                            last_size = size
                            time.sleep(1)
                        with open(logpath, 'r') as f:
                            message = f.read()
                    else:
                        message = e.message
                    raise TrafficGeneratorException(message)
            else:
                raise TrafficGeneratorException(e.message)

        ports = list(self.generator_config.ports)
        self.port_handle = ports
        # Prepare the ports
        self.client.reset(ports)
        # Read HW information from each port
        # this returns an array of dict (1 per port)
        """
        Example of output for Intel XL710
        [{'arp': '-', 'src_ipv4': '-', u'supp_speeds': [40000], u'is_link_supported': True,
          'grat_arp': 'off', 'speed': 40, u'index': 0, 'link_change_supported': 'yes',
          u'rx': {u'counters': 127, u'caps': [u'flow_stats', u'latency']},
          u'is_virtual': 'no', 'prom': 'off', 'src_mac': u'3c:fd:fe:a8:24:48', 'status': 'IDLE',
          u'description': u'Ethernet Controller XL710 for 40GbE QSFP+',
          'dest': u'fa:16:3e:3c:63:04', u'is_fc_supported': False, 'vlan': '-',
          u'driver': u'net_i40e', 'led_change_supported': 'yes', 'rx_filter_mode': 'hardware match',
          'fc': 'none', 'link': 'UP', u'hw_mac': u'3c:fd:fe:a8:24:48', u'pci_addr': u'0000:5e:00.0',
          'mult': 'off', 'fc_supported': 'no', u'is_led_supported': True, 'rx_queue': 'off',
          'layer_mode': 'Ethernet', u'numa': 0}, ...]
        """
        self.port_info = self.client.get_port_info(ports)
        LOG.info('Connected to TRex')
        for id, port in enumerate(self.port_info):
            LOG.info('   Port %d: %s speed=%dGbps mac=%s pci=%s driver=%s',
                     id, port['description'], port['speed'], port['src_mac'],
                     port['pci_addr'], port['driver'])
        # Make sure the 2 ports have the same speed
        if self.port_info[0]['speed'] != self.port_info[1]['speed']:
            raise TrafficGeneratorException('Traffic generator ports speed mismatch: %d/%d Gbps' %
                                            (self.port_info[0]['speed'],
                                             self.port_info[1]['speed']))

    def __start_server(self):
        server = TRexTrafficServer()
        server.run_server(self.generator_config)

    def resolve_arp(self):
        """Resolve all configured remote IP addresses.

        return: None if ARP failed to resolve for all IP addresses
                else a dict of list of dest macs indexed by port#
                the dest macs in the list are indexed by the chain id
        """
        self.client.set_service_mode(ports=self.port_handle)
        LOG.info('Polling ARP until successful...')
        arp_dest_macs = {}
        for port, device in zip(self.port_handle, self.generator_config.devices):
            # there should be 1 stream config per chain
            stream_configs = device.get_stream_configs()
            chain_count = len(stream_configs)
            ctx = self.client.create_service_ctx(port=port)
            # all dest macs on this port indexed by chain ID
            dst_macs = [None] * chain_count
            dst_macs_count = 0
            # the index in the list is the chain id
            arps = [
                STLServiceARP(ctx,
                              src_ip=cfg['ip_src_tg_gw'],
                              dst_ip=cfg['mac_discovery_gw'],
                              # will be None if no vlan tagging
                              vlan=cfg['vlan_tag'])
                for cfg in stream_configs
            ]

            for attempt in range(self.config.generic_retry_count):
                try:
                    ctx.run(arps)
                except STLError:
                    LOG.error(traceback.format_exc())
                    continue

                unresolved = []
                for chain_id, mac in enumerate(dst_macs):
                    if not mac:
                        arp_record = arps[chain_id].get_record()
                        if arp_record.dst_mac:
                            dst_macs[chain_id] = arp_record.dst_mac
                            dst_macs_count += 1
                            LOG.info('   ARP: port=%d chain=%d src IP=%s dst IP=%s -> MAC=%s',
                                     port, chain_id,
                                     arp_record.src_ip,
                                     arp_record.dst_ip, arp_record.dst_mac)
                        else:
                            unresolved.append(arp_record.dst_ip)
                if dst_macs_count == chain_count:
                    arp_dest_macs[port] = dst_macs
                    LOG.info('ARP resolved successfully for port %s', port)
                    break
                else:
                    retry = attempt + 1
                    LOG.info('Retrying ARP for: %s (retry %d/%d)',
                             unresolved, retry, self.config.generic_retry_count)
                    if retry < self.config.generic_retry_count:
                        time.sleep(self.config.generic_poll_sec)
            else:
                LOG.error('ARP timed out for port %s (resolved %d out of %d)',
                          port,
                          dst_macs_count,
                          chain_count)
                break

        self.client.set_service_mode(ports=self.port_handle, enabled=False)
        if len(arp_dest_macs) == len(self.port_handle):
            return arp_dest_macs
        return None

    def __is_rate_enough(self, l2frame_size, rates, bidirectional, latency):
        """Check if rate provided by user is above requirements. Applies only if latency is True."""
        intf_speed = self.generator_config.intf_speed
        if latency:
            if bidirectional:
                mult = 2
                total_rate = 0
                for rate in rates:
                    r = utils.convert_rates(l2frame_size, rate, intf_speed)
                    total_rate += int(r['rate_pps'])
            else:
                mult = 1
                total_rate = utils.convert_rates(l2frame_size, rates[0], intf_speed)
            # rate must be enough for latency stream and at least 1 pps for base stream per chain
            required_rate = (self.LATENCY_PPS + 1) * self.config.service_chain_count * mult
            result = utils.convert_rates(l2frame_size,
                                         {'rate_pps': required_rate},
                                         intf_speed * mult)
            result['result'] = total_rate >= required_rate
            return result

        return {'result': True}

    def create_traffic(self, l2frame_size, rates, bidirectional, latency=True, e2e=False):
        """Program all the streams in Trex server.

        l2frame_size: L2 frame size or IMIX
        rates: a list of 2 rates to run each direction
               each rate is a dict like {'rate_pps': '10kpps'}
        bidirectional: True if bidirectional
        latency: True if latency measurement is needed
        """
        r = self.__is_rate_enough(l2frame_size, rates, bidirectional, latency)
        if not r['result']:
            raise TrafficGeneratorException(
                'Required rate in total is at least one of: \n{pps}pps \n{bps}bps \n{load}%.'
                .format(pps=r['rate_pps'],
                        bps=r['rate_bps'],
                        load=r['rate_percent']))
        # a dict of list of streams indexed by port#
        # in case of fixed size, has self.chain_count * 2 * 2 streams
        # (1 normal + 1 latency stream per direction per chain)
        # for IMIX, has self.chain_count * 2 * 4 streams
        # (3 normal + 1 latency stream per direction per chain)
        streamblock = {}
        for port in self.port_handle:
            streamblock[port] = []
        stream_cfgs = [d.get_stream_configs() for d in self.generator_config.devices]
        self.rates = [utils.to_rate_str(rate) for rate in rates]
        for chain_id, (fwd_stream_cfg, rev_stream_cfg) in enumerate(zip(*stream_cfgs)):
            streamblock[0].extend(self.generate_streams(self.port_handle[0],
                                                        chain_id,
                                                        fwd_stream_cfg,
                                                        l2frame_size,
                                                        latency=latency,
                                                        e2e=e2e))
            if len(self.rates) > 1:
                streamblock[1].extend(self.generate_streams(self.port_handle[1],
                                                            chain_id,
                                                            rev_stream_cfg,
                                                            l2frame_size,
                                                            latency=bidirectional and latency,
                                                            e2e=e2e))

        for port in self.port_handle:
            self.client.add_streams(streamblock[port], ports=port)
            LOG.info('Created %d traffic streams for port %s.', len(streamblock[port]), port)

    def clear_streamblock(self):
        """Clear all streams from TRex."""
        self.rates = []
        self.client.reset(self.port_handle)
        LOG.info('Cleared all existing streams')

    def get_stats(self):
        """Get stats from Trex."""
        stats = self.client.get_stats()
        return self.extract_stats(stats)

    def get_macs(self):
        """Return the Trex local port MAC addresses.

        return: a list of MAC addresses indexed by the port#
        """
        return [port['src_mac'] for port in self.port_info]

    def get_port_speed_gbps(self):
        """Return the Trex local port MAC addresses.

        return: a list of speed in Gbps indexed by the port#
        """
        return [port['speed'] for port in self.port_info]

    def clear_stats(self):
        """Clear all stats in the traffic gneerator."""
        if self.port_handle:
            self.client.clear_stats()

    def start_traffic(self):
        """Start generating traffic in all ports."""
        for port, rate in zip(self.port_handle, self.rates):
            self.client.start(ports=port, mult=rate, duration=self.config.duration_sec, force=True)

    def stop_traffic(self):
        """Stop generating traffic."""
        self.client.stop(ports=self.port_handle)

    def start_capture(self):
        """Capture all packets on both ports that are unicast to us."""
        if self.capture_id:
            self.stop_capture()
        # Need to filter out unwanted packets so we do not end up counting
        # src MACs of frames that are not unicast to us
        src_mac_list = self.get_macs()
        bpf_filter = "ether dst %s or ether dst %s" % (src_mac_list[0], src_mac_list[1])
        # ports must be set in service in order to enable capture
        self.client.set_service_mode(ports=self.port_handle)
        self.capture_id = self.client.start_capture(rx_ports=self.port_handle,
                                                    bpf_filter=bpf_filter)

    def fetch_capture_packets(self):
        """Fetch capture packets in capture mode."""
        if self.capture_id:
            self.packet_list = []
            self.client.fetch_capture_packets(capture_id=self.capture_id['id'],
                                              output=self.packet_list)

    def stop_capture(self):
        """Stop capturing packets."""
        if self.capture_id:
            self.client.stop_capture(capture_id=self.capture_id['id'])
            self.capture_id = None
            self.client.set_service_mode(ports=self.port_handle, enabled=False)

    def cleanup(self):
        """Cleanup Trex driver."""
        if self.client:
            try:
                self.client.reset(self.port_handle)
                self.client.disconnect()
            except STLError:
                # TRex does not like a reset while in disconnected state
                pass
