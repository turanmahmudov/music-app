/*
 * Copyright (C) 2013, 2014, 2015, 2016
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Daniel Holm <d.holmen@gmail.com>
 *      Victor Thompson <victor.thompson@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3

import "HeadState"

Rectangle {
    id: nowPlayingSidebar
    anchors {
        fill: parent
    }
    color: "#2c2c34"
    state: queue.state === "multiselectable" ? "selection" : "default"
    states: [
        PageHeadState {
            id: defaultState
            name: "default"
            actions: [
                Action {
                    enabled: !player.mediaPlayer.playlist.empty
                    iconName: "add-to-playlist"
                    // TRANSLATORS: this action appears in the overflow drawer with limited space (around 18 characters)
                    text: i18n.tr("Add to playlist")

                    onTriggered: {
                        var items = []

                        items.push(makeDict(player.metaForSource(player.mediaPlayer.playlist.currentItemSource)));

                        mainPageStack.push(Qt.resolvedUrl("../ui/AddToPlaylist.qml"),
                                           {"chosenElements": items})
                    }
                },
                Action {
                    enabled: !player.mediaPlayer.playlist.empty
                    iconName: "delete"
                    objectName: "clearQueue"
                    // TRANSLATORS: this action appears in the overflow drawer with limited space (around 18 characters)
                    text: i18n.tr("Clear queue")

                    onTriggered: player.mediaPlayer.playlist.clearWrapper()
                }
            ]
            PropertyChanges {
                target: pageHeader.leadingActionBar
                actions: defaultState.backAction
            }
            PropertyChanges {
                target: pageHeader.trailingActionBar
                actions: defaultState.actions
            }
        },
        MultiSelectHeadState {
            addToQueue: false
            listview: queue
            removable: true
            thisPage: nowPlayingSidebar

            onRemoved: {
                // Remove the tracks from the queue
                // Use slice() to copy the list
                // so that the indexes don't change as they are removed
                player.mediaPlayer.playlist.removeItemsWrapper(selectedIndices.slice());
            }
        }
    ]
    property alias header: pageHeader

    PageHeader {
        id: pageHeader
        leadingActionBar {
            actions: nowPlayingSidebar.head.backAction
        }
        flickable: queue
        trailingActionBar {
            actions: nowPlayingSidebar.head.actions
        }
        z: 100  // put on top of content

        StyleHints {
            backgroundColor: mainView.headerColor
        }
    }

    Queue {
        id: queue
        clip: true
        isSidebar: true
        header: Column {
            id: sidebarColumn
            anchors {
                left: parent.left
                right: parent.right
            }

            NowPlayingFullView {
                anchors {
                    fill: undefined
                }
                backgroundColor: "#2c2c34"
                clip: true
                height: units.gu(47)
                sidebar: true
                width: parent.width
            }

            NowPlayingToolbar {
                anchors {
                    fill: undefined
                }
                bottomProgressHint: false
                color: "#2c2c34"
                height: itemSize + 2 * spacing + units.gu(2)
                width: parent.width
            }
        }
    }
}
