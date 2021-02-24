import time
from os.path import dirname, join
from subprocess import check_output

import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from syncloudlib.integration.hosts import add_host_alias_by_ip
from syncloudlib.integration.screenshots import screenshots
from syncloudlib.integration.installer import local_install

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud/ui'


@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir, ui_mode):
    def module_teardown():
        device.activated()
        device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl > {0}/journalctl.ui.{1}.log'.format(TMP_DIR, ui_mode), throw=False)
        device.run_ssh('cp /var/log/syslog {0}/syslog.ui.{1}.log'.format(TMP_DIR, ui_mode), throw=False)
        device.scp_from_device('{0}/*'.format(TMP_DIR), join(artifact_dir, 'log'))
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


def test_start(module_setup, app, domain, device_host):
    add_host_alias_by_ip(app, domain, device_host)


def test_index(driver, app_domain, ui_mode, screenshot_dir):
    driver.get("https://{0}".format(app_domain))
    screenshots(driver, screenshot_dir, 'index-' + ui_mode)


# def test_login(driver, app_domain, ui_mode, screenshot_dir, device_user, device_password):
#     driver.get("https://{0}".format(app_domain))
#     login = "//a[text()='Log In']"
#     wait_or_screenshot(driver, ui_mode, screenshot_dir,
#                        EC.presence_of_element_located((By.XPATH, login)))
#     btn = driver.find_element_by_xpath(login)
#     btn.click()
#     user_xpath = "//input[@name='user_id']"
#     wait_or_screenshot(driver, ui_mode, screenshot_dir,
#                        EC.presence_of_element_located((By.XPATH, user_xpath)))
#     user = driver.find_element_by_xpath(user_xpath)
#     user.send_keys(device_user)
#     password = driver.find_element_by_name("password")
#     password.send_keys(device_password)
#     screenshots(driver, screenshot_dir, 'login-credentials-' + ui_mode)
#     password.submit()
#     logout = "//a[text()='Log Out']"
#     wait_or_screenshot(driver, ui_mode, screenshot_dir,
#                        EC.presence_of_element_located((By.XPATH, logout)))
#     screenshots(driver, screenshot_dir, 'main-' + ui_mode)

def wait_or_screenshot(driver, ui_mode, screenshot_dir, method):
    wait_driver = WebDriverWait(driver, 30)
    try:
        wait_driver.until(method)
    except Exception as e:
        screenshots(driver, screenshot_dir, 'exception-' + ui_mode)
        raise e

