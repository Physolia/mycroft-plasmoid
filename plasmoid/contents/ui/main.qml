/* Copyright 2016 Aditya Mehra <aix.m@outlook.com>                            

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) version 3, or any
    later version accepted by the membership of KDE e.V. (or its
    successor approved by the membership of KDE e.V.), which shall
    act as a proxy defined in Section 6 of version 3 of the license.
    
    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.
    
    You should have received a copy of the GNU Lesser General Public
    License along with this library.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.9
import QtQml.Models 2.2
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.WebSockets 1.0
import Qt.labs.settings 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.private.mycroftplasmoid 1.0 as PlasmaLa
import org.kde.plasma.private.volume 0.1
import QtWebKit 3.0

Item {
    id: main
    Layout.fillWidth: true;
    Plasmoid.toolTipMainText: i18n("Mycroft")
    Plasmoid.switchWidth: units.gridUnit * 15
    Plasmoid.switchHeight: units.gridUnit * 15
    Layout.minimumHeight: units.gridUnit * 24
    Layout.minimumWidth: units.gridUnit * 26
    
    Component.onCompleted: {
        mycroftStatusCheckSocket.active = true
        refreshAllSkills();
    }
    
    property var skillList: []
    property alias cbwidth: rectangle2.width
    property string defaultmcorestartpath: "/usr/share/plasma/plasmoids/org.kde.plasma.mycroftplasmoid/contents/code/startservice.sh"
    property string defaultmcorestoppath: "/usr/share/plasma/plasmoids/org.kde.plasma.mycroftplasmoid/contents/code/stopservice.sh"
    property string packagemcorestartcmd: "/usr/share/plasma/plasmoids/org.kde.plasma.mycroftplasmoid/contents/code/pkgstartservice.sh"
    property string packagemcorestopcmd: "/usr/share/plasma/plasmoids/org.kde.plasma.mycroftplasmoid/contents/code/pkgstopservice.sh"
    property string customlocstartpath: startsrvcustom.text
    property string customlocstoppath: stopsrvcustom.text
    property string customloc: " "
    property string coreinstallstartpath: defaultmcorestartpath
    property string coreinstallstoppath: defaultmcorestoppath
    property variant searchIndex: []
    property variant results: []
    property var smintent
    property var dataContent
    property alias autoCompModel: completionItems
    property alias textInput: qinput
    
    Connections {
        target: main2
        onSendShowMycroft: {
            plasmoid.expanded = !plasmoid.expanded
            tabBar.currentTab = mycroftTab
        }
        onSendShowSkills: {
            tabBar.currentTab = mycroftSkillsTab
            if(plasmoid.expanded = !plasmoid.expanded){
                plasmoid.expanded
            }
        }
        onSendShowSkillsInstaller: {
            tabBar.currentTab = mycroftMSMinstTab
            if(plasmoid.expanded = !plasmoid.expanded){
                plasmoid.expanded
            }
        }
    }
    
    function toggleInputMethod(selection){
        switch(selection){
        case "KeyboardSetActive":
            qinput.visible = true
            suggestionbottombox.visible = true
            customMicIndicator.visible = false
            keybindic.color = "green"
            break
        case "KeyboardSetDisable":
            qinput.visible = false
            suggestionbottombox.visible = false
            customMicIndicator.visible = true
            keybindic.color = theme.textColor
            break
        }
   }
    
    function retryConn(){
        socket.active = true
        if (socket.active = false){
                console.log(socket.errorString)
        }
    }
    
    function filterSpeak(msg){
        convoLmodel.append({
            "itemType": "NonVisual",
            "InputQuery": msg
        })
           inputlistView.positionViewAtEnd();
    }
    
    function filterincoming(intent, metadata) {
        var intentVisualArray = ['CurrentWeatherIntent'];
        var itemType
        var filterintentname = intent.split(':');
        var intentname = filterintentname[1];

        if (intentVisualArray.indexOf(intentname) !== -1) {
                switch (intentname){
                case "CurrentWeatherIntent":
                    itemType = "CurrentWeather"
                    break;
                }

              convoLmodel.append({"itemType": itemType, "itemData": metadata})
                }

        else {
            convoLmodel.append({"itemType": "WebViewType", "InputQuery": metadata.url})
        }
    }
    
    function filtervisualObj(metadata){
                convoLmodel.append({"itemType": "LoaderType", "InputQuery": metadata.url})
                inputlistView.positionViewAtEnd();
          }

    
    function isBottomEdge() {
        return plasmoid.location == PlasmaCore.Types.BottomEdge;
    }
    
    function clearList() {
            inputlistView.clear()
        }
    
    function muteMicrophone() {
        if (!sourceModel.defaultSource) {
            return;
        }
        var toMute = !sourceModel.defaultSource.muted;
        sourceModel.defaultSource.muted = toMute;
    }
    
    
    function refreshAllSkills(){
        getSkills();
        msmskillsModel.reload();
    }
    
    function getAllSkills(){
        if(skillList.length <= 0){
            getSkills();
        }
        return skillList;
    }
    function getSkillByName(skillName){
        var tempSN=[];
        for(var i = 0; i <skillList.length;i++){
            var sList = skillList[i].name;
            if(sList.indexOf(skillName) !== -1){
                tempSN.push(skillList[i]);
            }
        }
        return tempSN;
    }
    function getSkills() {
      var doc = new XMLHttpRequest()
      var url = "https://raw.githubusercontent.com/MycroftAI/mycroft-skills/master/.gitmodules"
      doc.open("GET", url, true);
      doc.send();

      doc.onreadystatechange = function() {
        if (doc.readyState === XMLHttpRequest.DONE) {
          var path, list;
          var tempRes = doc.responseText
          var moduleList = tempRes.split("[");
          for (var i = 1; i < moduleList.length; i++) {
            path = moduleList[i].substring(moduleList[i].indexOf("= ") + 2, moduleList[i].indexOf("url")).replace(/^\s+|\s+$/g, '');
            url = moduleList[i].substring(moduleList[i].search("url =") + 6).replace(/^\s+|\s+$/g, '');
            skillList[i-1] = {"name": path, "url": url};
            msmskillsModel.reload();
          }
        }
      }
    }
    
    function getFileExtenion(filePath){
           var ext = filePath.split('.').pop();
           return ext;
    }

    function validateFileExtension(filePath) {
                  var ext = filePath.split('.').pop();
                  return ext === "jpg" || ext === "png" || ext === "jpeg" || ext === 'mp3' || ext === 'wav' || ext === 'mp4'
    }
        
    function readFile(filename) {
        if (PlasmaLa.FileReader.file_exists_local(filename)) {
            try {
                var content = PlasmaLa.FileReader.read(filename).toString("utf-8");
                return content;
            } catch (e) {
                return 0;
            }
        } else {
            return 0;
        }
    }
    
       function playwaitanim(recoginit){
       switch(recoginit){ //"mycroft.skill.handler.start":
       case "recognizer_loop:record_begin":
               drawer.open()
               waitanimoutter.cstanim.visible = true
               waitanimoutter.cstanim.running = true
               break
           case "recognizer_loop:audio_output_start":
               drawer.close()
               waitanimoutter.cstanim.visible = false
               waitanimoutter.cstanim.running = false
               break
           case "mycroft.skill.handler.complete":
               drawer.close()
               waitanimoutter.cstanim.running = false
               break
       }
   }
   
       function autoAppend(model, getinputstring, setinputstring) {
        for(var i = 0; i < model.count; ++i)
            if (getinputstring(model.get(i))){
                console.log(model.get(i))
                    return true
                }
              return null
            }

    function evalAutoLogic() {
        if (suggestionsBox.currentIndex === -1) {
        } else {
            suggestionsBox.complete(suggestionsBox.currentItem)
        }
    }

Timer {
           id: timer
       }

       function delay(delayTime, cb) {
               timer.interval = delayTime;
               timer.repeat = false;
               timer.triggered.connect(cb);
               timer.start();
}
    
Item {
 id: topBar
 Layout.fillWidth: true
 height: units.gridUnit * 2
 z: 101
 anchors {
    top: main.top
    topMargin: -1
    left: main.left
    leftMargin: -1
    right: main.right
    rightMargin: -1
    }
    
        
Item {
    id: topBarBGrect
    anchors.fill: parent
    z: 101
         
Image {
        id: barAnim
        anchors.left: parent.left
        anchors.leftMargin: units.gridUnit * 0.1
        anchors.verticalCenter: parent.verticalCenter
        source: "../images/mycroftsmaller.png"
        width: units.gridUnit * 1.6
        height: units.gridUnit * 1.6
    }
    
    PlasmaCore.SvgItem {
        id: topbarLeftDividerline
        anchors {
            left: barAnim.right
            leftMargin: units.gridUnit * 0.34
            top: parent.top
            topMargin: 0
            bottom: parent.bottom
            bottomMargin: 0
        }

        width: linetopleftvertSvg.elementSize("vertical-line").width
        z: 110
        elementId: "vertical-line"

        svg: PlasmaCore.Svg {
            id: linetopleftvertSvg;
            imagePath: "widgets/line"
        }
    }  


    PlasmaComponents.Label {
                anchors.top: parent.top
                anchors.topMargin: 4
                anchors.left: topbarLeftDividerline.right
                anchors.leftMargin: 2
                id: statusId
                text: i18n("Mycroft is disabled")
                font.bold: false;
                font.pixelSize: 14
                color: "#fff"
    }
    
TopBarAnim {
    id: midbarAnim
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: statusId.left
    anchors.right:  topbarDividerline.left
    height: units.gridUnit * 4
    z: 6
}    
    
    PlasmaCore.SvgItem {
        id: topbarDividerline
        anchors {
            right: mycroftstartservicebutton.left
            rightMargin: units.gridUnit * 0.25
            top: parent.top
            topMargin: 0
            bottom: parent.bottom
            bottomMargin: 0
        }

        width: linetopvertSvg.elementSize("vertical-line").width
        z: 110
        elementId: "vertical-line"

        svg: PlasmaCore.Svg {
            id: linetopvertSvg;
            imagePath: "widgets/line"
        }
    }   
    
    
        SwitchButton {
                anchors.right: qinputmicbx.left
                anchors.verticalCenter: topBarBGrect.verticalCenter
                id: mycroftstartservicebutton
                checked: false
                width: Math.round(units.gridUnit * 2)
                height: width
                z: 102
                
                onClicked: {
                    if (mycroftstartservicebutton.checked === false) {
                        PlasmaLa.LaunchApp.runCommand("bash", coreinstallstoppath);
                        convoLmodel.clear()
                        suggst.visible = true;
                        socket.active = false;
                        midbarAnim.showstatsId()
                    }
                    
                    if (mycroftstartservicebutton.checked === true) {
                        disclaimbox.visible = false;
                        PlasmaLa.LaunchApp.runCommand("bash", coreinstallstartpath);
                        convoLmodel.clear()
                        suggst.visible = true;
                        delay(15000, function() {
                        socket.active = true;
                        })
                    }

                }
                
                }
                
        PlasmaComponents.ToolButton {
                id: qinputmicbx
                anchors.right: pinButton.left
                anchors.verticalCenter: parent.verticalCenter
                iconSource: "mic-on"
                tooltip: i18n("Toggle Mic")
                flat: true
                width: Math.round(units.gridUnit * 2)
                height: width
                z: 102
    
                onClicked: {
                    if (qinputmicbx.iconSource == "mic-on") {
                        qinputmicbx.iconSource = "mic-off"
                    }
                    else if (qinputmicbx.iconSource == "mic-off") {
                        qinputmicbx.iconSource = "mic-on"
                    }
                    muteMicrophone()
                }    
                }
    
    
    
    PlasmaComponents.ToolButton {
        id: pinButton
        anchors.right: parent.right
        anchors.verticalCenter: topBarBGrect.verticalCenter
        width: Math.round(units.gridUnit * 1.5)
        height: width
        checkable: true
        iconSource: "window-pin"
        onCheckedChanged: plasmoid.hideOnWindowDeactivate = !checked
        z: 102
    }
    
    }    
}

PlasmaCore.SvgItem {
        anchors {
            left: main.left
            right: main.right
            top: root.top
        }
        width: 1
        height: horlinetopbarSvg.elementSize("horizontal-line").height

        elementId: "horizontal-line"
        z: 110
        svg: PlasmaCore.Svg {
            id: horlinetopbarSvg;
            imagePath: "widgets/line"
        }
}  
    
Item {
        id: root                
        anchors { 
        top: topBar.bottom
        bottom: rectanglebottombar.top
        left: parent.left
        right: parent.right
        }
        
    WebSocket {
        id: mycroftStatusCheckSocket
        url: innerset.wsurl
        active: true
        onStatusChanged: 
            if (mycroftStatusCheckSocket.status == WebSocket.Open && socket.status == WebSocket.Closed) {
            console.log("Activated")
            socket.active = true
            disclaimbox.visible = false;
            mycroftstartservicebutton.checked = true
            statusId.text = i18n("Mycroft is Ready")
            statusId.color = "green"
            statusId.visible = true
            }

            else if (mycroftStatusCheckSocket.status == WebSocket.Error) {
            mycroftstartservicebutton.checked = false
            statusId.text = i18n("Mycroft is Disabled")
            statusId.color = "#f4bf42"
            statusId.visible = true
            }
        }
        
    WebSocket {
        id: socket
        url: innerset.wsurl
        onTextMessageReceived: {
            var somestring = JSON.parse(message)
            var msgType = somestring.type;
            playwaitanim(msgType);
            qinput.focus = false;
            
            if (msgType === "recognizer_loop:utterance") {
                var intpost = somestring.data.utterances;
                qinput.text = intpost.toString()
                convoLmodel.append({"itemType": "AskType", "InputQuery": intpost.toString()})
                midbarAnim.wsistalking()
            }
            
            if (somestring && somestring.data && typeof somestring.data.intent_type !== 'undefined'){
                smintent = somestring.data.intent_type;
            }
            
            if(somestring && somestring.data && typeof somestring.data.utterance !== 'undefined' && somestring.type === 'speak'){
                filterSpeak(somestring.data.utterance);
            }

            if(somestring && somestring.data && typeof somestring.data.desktop !== 'undefined' && somestring.type === "data") {
                dataContent = somestring.data.desktop
                filterincoming(smintent, dataContent)
            }

            if(somestring && somestring.data && typeof somestring.data.desktop !== 'undefined' && somestring.type === "visualObject") {
                dataContent = somestring.data.desktop
                filtervisualObj(dataContent)
            }            
            
            if (msgType === "speak" && !plasmoid.expanded && notificationswitch.checked == true) {
                var post = somestring.data.utterance;
                var title = "Mycroft's Reply:"
                var notiftext = " "+ post;
                PlasmaLa.Notify.mycroftResponse(title, notiftext);
            }
            
             midbarAnim.wsistalking()
        }
                
        onStatusChanged: if (socket.status == WebSocket.Error) {
                                statusId.text = "Connection Error"
                                statusId.color = "red"
                                mycroftstartservicebutton.circolour = "red"
                                retryConn()
                                midbarAnim.showstatsId()
                         } else if (socket.status == WebSocket.Open) {
                                statusId.text = "Mycroft is Ready"
                                statusId.color = "green"
                                mycroftstartservicebutton.circolour = "green"
                                mycroftStatusCheckSocket.active = false;
                                midbarAnim.showstatsId()
                         } else if (socket.status == WebSocket.Closed) {
                                statusId.text = "Mycroft is Disabled"
                                statusId.color = "#f4bf42"
                                mycroftstartservicebutton.circolour = Qt.lighter(theme.backgroundColor, 1.5)
                                midbarAnim.showstatsId()
                         } else if (socket.status == WebSocket.Connecting) {
                                statusId.text = "Starting Up"
                                statusId.color = "grey"
                                mycroftstartservicebutton.circolour = "steelblue"
                                midbarAnim.showstatsId()
                         } else if (socket.status == WebSocket.Closing) {
                                statusId.text = "Shutting Down"
                                statusId.color = "grey"
                                midbarAnim.showstatsId()
                         }
    }    
        
    ColumnLayout {
    id: sidebar
    height: units.gridUnit * 6
    width: units.gridUnit * 2
    
    PlasmaComponents.TabBar {
        id: tabBar
        anchors.fill: parent
        tabPosition: Qt.LeftEdge;
        
            PlasmaComponents.TabButton {
                id: mycroftTab
                Layout.fillHeight: true
                Layout.fillWidth: true
                iconSource: "user-home"
                
                    PlasmaCore.ToolTipArea {
                        id: tooltiptab1
                        mainText: i18n("Home Tab")
                        anchors.fill: parent
                        }
                
                }
                  
            PlasmaComponents.TabButton {
                id: mycroftSkillsTab
                Layout.fillHeight: true
                Layout.fillWidth: true
                iconSource: "games-hint"
                
                    PlasmaCore.ToolTipArea {
                        id: tooltiptab2
                        mainText: i18n("Skills Tab")
                        anchors.fill: parent
                        }
                
                }
                
            PlasmaComponents.TabButton {
                id: mycroftSettingsTab
                Layout.fillHeight: true
                Layout.fillWidth: true
                iconSource: "games-config-options"
                
                    PlasmaCore.ToolTipArea {
                        id: tooltiptab3
                        mainText: i18n("Settings Tab")
                        anchors.fill: parent
                        }
                
                }
                
            PlasmaComponents.TabButton {
                id: mycroftMSMinstTab
                Layout.fillHeight: true
                Layout.fillWidth: true
                iconSource: "kmouth-phresebook-new"
                
                
                    PlasmaCore.ToolTipArea {
                        id: tooltiptab4
                        mainText: i18n("Skill Installs Tab")
                        anchors.fill: parent
                        }
                
                }  
                
            }
    }

    PlasmaCore.SvgItem {
        anchors {
            left: parent.left
            leftMargin: sidebar.width
            top: parent.top
            topMargin: 1
            bottom: parent.bottom
            bottomMargin: 1
        }

        width: lineSvg.elementSize("vertical-line").width
        z: 110
        elementId: "vertical-line"

        svg: PlasmaCore.Svg {
            id: lineSvg;
            imagePath: "widgets/line"
        }
    }        
                
    ColumnLayout {
    id: mycroftcolumntab    
    visible: tabBar.currentTab == mycroftTab;
    anchors.top: root.top
    anchors.left: sidebar.right
    anchors.leftMargin: units.gridUnit * 0.25
    anchors.right: root.right
    anchors.bottom: root.bottom

    Rectangle {
                    id: rectangle2
                    color: "#00000000"
                    anchors.top: mycroftcolumntab.top
                    anchors.topMargin:15
                    anchors.left: mycroftcolumntab.left
                    anchors.right: mycroftcolumntab.right
                    anchors.bottom: mycroftcolumntab.bottom
                
    DropArea {           
        anchors.fill: parent;
        id: dragTarget
        onEntered: {
            for(var i = 0; i < drag.urls.length; i++)
                if(validateFileExtension(drag.urls[i]))
                return
                console.log("No valid files, refusing drag event")
                drag.accept()
                dragTarget.enabled = false
        }
        
        onDropped: {
            for(var i = 0; i < drop.urls.length; i++){
            var ext = getFileExtenion(drop.urls[i]);
            if(ext === "jpg" || ext === "png" || ext === "jpeg"){
            var durl = String(drop.urls[i]);
            convoLmodel.append({
                "itemType": "DropImg",
                "InputQuery": durl
                })
                inputlistView.positionViewAtEnd();


            var irecogmsgsend = innerset.customrecog
            var socketmessage = {};
            socketmessage.type = "recognizer_loop:utterance";
            socketmessage.data = {};
            socketmessage.data.utterances = [irecogmsgsend + " " + durl];
            socket.sendTextMessage(JSON.stringify(socketmessage));
                }
            
            if(ext === 'mp3'){
                console.log('mp3');
                }
            }
        }
        
        
        Disclaimer{
            id: disclaimbox
            visible: true
            }
        
        ListModel{
        id: convoLmodel
        }

            Rectangle {
                id: messageBox
                anchors.fill: parent
                anchors.right: parent.right
                anchors.left: parent.left
                color: "#00000000"

                ColumnLayout {
                    id: colconvo
                    anchors.fill: parent

                ListView {
                    id: inputlistView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalLayoutDirection: ListView.TopToBottom
                    spacing: 12
                    clip: true
                    model: convoLmodel
                    ScrollBar.vertical: ScrollBar {}
                    delegate:  Component {
                            Loader {
                                source: switch(itemType) {
                                        case "NonVisual": return "SimpleMessageType.qml"
                                        case "WebViewType": return "WebViewType.qml"
                                        case "CurrentWeather": return "CurrentWeatherType.qml"
                                        case "DropImg" : return "ImgRecogType.qml"
                                        case "AskType" : return "AskMessageType.qml"
                                        case "LoaderType" : return "LoaderType.qml"
                                        }
                                    property var metacontent : dataContent
                                }
                        }

                onCountChanged: {
                    inputlistView.positionViewAtEnd();
                                }
                                    }
                                        }
                                            }
                                                }
                                                    }
                                                        }
                                                    
    ColumnLayout {
    id: mycroftSkillscolumntab    
    visible: tabBar.currentTab == mycroftSkillsTab;
    anchors.top: root.top
    anchors.left: sidebar.right
    anchors.leftMargin: units.gridUnit * 0.25
    anchors.right: root.right
    anchors.bottom: root.bottom

                ListView {
                    id: skillslistmodelview
                    anchors.top: parent.top
                    anchors.topMargin: 5
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    model: SkillModel{}
                    delegate: SkillView{}
                    spacing: 4
                    focus: false
                    interactive: true
                    clip: true;
                }

        }

    ColumnLayout {
    id: mycroftSettingsColumn
    visible: tabBar.currentTab == mycroftSettingsTab;
    anchors.top: root.top
    anchors.left: sidebar.right
    anchors.leftMargin: units.gridUnit * 0.25
    anchors.right: root.right
    anchors.bottom: root.bottom

    Item {
                    id: settingscontent
                    Layout.fillWidth: true;
                    Layout.fillHeight: true;
                    anchors.fill: parent;

    Flickable {
        id: settingFlick
        anchors.fill: parent;
        contentWidth: mycroftSettingsColumn.width
        contentHeight: units.gridUnit * 22
        clip: true;
        
                PlasmaComponents.Label {
                    id: settingsTabUnits
                    anchors.top: parent.top;
                    anchors.topMargin: 5
                    text: i18n("<i>Your Mycroft Core Installation Path</i>")
                    }
                    
                PlasmaComponents.ButtonColumn {
                    id: radiobuttonColoumn
                    anchors.top: settingsTabUnits.bottom
                    anchors.topMargin: 5
                    
                    PlasmaComponents.RadioButton {
                        id: settingsTabUnitsOpZero
                        exclusiveGroup: installPathGroup
                        text: i18n("Default Path")
                        checked: true
                        
                        onCheckedChanged: {
                            
                            if (settingsTabUnitsOpZero.checked === true && coreinstallstartpath === packagemcorestartcmd) {
                                coreinstallstartpath = defaultmcorestartpath;
                            }
                            else if (settingsTabUnitsOpZero.checked === true && coreinstallstartpath === customlocstartpath) {
                                coreinstallstartpath = defaultmcorestartpath;   
                            }
                            
                            if (settingsTabUnitsOpZero.checked === true && coreinstallstoppath === packagemcorestopcmd) {
                                coreinstallstoppath = defaultmcorestoppath;
                            }
                            
                            else if (settingsTabUnitsOpZero.checked === true && coreinstallstoppath === customlocstoppath) {
                                coreinstallstoppath = defaultmcorestoppath;   
                            }
                        }
                    }
                    
                    PlasmaComponents.RadioButton {
                        id: settingsTabUnitsOpOne
                        exclusiveGroup: installPathGroup
                        text: i18n("Installed Using Mycroft Package")
                        checked: false
                        
                        onCheckedChanged: {
                            
                            if (settingsTabUnitsOpOne.checked === true && coreinstallstartpath === defaultmcorestartpath) {
                                coreinstallstartpath = packagemcorestartcmd;
                            }
                            else if (settingsTabUnitsOpOne.checked === true && coreinstallstartpath === customlocstartpath) {
                                coreinstallstartpath = packagemcorestartcmd;   
                            }
                            
                            if (settingsTabUnitsOpOne.checked === true && coreinstallstoppath === defaultmcorestoppath) {
                                coreinstallstoppath = packagemcorestopcmd;
                            }
                            
                            else if (settingsTabUnitsOpOne.checked === true && coreinstallstoppath === customlocstoppath) {
                                coreinstallstoppath = packagemcorestopcmd;   
                            }
                        }
                    }
                    
                    PlasmaComponents.RadioButton {
                        id: settingsTabUnitsOpTwo
                        exclusiveGroup: installPathGroup
                        text: i18n("Location of Mycroft-Core Directory")
                        checked: false
                        
                        onCheckedChanged: {
                            
                            if (settingsTabUnitsOpTwo.checked === true && coreinstallstartpath === defaultmcorestartpath) {
                                coreinstallstartpath = customlocstartpath;
                            }
                            else if (settingsTabUnitsOpTwo.checked === true && coreinstallstartpath === packagemcorestartcmd) {
                                coreinstallstartpath = customlocstartpath;   
                            }
                            
                            if (settingsTabUnitsOpTwo.checked === true && coreinstallstoppath === defaultmcorestoppath) {
                                coreinstallstoppath = customlocstoppath;
                            }
                            
                            else if (settingsTabUnitsOpTwo.checked === true && coreinstallstoppath === packagemcorestopcmd) {
                                coreinstallstoppath = customlocstoppath;   
                            }
                            
                        }
                    } 
                        }
                    
                    PlasmaComponents.TextField {
                        id: settingsTabUnitsOpThree
                        width: settingscontent.width / 1.1
                        anchors.top: radiobuttonColoumn.bottom
                        anchors.topMargin: 10
                        placeholderText: i18n("<custom location>/mycroft-core/")
                        
                        onTextChanged: {
                            var cstloc = settingsTabUnitsOpThree.text
                            customloc = cstloc
                        }
                    }
                    
                PlasmaComponents.Button {
                    id: acceptcustomPath
                    anchors.left: settingsTabUnitsOpThree.right
                    anchors.verticalCenter: settingsTabUnitsOpThree.verticalCenter
                    anchors.right: parent.right
                    iconSource: "checkbox"
                    
                    onClicked: {
                        var cstlocl = customloc
                        var ctstart = cstlocl + "start-mycroft.sh all" 
                        var ctstop = cstlocl + "stop-mycroft.sh" 
                            startsrvcustom.text = ctstart
                            stopsrvcustom.text = ctstop
                            console.log(startsrvcustom.text)                    
                        }
                    } 
                    
                PlasmaComponents.TextField {
                        id: settingsTabUnitsWSpath
                        width: settingscontent.width / 1.1
                        anchors.top: settingsTabUnitsOpThree.bottom
                        anchors.topMargin: 10
                        placeholderText: i18n("ws://0.0.0.0:8181/core")
                        text: i18n("ws://0.0.0.0:8181/core")
                    }
                    
                PlasmaComponents.Button {
                    id: acceptcustomWSPath
                    anchors.left: settingsTabUnitsWSpath.right
                    anchors.verticalCenter: settingsTabUnitsWSpath.verticalCenter
                    anchors.right: parent.right
                    iconSource: "checkbox"
                    
                    onClicked: { 
                        innerset.wsurl = settingsTabUnitsWSpath.text
                        }
                    }
                    
                                
                PlasmaComponents.TextField {
                        id: settingsTabUnitsIRCmd
                        width: settingscontent.width / 1.1
                        anchors.top: settingsTabUnitsWSpath.bottom
                        anchors.topMargin: 10
                        placeholderText: i18n("Your Custom Image Recognition Skill Voc Keywords")
                        text: i18n("search image url")
                    }
                    
                PlasmaComponents.Button {
                    id: acceptcustomIRCmd
                    anchors.left: settingsTabUnitsIRCmd.right
                    anchors.verticalCenter: settingsTabUnitsIRCmd.verticalCenter
                    anchors.right: parent.right
                    iconSource: "checkbox"
                }    
                    
                    
                PlasmaComponents.Switch {
                        id: notificationswitch
                        anchors.top: settingsTabUnitsIRCmd.bottom
                        anchors.topMargin: 10
                        text: i18n("Enable Notifications")
                        checked: true
                    }
                    
                    
                PlasmaExtras.Paragraph {
                        id: settingsTabTF2
                        anchors.top: notificationswitch.bottom
                        anchors.topMargin: 15
                        text: i18n("<i>Please Note: Default path is set to /home/$USER/mycroft-core/. Change the above settings to match your installation</i>")
                    }
                    
                PlasmaComponents.Label {
                    id: startsrvcustom
                    visible: false
                }
                
                PlasmaComponents.Label {
                    id: stopsrvcustom
                    visible: false
                }   
            }
        }
    }

    ColumnLayout {
    id: mycroftMsmColumn
    visible: tabBar.currentTab == mycroftMSMinstTab;
    anchors.top: root.top
    anchors.left: sidebar.right
    anchors.leftMargin: units.gridUnit * 0.25
    anchors.right: root.right
    anchors.bottom: root.bottom
            
            Item { 
                id: msmtabtopbar
                width: parent.width
                anchors.left: parent.left
                anchors.right: parent.right
                height: units.gridUnit * 2
                
                PlasmaComponents.TextField {
                id: msmsearchfld
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: getskillsbx.left
                placeholderText: i18n("Search Skills")
                clearButtonShown: true
                
                onTextChanged: {
                if(text.length > 0 ) {
                    msmskillsModel.applyFilter(text.toLowerCase());
                } else {
                    msmskillsModel.reload();
                }
            }
        }    
            
            PlasmaComponents.ToolButton {
                    id: getskillsbx
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    iconSource: "view-refresh"
                    tooltip: i18n("Refresh List")
                    flat: true
                    width: Math.round(units.gridUnit * 2)
                    height: width
                    z: 102
        
                    onClicked: {
                            msmskillsModel.clear();
                            refreshAllSkills();
                        }    
                    }
            }
            
            ListModel {
                id: msmskillsModel
                
                Component.onCompleted: {
                    reload();
                }
                
                function reload() {
                    var skList = getAllSkills();
                    msmskillsModel.clear();
                    for( var i=0; i < skList.length ; ++i ) {
                        msmskillsModel.append(skList[i]);
                    }
                }

                function applyFilter(skName) {
                    var skList = getSkillByName(skName);
                    msmskillsModel.clear();
                    for( var i=0; i < skList.length ; ++i ) {
                        msmskillsModel.append(skList[i]);
                    }
                }
            }
            
            ListView {
                id: msmlistView    
                anchors.top: msmtabtopbar.bottom
                anchors.topMargin: 5
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                model: msmskillsModel
                delegate: MsmView{}
                spacing: 4
                focus: false
                interactive: true
                clip: true;
                    
                }
        }
}

SourceModel {
        id: sourceModel
                }
                
    PlasmaCore.SvgItem {
        anchors {
            left: main.left
            right: main.right
            bottom: root.bottom
        }
        width: 1
        height: horlineSvg.elementSize("horizontal-line").height

        elementId: "horizontal-line"
                z: 110
        svg: PlasmaCore.Svg {
            id: horlineSvg;
            imagePath: "widgets/line"
        }
    }        
                       
                
Item {
    id: rectanglebottombar
    height: units.gridUnit * 3.5
    anchors.left: main.left
    anchors.right: main.right
    anchors.bottom: main.bottom
    z: 110
    
    ListModel {
        id: completionItems
    }
    
    Drawer {
         id: drawer
          width: parent.width
          height: units.gridUnit * 4
          edge: Qt.BottomEdge
 
          Rectangle {
            color: theme.backgroundColor
            anchors.fill: parent
          }

     CustomIndicator {
              id: waitanimoutter
              height: 70
              width: 70
              anchors.verticalCenter: parent.verticalCenter
              anchors.horizontalCenter: parent.horizontalCenter
                  }
          }
    
    Rectangle {
        id: suggestionbottombox
        anchors.top: parent.top
        anchors.bottom: qinput.top
        anchors.right: parent.right
        anchors.left: parent.left
        color: theme.backgroundColor
            
        Suggestions {
            id: suggst
            visible: true;
        }
    }
    
        Rectangle {
        id: keyboardactivaterect
        color: theme.backgroundColor
        border.width: 1
        border.color: Qt.lighter(theme.backgroundColor, 1.2)
        width: units.gridUnit * 2
        height: qinput.height
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        PlasmaComponents.ToolButton {
            id: keybdImg
            iconSource: "input-keyboard"
            anchors.centerIn: parent
            width: units.gridUnit * 2
            height: units.gridUnit * 2
        }

        Rectangle {
            id: keybindic
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            height: 2
            color: "green"
        }

        MouseArea{
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {}
            onExited: {}
            onClicked: {
                if(qinput.visible === false){
                    toggleInputMethod("KeyboardSetActive")
                    }
                else if(qinput.visible === true){
                    toggleInputMethod("KeyboardSetDisable")
                    }
                }
            }
        }
    
    PlasmaComponents.TextField {
        id: qinput
        anchors.left: keyboardactivaterect.right
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        placeholderText: i18n("Enter Query or Say 'Hey Mycroft'")
        clearButtonShown: true
        
        onAccepted: {
            var doesExist = autoAppend(autoCompModel, function(item) { return item.name === qinput.text }, qinput.text)
            var evaluateExist = doesExist
            if(evaluateExist === null){
                        autoCompModel.append({"name": qinput.text});
            }
            suggst.visible = true;
            var socketmessage = {};
            socketmessage.type = "recognizer_loop:utterance";
            socketmessage.data = {};
            socketmessage.data.utterances = [qinput.text];
            socket.sendTextMessage(JSON.stringify(socketmessage));
            qinput.text = ""; 
            }
        
        onTextChanged: {
            evalAutoLogic();
        }
    }
    
    CustomMicIndicator {
        id: customMicIndicator
        anchors.centerIn: parent
        visible: false
    }
    
    AutocompleteBox {
        id: suggestionsBox
        model: completionItems
        width: qinput.width
        anchors.bottom: qinput.top
        anchors.left: qinput.left
        anchors.right: qinput.right
        filter: textInput.text
        property: "name"
        onItemSelected: complete(item)

        function complete(item) {
            if (item !== undefined)
                textInput.text = item.name
            }
    }
}

    Settings {
            id: innerset
            property alias wsurl: settingsTabUnitsWSpath.text
            property alias customrecog: settingsTabUnitsIRCmd.text
            property alias customsetuppath: settingsTabUnitsOpThree.text
            property alias notifybool: notificationswitch.checked
            property alias radiobt1: settingsTabUnitsOpOne.checked
            property alias radiobt2: settingsTabUnitsOpTwo.checked
            property alias radiobt3: settingsTabUnitsOpZero.checked
    }
}
