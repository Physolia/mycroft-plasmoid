import QtQuick 2.7
import QtQuick.Templates 2.1 as T
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras


T.Switch {
    id: control

    implicitWidth: indicator.implicitWidth
    implicitHeight: switchHandle.implicitHeight
    
    property alias circolour: rectangle.color

    indicator: Rectangle {
        id: switchHandle
        implicitWidth: 6 * 4.8
        implicitHeight: 6 * 2.6
        x: control.leftPadding
        anchors.verticalCenter: parent.verticalCenter
        radius: 6 * 1.3
        color: Qt.darker(theme.textColor, 1.2)
        border.color: theme.backgroundColor

        Rectangle {
            id: rectangle

            width: 6 * 2.6
            height: 6 * 2.6
            radius: 10 * 1.3
            color: Qt.lighter(theme.backgroundColor, 1.5)
            border.color: theme.textColor
        }

        states: [
            State {
                name: "off"
                when: !control.checked && !control.down
            },
            State {
                name: "on"
                when: control.checked && !control.down

                PropertyChanges {
                    target: switchHandle
                    color: Qt.lighter(theme.backgroundColor, 1.5)
                    border.color: theme.textColor
                }

                PropertyChanges {
                    target: rectangle
                    x: parent.width - width

                }
            },
            State {
                name: "off_down"
                when: !control.checked && control.down

                PropertyChanges {
                    target: rectangle
                    color: theme.textColor
                }

            },
            State {
                name: "on_down"
                extend: "off_down"
                when: control.checked && control.down

                PropertyChanges {
                    target: rectangle
                    x: parent.width - width
                    color: theme.textColor
                }

                PropertyChanges {
                    target: switchHandle
                    color: theme.backgroundColor
                    border.color: theme.backgroundColor
                }
            }
        ]
    }
}
