/*
 * Copyright (C) 2013 Victor Thompson <victor.thompson@gmail.com>
 *                    Daniel Holm <d.holmen@gmail.com>
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

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import org.nemomobile.folderlistmodel 1.0
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import "settings.js" as Settings
import "meta-database.js" as Library
import "playing-list.js" as PlayingList

Page {
    title: i18n.tr("Artists")

    tools: ToolbarItems {
        // Settings dialog
        ToolbarButton {
            objectName: "settingsaction"
            iconSource: Qt.resolvedUrl("images/settings.png")
            text: i18n.tr("Settings")

            onTriggered: {
                console.debug('Debug: Show settings')
                PopupUtils.open(Qt.resolvedUrl("MusicSettings.qml"), mainView,
                                {
                                    title: i18n.tr("Settings")
                                } )
            }
        }

        // Queue dialog
        ToolbarButton {
            objectName: "queuesaction"
            iconSource: Qt.resolvedUrl("images/folder.png") // change this icon later
            text: i18n.tr("Queue")

            onTriggered: {
                console.debug('Debug: Show queue')
                PopupUtils.open(Qt.resolvedUrl("QueueDialog.qml"), mainView,
                                {
                                    title: i18n.tr("Queue")
                                } )
            }
        }
    }

    Component {
        id: highlight
        Rectangle {
            width: 5; height: 40
            color: "#DD4814";
            Behavior on y {
                SpringAnimation {
                    spring: 3
                    damping: 0.2
                }
            }
        }
    }

    ListView {
        id: artistlist
        width: parent.width
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.bottomMargin: units.gu(8)
        highlight: highlight
        highlightFollowsCurrentItem: true
        model: artistModel.model
        delegate: artistDelegate

        Component {
            id: artistDelegate

            ListItem.Standard {
                id: track
                property string artist: model.artist
                property string album: model.album
                property string title: model.title
                property string cover: model.cover
                property string length: model.length
                property string file: model.file
                icon: cover === "" ? (file.match("\\.mp3") ? Qt.resolvedUrl("images/audio-x-mpeg.png") : Qt.resolvedUrl("images/audio-x-vorbis+ogg.png")) : "image://cover-art/"+file
                iconFrame: false
                Label {
                    id: trackTitle
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                    fontSize: "medium"
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(8)
                    anchors.top: parent.top
                    anchors.topMargin: 5
                    anchors.right: parent.right
                    text: track.title == "" ? track.file : track.title
                }
                Label {
                    id: trackArtistAlbum
                    wrapMode: Text.NoWrap
                    maximumLineCount: 2
                    fontSize: "small"
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(8)
                    anchors.top: trackTitle.bottom
                    anchors.right: parent.right
                    text: artist == "" ? "" : artist + " - " + album
                }
                Label {
                    id: trackDuration
                    wrapMode: Text.NoWrap
                    maximumLineCount: 2
                    fontSize: "small"
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(8)
                    anchors.top: trackArtistAlbum.bottom
                    anchors.right: parent.right
                    visible: false
                    text: ""
                }

                onFocusChanged: {
                    if (focus == false) {
                        selected = false
                    } else {
                        selected = false
                        mainView.currentArtist = artist
                        mainView.currentAlbum = album
                        mainView.currentTracktitle = title
                        mainView.currentFile = file
                        mainView.currentCover = cover
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onDoubleClicked: {
                    }
                    onPressAndHold: {
                        trackQueue.append({"title": title, "artist": artist, "file": file})
                    }
                    onClicked: {
                        if (focus == false) {
                            focus = true
                        }
                        console.log("fileName: " + file)
                        if (tracklist.currentIndex == index) {
                            if (player.playbackState === MediaPlayer.PlayingState)  {
                                player.pause()
                            } else if (player.playbackState === MediaPlayer.PausedState) {
                                player.play()
                            }
                        } else {
                            player.stop()
                            player.source = Qt.resolvedUrl(file)
                            tracklist.currentIndex = index
                            playing = PlayingList.indexOf(file)
                            console.log("Playing click: "+player.source)
                            console.log("Index: " + tracklist.currentIndex)
                            player.play()
                        }
                        console.log("Source: " + player.source.toString())
                        console.log("Length: " + length.toString())
                    }
                }
                Component.onCompleted: {
                    if (PlayingList.size() === 0) {
                        player.source = file
                    }

                    if (!PlayingList.contains(file)) {
                        console.log("Adding file:" + file)
                        PlayingList.addItem(file, itemnum)
                        console.log(itemnum)
                    }
                    console.log("Title:" + title + " Artist: " + artist)
                    itemnum++
                }
            }
        }
    }
}
