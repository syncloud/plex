import requests
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.http import wait_for_rest

TMP_DIR = '/tmp/syncloud'


def test_start(app, device_host, domain, device, snapd_settle):
    add_host_alias(app, device_host, domain)
    device.activated()
    device.run_ssh('rm -rf {0}'.format(TMP_DIR), throw=False)
    device.run_ssh('mkdir {0}'.format(TMP_DIR), throw=False)
    snapd_settle()


def test_install_released(device, app, app_domain):
    device.run_ssh('snap remove {0}'.format(app), throw=False)
    device.run_ssh('snap install {0}'.format(app), retries=10)
    wait_for_rest(requests.session(), 'https://{0}/web'.format(app_domain), 200, 100)
