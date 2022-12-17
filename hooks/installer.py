import logging
import os
from os.path import join, isfile

from syncloudlib import fs, linux, gen, logger
from syncloudlib.application import paths, storage

APP_NAME = 'plex'

USER_NAME = 'plex'
DB_NAME = APP_NAME
DB_USER = APP_NAME
DB_PASSWORD = APP_NAME


class Installer:
    def __init__(self):
        if not logger.factory_instance:
            logger.init(logging.DEBUG, True)

        self.log = logger.get_logger('{0}_installer'.format(APP_NAME))
        self.app_dir = paths.get_app_dir(APP_NAME)
        self.common_dir = paths.get_data_dir(APP_NAME)
        self.snap_data_dir = os.environ['SNAP_DATA']

    def install_config(self):

        home_folder = join(self.common_dir, USER_NAME)
        linux.useradd(USER_NAME, home_folder=home_folder)
        
        fs.makepath(join(self.common_dir, 'log'))
        fs.makepath(join(self.common_dir, 'nginx'))
        fs.makepath(join(self.snap_data_dir, 'Application_Support'))

        storage.init_storage(APP_NAME, USER_NAME)

        templates_path = join(self.app_dir, 'config')
        config_path = join(self.snap_data_dir, 'config')

        variables = {
            'app': APP_NAME,
            'app_dir': self.app_dir,
            'common_dir': self.common_dir,
            'snap_data': self.snap_data_dir
        }
        gen.generate_files(templates_path, config_path, variables)
        fs.chownpath(self.snap_data_dir, USER_NAME, recursive=True)
        fs.chownpath(self.common_dir, USER_NAME, recursive=True)

    def install(self):
        self.install_config()

    def post_refresh(self):
        self.install_config()
        
    def configure(self):
        self.prepare_storage()
        install_file = join(self.common_dir, 'installed')
        if not isfile(install_file):
            fs.touchfile(install_file)
        # else:
            # upgrade
    
    def on_disk_change(self):
        self.prepare_storage()
        
    def prepare_storage(self):
        app_storage_dir = storage.init_storage(APP_NAME, USER_NAME)
