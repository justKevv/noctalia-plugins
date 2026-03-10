import QtQuick 2.15

Item {
    property var pluginApi

    Component.onCompleted: {
        var s = pluginApi.pluginSettings
        if (s.lastResult === undefined){
            s.lastResult = "—"
        } 
        console.log(pluginApi.pluginId + " started, lastResult=", s.lastResult)
    }
}