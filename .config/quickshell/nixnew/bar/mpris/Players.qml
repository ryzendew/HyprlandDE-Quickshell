pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Mpris
import ".."
import "../.."

FullwidthMouseArea {
	id: root
	hoverEnabled: true
	fillWindowWidth: true

	required property var bar;
	implicitHeight: column.implicitHeight + 10

	PersistentProperties {
		id: persist
		reloadableId: "MusicWidget";
		property bool widgetOpen: false;

		onReloaded: {
			rightclickMenu.snapOpacity(widgetOpen ? 1.0 : 0.0)
		}
	}

	property alias widgetOpen: persist.widgetOpen;

	acceptedButtons: Qt.RightButton | Qt.ForwardButton | Qt.BackButton
	onPressed: event => {
		if (event.button == Qt.RightButton) widgetOpen = !widgetOpen;
		else if (event.button == Qt.ForwardButton) {
			MprisController.next();
		} else if (event.button == Qt.BackButton) {
			MprisController.previous();
		}
	}

	onWheel: event => {
		event.accepted = true;
		if (MprisController.canChangeVolume) {
			root.activePlayer.volume = Math.max(0, Math.min(1, root.activePlayer.volume + (event.angleDelta.y / 120) * 0.05));
		}
	}

	readonly property var activePlayer: MprisController.activePlayer

	Item {
		id: widget
		anchors.fill: parent

		property real scaleMul: widgetOpen ? 100 : 1
		Behavior on scaleMul { SmoothedAnimation { velocity: 600 } }
		scale: scaleCurve.interpolate(scaleMul / 100, 1, (width - 6) / width)

		EasingCurve {
			id: scaleCurve
			curve.type: Easing.Linear
		}

		implicitHeight: column.implicitHeight + 10

		BackgroundArt {
			id: bkg
			anchors.fill: parent
			overlay.color: "#30000000"

			function updateArt(reverse: bool) {
				console.log("update art", MprisController.activeTrack.artUrl)
				this.setArt(MprisController.activeTrack.artUrl, reverse, false)
			}

			Component.onCompleted: this.updateArt(false);

			Connections {
				target: MprisController

				function onTrackChanged(reverse: bool) {
					bkg.updateArt(reverse);
				}
			}
		}

		ColumnLayout {
			id: column

			anchors {
				fill: parent
				margins: 5;
			}

			ClickableIcon {
				Layout.fillWidth: true
				image: "root:icons/rewind.svg"
				implicitHeight: width
				scaleIcon: false
				baseMargin: 3
				hoverEnabled: false
				enabled: MprisController.canGoPrevious;
				onClicked: MprisController.previous();
			}

			ClickableIcon {
				Layout.fillWidth: true
				image: `root:icons/${MprisController.isPlaying ? "pause" : "play"}.svg`;
				implicitHeight: width
				scaleIcon: false
				hoverEnabled: false
				enabled: MprisController.canTogglePlaying;
				onClicked: MprisController.togglePlaying();
			}

			ClickableIcon {
				Layout.fillWidth: true
				image: "root:icons/fast-forward.svg"
				implicitHeight: width
				scaleIcon: false
				baseMargin: 3
				hoverEnabled: false
				enabled: MprisController.canGoNext;
				onClicked: MprisController.next();
			}
		}

		property Scope positionInfo: Scope {
			id: positionInfo

			property var player: root.activePlayer;
			property int position: Math.floor(player.position);
			property int length: Math.floor(player.length);

			FrameAnimation {
				id: posTracker;
				running: positionInfo.player.isPlaying && (tooltip.visible || rightclickMenu.visible);
				onTriggered: positionInfo.player.positionChanged();
			}

			function timeStr(time: int): string {
				const seconds = time % 60;
				const minutes = Math.floor(time / 60);

				return `${minutes}:${seconds.toString().padStart(2, '0')}`
			}
		}

		property TooltipItem tooltip: TooltipItem {
			id: tooltip
			tooltip: bar.tooltip
			owner: root

			show: root.containsMouse

			/*ColumnLayout {
				ColumnLayout {
					visible: MprisController.activePlayer != null

					Label { text: MprisController.activeTrack?.title ?? "" }

					Label {
						text: {
							const artist = MprisController.activeTrack?.artist ?? "";
							const album = MprisController.activeTrack?.album ?? "";

							return artist + (album ? ` - ${album}` : "");
						}
					}

					Label { text: MprisController.activePlayer?.identity ?? "" }
				}

				Label {
					visible: MprisController.activePlayer == null
					text: "No media playing"
				}

				Rectangle { implicitHeight: 10; color: "white"; Layout.fillWidth: true }
				}*/

			contentItem.anchors.margins: 0

			Item {
				id: ttcontent
				width: parent.width
				height: Math.max(parent.height, implicitHeight)
				implicitWidth: cl.implicitWidth + 10
				implicitHeight: cl.implicitHeight + 10 + (MprisController.activePlayer ? 8 : 0)

				ColumnLayout {
					id: cl
					anchors {
						left: parent.left
						right: parent.right
						top: parent.top
						margins: 5
					}

					//visible: MprisController.activePlayer != null

					FontMetrics { id: fontmetrics }

					component FullheightLabel: Item {
						implicitHeight: fontmetrics.height
						implicitWidth: label.implicitWidth

						property alias text: label.text

						Label {
							id: label
							anchors.verticalCenter: parent.verticalCenter
						}
					}

					FullheightLabel {
						visible: MprisController.activePlayer != null
						text: MprisController.activeTrack?.title ?? ""
					}

					FullheightLabel {
						visible: MprisController.activePlayer != null
						text: MprisController.activeTrack?.artist ?? ""
						/*text: {
							const artist = MprisController.activeTrack?.artist ?? "";
							const album = MprisController.activeTrack?.album ?? "";

							return artist + (album ? ` - ${album}` : "");
						}*/
					}

					Label {
						text: {
							if (!MprisController.activePlayer) return "No media playing";

							return MprisController.activePlayer?.identity + " - "
								+ positionInfo.timeStr(positionInfo.position) + " / "
								+ positionInfo.timeStr(positionInfo.length);
						}
					}
				}

				Rectangle {
					id: ttprect
					anchors {
						left: parent.left
						right: parent.right
						bottom: parent.bottom
					}

					color: "#30ceffff"
					implicitHeight: 8
					visible: MprisController.activePlayer != null

					Rectangle {
						anchors {
							left: parent.left
							top: parent.top
							bottom: parent.bottom
						}

						color: "#80ceffff"
						width: parent.width * (root.activePlayer.position / root.activePlayer.length)
					}
				}


				layer.enabled: true
				layer.effect: OpacityMask {
					maskSource: Rectangle {
						width: ttcontent.width
						height: ttcontent.height
						bottomLeftRadius: 5
						bottomRightRadius: 5
					}
				}
			}
		}

		property var rightclickMenu: TooltipItem {
			id: rightclickMenu
			tooltip: bar.tooltip
			owner: root

			isMenu: true
			show: widgetOpen
			onClose: widgetOpen = false

			// some very large covers take a sec to appear in the background,
			// so we'll try to preload them.
			preloadBackground: root.containsMouse

			backgroundComponent: BackgroundArt {
				id: popupBkg
				anchors.fill: parent
				renderHeight: rightclickMenu.implicitHeight
				renderWidth: rightclickMenu.implicitWidth
				blurRadius: 100
				blurSamples: 201

				overlay.color: "#80000000"

				Connections {
					target: MprisController

					function onTrackChanged(reverse: bool) {
						console.log(`track changed: rev: ${reverse}`)
						popupBkg.setArt(MprisController.activeTrack.artUrl, reverse, false);
					}
				}

				Component.onCompleted: {
					setArt(MprisController.activeTrack.artUrl, false, true);
				}
			}

			contentItem {
				implicitWidth: 500
				implicitHeight: 650
			}

			Loader {
				active: rightclickMenu.visible
				width: 500
				height: 650

				sourceComponent: ColumnLayout {
					anchors.fill: parent;

					property var player: root.activePlayer;

					Connections {
						target: MprisController

						function onTrackChanged(reverse: bool) {
							trackStack.updateTrack(reverse, false);
						}
					}

					Item {
						id: playerSelectorContainment
						Layout.fillWidth: true
						implicitHeight: playerSelector.implicitHeight + 20
						implicitWidth: playerSelector.implicitWidth

						Rectangle {
							anchors.centerIn: parent
							implicitWidth: 50
							implicitHeight: 50
							radius: 5
							color: "#20ceffff"
						}

						RowLayout { //ScrollView {
							property Item selectedPlayerDisplay: null;
							onSelectedPlayerDisplayChanged: console.log(selectedPlayerDisplay)
							id: playerSelector
							x: parent.width / 2 - (selectedPlayerDisplay ? selectedPlayerDisplay.x + selectedPlayerDisplay.width / 2 : 0)
							anchors.verticalCenter: parent.verticalCenter
							width: Math.min(implicitWidth, playerSelectorContainment.width)

							Behavior on x {
								NumberAnimation {
									duration: 400
									easing.type: Easing.OutExpo
								}
							}

							//RowLayout {
								Repeater {
									model: Mpris.players

									MouseArea {
										required property MprisPlayer modelData;
										readonly property bool selected: modelData == player;
										onSelectedChanged: if (selected) playerSelector.selectedPlayerDisplay = this;

										implicitWidth: childrenRect.width
										implicitHeight: childrenRect.height

										onClicked: MprisController.setActivePlayer(modelData);

										Item {
											implicitWidth: 50
											implicitHeight: 50

											Image {
												anchors.fill: parent
												anchors.margins: 5
												source: {
													const entry = DesktopEntries.byId(modelData.desktopEntry);
													console.log(`ent ${entry} id ${modelData.desktopEntry}`)
													return Quickshell.iconPath(entry?.icon);
												}

												sourceSize.width: 50
												sourceSize.height: 50
												cache: false
											}
										}
									}
								//}
							}
						}
					}

					Item {
						Layout.fillWidth: true
						Layout.bottomMargin: 20

						Label {
							anchors.centerIn: parent
							text: root.activePlayer.identity
						}
					}

					SlideView {
						id: trackStack
						Layout.fillWidth: true
						implicitHeight: 400
						clip: animating || (lastFlicked?.contentX ?? 0) != 0

						// inverse of default tooltip margin - 1px for border
						Layout.leftMargin: -4
						Layout.rightMargin: -4

						property Flickable lastFlicked;
						property bool reverse: false;

						Component.onCompleted: updateTrack(false, true);

						function updateTrack(reverse: bool, immediate: bool) {
							this.reverse = reverse;
							this.replace(
								trackComponent,
								{ track: MprisController.activeTrack },
								immediate
							)
						}

						property var trackComponent: Component {
							Flickable {
								id: flickable
								required property var track;
								// in most cases this is ready around the same time as the background,
								// but may take longer if the image is huge.
								readonly property bool svReady: img.status === Image.Ready;
								contentWidth: width + 1
								onDragStarted: trackStack.lastFlicked = this
								onDragEnded: {
									//return;
									console.log(`dragend ${contentX}`)
									if (Math.abs(contentX) > 75) {
										if (contentX < 0) MprisController.previous();
										else if (contentX > 0) MprisController.next();
									}
								}

								ColumnLayout {
									id: trackContent
									width: flickable.width
									height: flickable.height

									Item {
										Layout.fillWidth: true
										implicitHeight: 302//img.implicitHeight
										implicitWidth: img.implicitWidth

										Image {
											id: img;
											anchors.centerIn: parent;
											source: track.artUrl ?? "";
											//height: 300
											//fillMode: Image.PreserveAspectFit
											cache: false
											asynchronous: true

											sourceSize.height: 300
											sourceSize.width: 300

											layer.enabled: true
											layer.effect: OpacityMask {
												cached: true
												maskSource: Rectangle {
													width: img.width
													height: img.height
													radius: 5
												}
											}
										}
									}

									component CenteredText: Item {
										Layout.fillWidth: true

										property alias text: label.text
										property alias font: label.font

										Label {
											id: label
											visible: text != ""
											anchors.centerIn: parent
											elide: Text.ElideRight
											width: Math.min(parent.width - 20, implicitWidth)
										}
									}

									CenteredText {
										Layout.topMargin: 20
										text: track.title
										font.pointSize: albumLabel.font.pointSize + 1
									}

									CenteredText {
										id: albumLabel
										Layout.topMargin: 18
										text: track.album
										opacity: 0.8
									}

									CenteredText {
										Layout.topMargin: 20
										text: track.artist
									}

									Item { Layout.fillHeight: true }
								}
							}
						}

						readonly property real fromPos: trackStack.width * (trackStack.reverse ? -1 : 1);

						// intentionally slightly faster than the background
						enterTransition: PropertyAnimation {
							property: "x"
							from: trackStack.fromPos
							to: 0;
							duration: 350;
							easing.type: Easing.OutExpo;
						}

						exitTransition: PropertyAnimation {
							property: "x"
							to: target.x - trackStack.fromPos;
							duration: 350;
							easing.type: Easing.OutExpo;
						}
					}

					Item { Layout.fillHeight: true }

					Item {
						Layout.fillWidth: true
						implicitHeight: controlsRow.implicitHeight

						RowLayout {
							id: controlsRow
							anchors.centerIn: parent

							ClickableIcon {
								image: {
									switch (MprisController.loopState) {
									case MprisLoopState.None: return "root:icons/repeat-none.svg";
									case MprisLoopState.Playlist: return "root:icons/repeat-all.svg";
									case MprisLoopState.Track: return "root:icons/repeat-once.svg";
									}
								}

								implicitWidth: 50
								implicitHeight: width
								scaleIcon: false
								baseMargin: 3
								enabled: MprisController.loopSupported;
								onClicked: {
									let target = MprisLoopState.None;
									switch (MprisController.loopState) {
									case MprisLoopState.None: target = MprisLoopState.Playlist; break;
									case MprisLoopState.Playlist: target = MprisLoopState.Track; break;
									case MprisLoopState.Track: target = MprisLoopState.None; break;
									}

									MprisController.setLoopState(target);
								}
							}

							ClickableIcon {
								image: "root:icons/rewind.svg"
								implicitWidth: 60
								implicitHeight: width
								scaleIcon: false
								baseMargin: 3
								enabled: MprisController.canGoPrevious;
								onClicked: MprisController.previous();
							}

							ClickableIcon {
								image: `root:icons/${MprisController.isPlaying ? "pause" : "play"}.svg`;
								Layout.leftMargin: -10
								Layout.rightMargin: -10
								implicitWidth: 80
								implicitHeight: width
								scaleIcon: false
								enabled: MprisController.canTogglePlaying;
								onClicked: MprisController.togglePlaying();
							}

							ClickableIcon {
								image: "root:icons/fast-forward.svg"
								implicitWidth: 60
								implicitHeight: width
								scaleIcon: false
								baseMargin: 3
								enabled: MprisController.canGoNext;
								onClicked: MprisController.next();
							}

							ClickableIcon {
								image: `root:icons/${MprisController.hasShuffle ? "shuffle" : "shuffle-off"}.svg`
								implicitWidth: 50
								implicitHeight: width
								scaleIcon: false
								enabled: MprisController.shuffleSupported;
								onClicked: MprisController.setShuffle(!MprisController.hasShuffle);
							}
						}
					}

					RowLayout {
						Layout.margins: 5

						Label {
							Layout.preferredWidth: lengthLabel.implicitWidth
							text: positionInfo.timeStr(positionInfo.position)
						}

						MediaSlider {
							id: slider
							property bool bindSlider: true;

							property real boundAnimStart: 0;
							property real boundAnimFactor: 1;
							property real lastPosition: 0;
							property real lastLength: 0;
							property real boundPosition: {
								const ppos = player.position / player.length;
								const bpos = boundAnimStart;
								return (ppos * boundAnimFactor) + (bpos * (1.0 - boundAnimFactor));
							}

							NumberAnimation {
								id: boundAnim
								target: slider
								property: "boundAnimFactor"
								from: 0
								to: 1
								duration: 600
								easing.type: Easing.OutExpo
							}

							Connections {
								target: player

								function onPositionChanged() {
									if (false && player.position == 0 && slider.lastPosition != 0 && !boundAnim.running) {
										slider.boundAnimStart = slider.lastPosition / slider.lastLength;
										boundAnim.start();
									}

									slider.lastPosition = player.position;
									slider.lastLength = player.length;
								}
							}

							ColorQuantizer {
								id: quant
								rescaleSize: 200
								depth: 0
								source: MprisController.activeTrack.artUrl
								onColorsChanged: console.log(colors)
							}

							grooveColor: quant.colors.length === 0 ? "#30ceffff" : Qt.alpha(quant.colors[0], 0.2)
							barColor: quant.colors.length === 0 ? "#80ceffff" : Qt.alpha(Qt.lighter(quant.colors[0]), 0.5)

							Behavior on grooveColor { ColorAnimation { duration: 200 } }
							Behavior on barColor { ColorAnimation { duration: 200 } }

							Layout.fillWidth: true
							enabled: player.canSeek
							from: 0
							to: 1

							onPressedChanged: {
								if (!pressed) player.position = value * player.length;
								bindSlider = !pressed;
							}

							Binding {
								when: slider.bindSlider
								slider.value: slider.boundPosition
							}
						}

						Label {
							id: lengthLabel
							text: positionInfo.timeStr(positionInfo.length)
						}
					}
				}
			}
		}
	}
}
