/*
 * Copyright (C) 2013, 2014
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

import QtQuick 2.3
import Ubuntu.Components 1.1
import Ubuntu.MediaScanner 0.1
import Ubuntu.Thumbnailer 0.1
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import "settings.js" as Settings
import "playlists.js" as Playlists
import "common"
import "common/ListItemActions"


MusicPage {
    id: mainpage
    objectName: "tracksPage"
    title: i18n.tr("Songs")

    state: tracklist.state === "multiselectable" ? "selection" : "default"
    states: [
        PageHeadState {
            id: selectionState
            name: "selection"
            backAction: Action {
                text: i18n.tr("Cancel selection")
                iconName: "back"
                onTriggered: tracklist.state = "normal"
            }
            actions: [
                Action {
                    iconName: "select"
                    text: i18n.tr("Select All")
                    onTriggered: {
                        if (tracklist.selectedItems.length === tracklist.model.count) {
                            tracklist.clearSelection(false)
                        } else {
                            tracklist.selectAll()
                        }
                    }
                },
                Action {
                    enabled: tracklist.selectedItems.length !== 0
                    iconName: "add-to-playlist"
                    text: i18n.tr("Add to playlist")
                    onTriggered: {
                        var items = []

                        for (var i=0; i < tracklist.selectedItems.length; i++) {
                            items.push(makeDict(tracklist.model.get(tracklist.selectedItems[i], tracklist.model.RoleModelData)));
                        }

                        chosenElements = items;
                        mainPageStack.push(addtoPlaylist)

                        tracklist.clearSelection(true)
                    }
                },
                Action {
                    enabled: tracklist.selectedItems.length > 0
                    iconName: "add"
                    text: i18n.tr("Add to queue")
                    onTriggered: {
                        for (var i=0; i < tracklist.selectedItems.length; i++) {
                            trackQueue.model.append(makeDict(tracklist.model.get(tracklist.selectedItems[i], tracklist.model.RoleModelData)));
                        }

                        tracklist.clearSelection(true)
                    }
                }
            ]
            PropertyChanges {
                target: mainpage.head
                backAction: selectionState.backAction
                actions: selectionState.actions
            }
        }
    ]

    ListView {
        id: tracklist
        anchors {
            fill: parent
            topMargin: units.gu(2)
        }
        highlightFollowsCurrentItem: false
        objectName: "trackstab-listview"
        model: SortFilterModel {
            id: songsModelFilter
            property alias rowCount: songsModel.rowCount
            model: SongsModel {
                id: songsModel
                store: musicStore
            }
            sort.property: "title"
            sort.order: Qt.AscendingOrder
        }

        // Requirements for ListItemWithActions
        property var selectedItems: []

        signal clearSelection(bool closeSelection)
        signal selectAll()

        onClearSelection: {
            selectedItems = []

            if (closeSelection || closeSelection === undefined) {
                state = "normal"
            }
        }
        onSelectAll: {
            for (var i=0; i < model.count; i++) {
                if (selectedItems.indexOf(i) === -1) {
                    selectedItems.push(i)
                }
            }
        }
        onVisibleChanged: {
            if (!visible) {
                clearSelection(true)
            }
        }

        delegate: trackDelegate
        Component {
            id: trackDelegate

            ListItemWithActions {
                id: track
                color: "transparent"
                objectName: "tracksPageListItem" + index
                width: parent.width
                height: units.gu(7)
                showDivider: false

                multiselectable: true
                rightSideActions: [
                    AddToQueue {
                    },
                    AddToPlaylist {

                    }
                ]

                // TODO: If http://pad.lv/1354753 is fixed to expose whether the Shape should appear pressed, update this as well.
                onPressedChanged: musicRow.pressed = pressed

                onItemClicked: trackClicked(tracklist.model, index)  // play track

                MusicRow {
                    id: musicRow
                    anchors.verticalCenter: parent.verticalCenter
                    covers: [{art: model.art}]
                    isSquare: true
                    coverSize: units.gu(6)
                    spacing: units.gu(2)
                    column: Column {
                        Label {
                            id: trackTitle
                            color: styleMusic.common.music
                            fontSize: "small"
                            objectName: "tracktitle"
                            text: model.title
                        }

                        Label {
                            id: trackArtist
                            color: styleMusic.common.subtitle
                            fontSize: "x-small"
                            text: model.author
                        }
                    }
                }

                states: State {
                    name: "Current"
                    when: track.ListView.isCurrentItem
                }
            }
        }
    }
}

