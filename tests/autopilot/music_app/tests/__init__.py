# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013, 2014 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Music app autopilot tests."""

import os
import os.path
import shutil
import sqlite3
import logging
import music_app

import fixtures
from music_app import MusicApp

from autopilot import logging as autopilot_logging
from autopilot.input import Mouse, Touch
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase

import ubuntuuitoolkit
from ubuntuuitoolkit import (
    base,
    fixture_setup as toolkit_fixtures
)


logger = logging.getLogger(__name__)


class BaseTestCaseWithPatchedHome(AutopilotTestCase):

    """A common test case class that provides several useful methods for
    music-app tests.

    """
    if model() == 'Desktop':
        scenarios = [('with mouse', dict(input_device_class=Mouse))]
    else:
        scenarios = [('with touch', dict(input_device_class=Touch))]

    working_dir = os.getcwd()
    local_location_dir = os.path.dirname(os.path.dirname(working_dir))
    local_location = local_location_dir + "/music-app.qml"
    installed_location = "/usr/share/music-app/music-app.qml"

    def get_launcher_method_and_type(self):
        if os.path.exists(self.local_location):
            launch = self.launch_test_local
            test_type = 'local'
        elif os.path.exists(self.installed_location):
            launch = self.launch_test_installed
            test_type = 'deb'
        else:
            launch = self.launch_test_click
            test_type = 'click'
        return launch, test_type

    def setUp(self):
        super(BaseTestCaseWithPatchedHome, self).setUp()
        _, test_type = self.get_launcher_method_and_type()
        self.home_dir = self._patch_home(test_type)

        self._create_music_library(test_type)

    @autopilot_logging.log_action(logger.info)
    def launch_test_local(self):
        return self.launch_test_application(
            base.get_qmlscene_launch_command(),
            self.local_location,
            "debug",
            app_type='qt',
            emulator_base=ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase)

    @autopilot_logging.log_action(logger.info)
    def launch_test_installed(self):
        return self.launch_test_application(
            base.get_qmlscene_launch_command(),
            self.installed_location,
            "debug",
            app_type='qt',
            emulator_base=ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase)

    @autopilot_logging.log_action(logger.info)
    def launch_test_click(self):
        return self.launch_click_package(
            "com.ubuntu.music",
            emulator_base=ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase)

    def _copy_xauthority_file(self, directory):
        """ Copy .Xauthority file to directory, if it exists in /home
        """
        # If running under xvfb, as jenkins does,
        # xsession will fail to start without xauthority file
        # Thus if the Xauthority file is in the home directory
        # make sure we copy it to our temp home directory

        xauth = os.path.expanduser(os.path.join(os.environ.get('HOME'),
                                   '.Xauthority'))
        if os.path.isfile(xauth):
            logger.debug("Copying .Xauthority to %s" % directory)
            shutil.copyfile(
                os.path.expanduser(os.path.join(os.environ.get('HOME'),
                                   '.Xauthority')),
                os.path.join(directory, '.Xauthority'))

    def _patch_home(self, test_type):
        """ mock /home for testing purposes to preserve user data
        """
        # click requires apparmor profile, and writing to special dir
        # but the desktop can write to a traditional /tmp directory
        if test_type == 'click':
            env_dir = os.path.join(os.environ.get('HOME'), 'autopilot',
                                   'fakeenv')

            if not os.path.exists(env_dir):
                os.makedirs(env_dir)

            temp_dir_fixture = fixtures.TempDir(env_dir)
            self.useFixture(temp_dir_fixture)

            # apparmor doesn't allow the app to create needed directories,
            # so we create them now
            temp_dir = temp_dir_fixture.path
            temp_dir_cache = os.path.join(temp_dir, '.cache')
            temp_dir_cache_font = os.path.join(temp_dir_cache, 'fontconfig')
            temp_dir_cache_media = os.path.join(temp_dir_cache, 'media-art')
            temp_dir_cache_write = os.path.join(temp_dir_cache,
                                                'tncache-write-text.null')
            temp_dir_config = os.path.join(temp_dir, '.config')
            temp_dir_toolkit = os.path.join(temp_dir_config,
                                            'ubuntu-ui-toolkit')
            temp_dir_font = os.path.join(temp_dir_cache, '.fontconfig')
            temp_dir_local = os.path.join(temp_dir, '.local', 'share')
            temp_dir_confined = os.path.join(temp_dir, 'confined')

            if not os.path.exists(temp_dir_cache):
                os.makedirs(temp_dir_cache)
            if not os.path.exists(temp_dir_cache_font):
                os.makedirs(temp_dir_cache_font)
            if not os.path.exists(temp_dir_cache_media):
                os.makedirs(temp_dir_cache_media)
            if not os.path.exists(temp_dir_cache_write):
                os.makedirs(temp_dir_cache_write)
            if not os.path.exists(temp_dir_config):
                os.makedirs(temp_dir_config)
            if not os.path.exists(temp_dir_toolkit):
                os.makedirs(temp_dir_toolkit)
            if not os.path.exists(temp_dir_font):
                os.makedirs(temp_dir_font)
            if not os.path.exists(temp_dir_local):
                os.makedirs(temp_dir_local)
            if not os.path.exists(temp_dir_confined):
                os.makedirs(temp_dir_confined)

            # before we set fixture, copy xauthority if needed
            self._copy_xauthority_file(temp_dir)
            self.useFixture(toolkit_fixtures.InitctlEnvironmentVariable(
                            HOME=temp_dir))
        else:
            temp_dir_fixture = fixtures.TempDir()
            self.useFixture(temp_dir_fixture)
            temp_dir = temp_dir_fixture.path

            # before we set fixture, copy xauthority if needed
            self._copy_xauthority_file(temp_dir)
            self.useFixture(fixtures.EnvironmentVariable('HOME',
                                                         newvalue=temp_dir))

        logger.debug("Patched home to fake home directory %s" % temp_dir)
        return temp_dir

    def _create_music_library(self, test_type):
        logger.debug("Creating music library for %s test" % test_type)
        logger.debug("Home set to %s" % self.home_dir)
        musicpath = os.path.join(self.home_dir, 'Music')
        logger.debug("Music path set to %s" % musicpath)
        mediascannerpath = os.path.join(self.home_dir,
                                        '.cache/mediascanner-2.0')
        if not os.path.exists(musicpath):
            os.makedirs(musicpath)
        logger.debug("Mediascanner path set to %s" % mediascannerpath)

        # set content path
        content_dir = os.path.join(os.path.dirname(music_app.__file__),
                                   'content')

        logger.debug("Content dir set to %s" % content_dir)

        # copy content
        shutil.copy(os.path.join(content_dir, '1.ogg'), musicpath)
        shutil.copy(os.path.join(content_dir, '2.ogg'), musicpath)
        shutil.copy(os.path.join(content_dir, '3.mp3'), musicpath)
        shutil.copytree(
            os.path.join(content_dir, 'mediascanner-2.0'), mediascannerpath)

        logger.debug("Music copied, files " + str(os.listdir(musicpath)))

        self._patch_mediascanner_home(mediascannerpath)

        logger.debug(
            "Mediascanner database copied, files " +
            str(os.listdir(mediascannerpath)))

    def _patch_mediascanner_home(self, mediascannerpath):
        # do some inline db patching
        # patch mediaindex to proper home
        # these values are dependent upon our sampled db
        logger.debug("Patching fake mediascanner database in %s" %
                     mediascannerpath)
        logger.debug(
            "Mediascanner database files " +
            str(os.listdir(mediascannerpath)))

        relhome = self.home_dir[1:]
        dblocation = "home/phablet"
        # patch mediaindex
        self._file_find_replace(mediascannerpath +
                                "/mediastore.sql", dblocation, relhome)

        con = sqlite3.connect(mediascannerpath + "/mediastore.db")
        f = open(mediascannerpath + "/mediastore.sql", 'r', encoding='utf-8')
        sql = f.read()
        cur = con.cursor()
        cur.executescript(sql)
        con.close()

    def _file_find_replace(self, in_filename, find, replace):
        # replace all occurences of string find with string replace
        # in the given file
        out_filename = in_filename + ".tmp"
        infile = open(in_filename, 'rb')
        outfile = open(out_filename, 'wb')
        for line in infile:
            outfile.write(line.replace(str.encode(find), str.encode(replace)))
        infile.close()
        outfile.close()

        # remove original file and copy new file back
        os.remove(in_filename)
        os.rename(out_filename, in_filename)


class MusicAppTestCase(BaseTestCaseWithPatchedHome):

    """Base test case that launches the music-app."""

    def setUp(self):
        super(MusicAppTestCase, self).setUp()
        launcher_method, _ = self.get_launcher_method_and_type()
        self.app = MusicApp(launcher_method())
