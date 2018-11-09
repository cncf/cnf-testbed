import pytest


@pytest.mark.parametrize('f', ['/usr/local/sbin/etcd',
                               '/usr/local/sbin/etcdctl'])
def test_etcd_installed(File, f):
    file = File(f)

    assert file.exists


def test_cluster_configured(Interface, Command):
    address = Interface('eth0').addresses[0]
    cmd = ('curl -qs '
           'http://{0}:2379/v2/machines | '
           'grep -o 2379 | '
           'wc -l').format(address)

    assert Command.check_output(cmd) == '6'
