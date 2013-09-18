# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Music app autopilot emulators."""

from ubuntuuitoolkit import emulators as uitk

class MainView(uitk.MainView):
    """An emulator class that makes it easy to interact with the
    music-app.
    """
    retry_delay = 0.2

    def __init__(self, app):
        self.app = app

    def get_qml_view(self):
        """Get the main QML view"""
        return self.app.select_single("QQuickView")

    def get_main_view(self):
        return self.app.select_single("MainView", objectName = "music")

    def select_many_retry(self, object_type, **kwargs):
        """Returns the item that is searched for with app.select_many
        In case of no item was not found (not created yet) a second attempt is
        taken 1 second later"""
        items = self.select_many(object_type, **kwargs)
        tries = 10
        while len(items) < 1 and tries > 0:
            sleep(self.retry_delay)
            items = self.select_many(object_type, **kwargs)
            tries = tries - 1
        return items

    def select_single_retry(self, object_type, **kwargs):
        """Returns the item that is searched for with app.select_single
        In case of the item was not found (not created yet) a second attempt is
        taken 1 second later."""
        item = self.select_single(object_type, **kwargs)
        tries = 10
        while item is None and tries > 0:
            sleep(self.retry_delay)
            item = self.select_single(object_type, **kwargs)
            tries = tries - 1
        return item

    def get_play_button(self):
        return self.app.select_single("UbuntuShape", objectName = "playshape")

    def get_forward_button(self):
        return self.app.select_single(
            "UbuntuShape", objectName = "forwardshape")