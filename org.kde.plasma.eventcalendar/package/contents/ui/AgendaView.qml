import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.calendar 2.0 as PlasmaCalendar
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

import "shared.js" as Shared
import "debugfixtures.js" as DebugFixtures

Item {
    id: agendaView

    //anchors.margins: units.largeSpacing
    property int spacing: units.largeSpacing
    property alias agendaListView: agenda

    property int showNextNumDays: 14
    property bool clipPastEvents: false
    property bool clipPastEventsToday: false
    property bool clipEventsOutsideLimits: true
    property bool clipEventsFromOtherMonths: true
    property date visibleDateMin: new Date()
    property date visibleDateMax: new Date()
    property date currentMonth: new Date()

    property bool cfg_clock_24h: false
    property bool cfg_agenda_weather_show_icon: false
    property int cfg_agenda_weather_icon_height: 24
    property bool cfg_agenda_weather_show_text: false
    property bool cfg_agenda_breakup_multiday_events: true

    signal newEventFormOpened(variant agendaItem, variant newEventCalendarId)
    signal submitNewEventForm(variant calendarId, variant date, string text)

    ListModel {
        id: agendaModel
    }

    width: 400
    height: 400

    // Testing with qmlview
    Rectangle {
        visible: typeof popup === 'undefined'
        color: PlasmaCore.ColorScope.backgroundColor
        anchors.fill: parent
    }
    
    ListView {
        id: agenda
        model: agendaModel
        anchors.fill: parent
        clip: true
        spacing: 10
        boundsBehavior: Flickable.StopAtBounds

        // Don't bother garbage collecting
        // GC or Reloading the weather images is very slow.
        cacheBuffer: 10000000 

        delegate: RowLayout {
            Layout.fillWidth: true
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 10
            property date agendaItemDate: model.date

            LinkRect {
                Layout.alignment: Qt.AlignTop

                Column {
                    id: itemWeatherColumn
                    width: 50
                    Layout.alignment: Qt.AlignTop

                    FontIcon {
                        visible: showWeather && cfg_agenda_weather_show_icon
                        source: weatherIcon
                        height: cfg_agenda_weather_icon_height
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                    }

                    Text {
                        id: itemWeatherText
                        visible: showWeather && cfg_agenda_weather_show_text
                        text: weatherText
                        color: PlasmaCore.ColorScope.textColor
                        opacity: 0.75
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        id: itemWeatherTemps
                        visible: showWeather
                        text: tempHigh + '° | ' + tempLow + '°'
                        color: PlasmaCore.ColorScope.textColor
                        opacity: 0.75
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        horizontalAlignment: paintedWidth > parent.width ? Text.AlignLeft  : Text.AlignHCenter
                    }
                }

                tooltipMainText: weatherDescription
                tooltipSubText: {
                    var lines = [];
                    lines.push('<b>Morning:</b> ' + weatherTempMorn + '°');
                    lines.push('<b>Day:</b> ' + weatherTempDay + '°');
                    lines.push('<b>Evening:</b> ' + weatherTempEve + '°');
                    lines.push('<b>Night:</b> ' + weatherTempNight + '°');
                    return lines.join('<br>');
                }

                onClicked: {
                    console.log('agendaItem.date.clicked', date)
                    if (true) {
                        // cfg_agenda_weather_clicked == "browser_viewcityforecast"
                        if (config.weather_city_id) {
                            Shared.openOpenWeatherMapCityUrl(config.weather_city_id);
                        }
                    }
                }
            }

            LinkRect {
                Layout.alignment: Qt.AlignTop

                Column {
                    id: itemDateColumn
                    width: 50

                    Text {
                        id: itemDate
                        text: Qt.formatDateTime(date, "MMM d")
                        color: PlasmaCore.ColorScope.textColor
                        opacity: 0.75
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        horizontalAlignment: Text.AlignRight

                        // MouseArea {
                        //     anchors.fill: itemDateColumn
                        //     onClicked: {
                        //         newEventInput.forceActiveFocus()
                        //     }
                        // }
                    }

                    Text {
                        id: itemDay
                        text: Qt.formatDateTime(date, "ddd")
                        color: PlasmaCore.ColorScope.textColor
                        opacity: 0.5
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        horizontalAlignment: Text.AlignRight
                    }
                }

                onClicked: {
                    console.log('agendaItem.date.clicked', date)
                    if (false) {
                        // cfg_agenda_date_clicked == "browser_newevent"
                        Shared.openGoogleCalendarNewEventUrl(date);
                    } else if (true) {
                        // cfg_agenda_date_clicked == "agenda_newevent"
                        newEventForm.visible = !newEventForm.visible
                    }
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                spacing: 0
                Item {
                    Layout.fillWidth: true
                }


                ColumnLayout {
                    id: newEventForm
                    visible: false
                    onVisibleChanged: {
                        if (visible) {
                            newEventText.forceActiveFocus()
                            newEventFormOpened(model, newEventCalendarId)
                        }
                    }
                    PlasmaComponents.ComboBox {
                        id: newEventCalendarId
                        Layout.fillWidth: true
                        model: ['asdf']
                    }

                    RowLayout {
                        PlasmaComponents.TextField {
                            id: newEventText
                            Layout.fillWidth: true
                            placeholderText: "Eg: 9am-5pm Work"
                            onAccepted: {
                                var calendarId = newEventCalendarId.model[newEventCalendarId.currentIndex]
                                submitNewEventForm(calendarId, date, text)
                                text = ''
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        height: 10
                    }
                }

                ColumnLayout {
                    spacing: 10
                    Layout.fillWidth: true

                    Repeater {
                        model: events

                        // delegate: Rectangle {
                        delegate: LinkRect {
                            width: undefined
                            Layout.fillWidth: true
                            height: eventColumn.height

                            RowLayout {
                                Rectangle {
                                    width: 2
                                    height: eventColumn.height
                                    color: model.backgroundColor
                                }

                                ColumnLayout {
                                    id: eventColumn
                                    // Layout.fillWidth: true

                                    Text {
                                        id: eventSummary
                                        text: summary
                                        color: PlasmaCore.ColorScope.textColor
                                    }

                                    Text {
                                        id: eventDateTime
                                        text: {
                                            Shared.formatEventDuration(model, {
                                                relativeDate: agendaItemDate,
                                                clock_24h: agendaView.cfg_clock_24h
                                            })
                                        }
                                        color: PlasmaCore.ColorScope.textColor
                                        opacity: 0.75
                                    }
                                }
                            }

                            onClicked: {
                                console.log('agendaItem.event.clicked', start.date)
                                if (true) {
                                    // cfg_agenda_event_clicked == "browser_viewevent"
                                    Qt.openUrlExternally(htmlLink)
                                }
                            }
                        }
                    }
                }

            }
        }
    }

    function scrollToTop() {
        agendaListView.positionViewAtBeginning()
    }

    function scrollToDate(date) {
        for (var i = 0; i < agendaModel.count; i++) {
            var agendaItem = agendaModel.get(i);
            if (Shared.isSameDate(date, agendaItem.date)) {
                agendaListView.positionViewAtIndex(i, ListView.Beginning);
                return;
            } else if (Shared.isDateEarlier(date, agendaItem.date)) {
                // If the date is smaller than the current agendaItem.date, scroll to the previous agendaItem.
                if (i > 0) {
                    agendaListView.positionViewAtIndex(i-1, ListView.Beginning);
                } else {
                    agendaListView.positionViewAtBeginning()
                }
                return;
            }
        }
        // If the date is greater than any item in the agenda, scroll to the bottom.
        agendaListView.positionViewAtEnd()
    }

    function buildAgendaItem(dateTime) {
        return {
            date: new Date(dateTime),
            events: [],
            showWeather: false,
            tempLow: 0,
            tempHigh: 0,
            weatherIcon: "",
            weatherText: "",
            weatherDescription: "",
            weatherTempMorn: 0,
            weatherTempDay: 0,
            weatherTempEve: 0,
            weatherTempNight: 0,
        };
    }

    function parseGCalEvents(data) {
        agendaModel.clear();

        if (!(data && data.items))
            return;

        // var eventItemList = [];
        // var timeZoneOffset = new Date().getTimezoneOffset()/60;
        // timeZoneOffset = 'Z' + (timeZoneOffset > 0 ? '-' : '+') + timeZoneOffset + '00';
        // console.log(timeZoneOffset);
        for (var i = 0; i < data.items.length; i++) {
            var eventItem = data.items[i];

            if (eventItem.start.date) {
                eventItem.start.dateTime = new Date(eventItem.start.date + ' 00:00:00');
            } else {
                eventItem.start.dateTime = new Date(eventItem.start.dateTime);
            }
            // console.log(eventItem.start.dateTime, eventItem.summary);

            if (eventItem.end.date) {
                eventItem.end.dateTime = new Date(eventItem.end.date + ' 00:00:00');
            } else {
                eventItem.end.dateTime = new Date(eventItem.end.dateTime);
            }

            // eventItemList.push(eventItem);
        }
        data.items.sort(function(a,b) { return a.start.dateTime - b.start.dateTime; });

        // for (var i = 0; i < data.items.length; i++) {
        //     var eventItem = data.items[i];
        //     console.log(eventItem.start.dateTime, eventItem.summary);
        // }

        var agendaItemList = [];
        function getAgendaItemByDate(date) {
            for (var i = 0; i < agendaItemList.length; i++) {
                var agendaItem = agendaItemList[i];
                if (Shared.isSameDate(agendaItem.date, date)) {
                    return agendaItem;
                }
            }
            return null;
        }
        function insertEventAtDate(date, eventItem) {
            var agendaItem = getAgendaItemByDate(date);
            if (!agendaItem) {
                agendaItem = buildAgendaItem(date);
                agendaItemList.push(agendaItem);
            }
            agendaItem.events.push(eventItem);
        }
        for (var i = 0; i < data.items.length; i++) {
            var eventItem = data.items[i];
            if (cfg_agenda_breakup_multiday_events) {
                // for Max(start, visibleMin) .. Min(end, visibleMax)
                var lowerLimitDate = agendaView.clipEventsOutsideLimits && eventItem.start.dateTime < agendaView.visibleDateMin ? agendaView.visibleDateMin : eventItem.start.dateTime;
                var upperLimitDate = eventItem.end.dateTime;
                if (eventItem.end.date) {
                    // All Day event "ends" day before.
                    upperLimitDate = new Date(eventItem.end.dateTime);
                    upperLimitDate.setDate(upperLimitDate.getDate() - 1);
                }
                if (agendaView.clipEventsOutsideLimits && upperLimitDate > agendaView.visibleDateMax) {
                    upperLimitDate = agendaView.visibleDateMax;
                }
                for (var eventItemDate = new Date(lowerLimitDate); eventItemDate <= upperLimitDate; eventItemDate.setDate(eventItemDate.getDate() + 1)) {
                    insertEventAtDate(eventItemDate, eventItem);
                }
            } else {
                var now = new Date();
                var inProgress = eventItem.start.dateTime <= now && now <= eventItem.end.dateTime;
                if (inProgress) {
                    insertEventAtDate(now, eventItem);
                } else {
                    insertEventAtDate(eventItem.start.dateTime, eventItem);
                }
            }
        }

        var today = new Date();
        var nextNumDaysEndExclusive = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), today.getDate() + showNextNumDays);

        if (clipEventsFromOtherMonths) {
            // Remove calendar from different months
            var currentMonthMin = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), 1);
            var currentMonthMaxExclusive = new Date(currentMonth.getFullYear(), currentMonth.getMonth()+1, 1);
            
            for (var i = 0; i < agendaItemList.length; i++) {
                var agendaItem = agendaItemList[i];
                if (agendaItem.date < currentMonthMin || currentMonthMaxExclusive <= agendaItem.date && nextNumDaysEndExclusive <= agendaItem.date) {
                    console.log('removed agendaItem:', agendaItem.date)
                    agendaItemList.splice(i, 1);
                    i--;
                }
            }
        }

        if (showNextNumDays > 0) {
            for (var day = new Date(today); day <= nextNumDaysEndExclusive; day.setDate(day.getDate() + 1)) {
                // console.log(day);

                // Check if an agendaItem with this date already exists.
                var index = -1;
                for (var i = 0; i < agendaItemList.length; i++) {
                    var agendaItem = agendaItemList[i];
                    if (Shared.isSameDate(day, agendaItem.date)) {
                        index = i;
                        break;
                    }
                }
                if (index >= 0) {
                    // It does, so skip.
                    continue;
                }

                // It doesn't, so we need to insert an item.
                var newAgendaItem = buildAgendaItem(new Date(day));

                // Insert before the agendaItem with a higher date.
                for (var i = 0; i < agendaItemList.length; i++) {
                    var agendaItem = agendaItemList[i];
                    if (Shared.isDateEarlier(day, agendaItem.date)) {
                        index = i;
                        break;
                    }
                }

                if (index >= 0) {
                    // Insert at index
                    agendaItemList.splice(i, 0, newAgendaItem);
                } else {
                    // Append
                    agendaItemList.push(newAgendaItem);
                }
                // console.log('uneventfulDay:', day);
            }
        }
        
        if (clipPastEvents) {
            // Remove calendar events before today.
            var minDate = today;
            if (!clipPastEventsToday) {
                minDate = new Date(today.getFullYear(), today.getMonth(), today.getDate());
            }
            for (var i = 0; i < agendaItemList.length; i++) {
                var agendaItem = agendaItemList[i];
                if (agendaItem.date < minDate) {
                    // console.log('removed agendaItem:', agendaItem.date)
                    agendaItemList.splice(i, 1);
                    i--;
                }
            }
        }

        for (var i = 0; i < agendaItemList.length; i++) {
            agendaModel.append(agendaItemList[i]);
        }
    }

    function parseWeatherForecast(data) {
        if (!(data && data.list))
            return;

        for (var j = 0; j < data.list.length; j++) {
            var forecastItem = data.list[j];
            var day = new Date(forecastItem.dt * 1000);

            for (var i = 0; i < agendaModel.count; i++) {
                var agendaItem = agendaModel.get(i);
                if (Shared.isSameDate(day, agendaItem.date)) {
                    // console.log(day);
                    agendaItem.tempLow = Math.floor(forecastItem.temp.min);
                    agendaItem.tempHigh = Math.ceil(forecastItem.temp.max);
                    agendaModel.setProperty(i, 'tempLow', Math.floor(forecastItem.temp.min));
                    agendaModel.setProperty(i, 'tempHigh', Math.ceil(forecastItem.temp.max));
                    var weatherIcon = Shared.weatherIconMap[forecastItem.weather[0].icon] || 'weather-severe-alert';
                    agendaModel.setProperty(i, 'weatherIcon', weatherIcon);
                    agendaModel.setProperty(i, 'weatherText', forecastItem.weather[0].main);
                    agendaModel.setProperty(i, 'weatherDescription', forecastItem.weather[0].description);
                    agendaModel.setProperty(i, 'weatherTempMorn', Math.round(forecastItem.temp.morn));
                    agendaModel.setProperty(i, 'weatherTempDay', Math.round(forecastItem.temp.day));
                    agendaModel.setProperty(i, 'weatherTempEve', Math.round(forecastItem.temp.eve));
                    agendaModel.setProperty(i, 'weatherTempNight', Math.round(forecastItem.temp.night));
                    agendaModel.setProperty(i, 'showWeather', true);
                    
                    break;
                }
            }
        }
    }

    Component.onCompleted: {
        parseGCalEvents({ "items": [], });
        parseWeatherForecast({ "list": [], });

        if (typeof root === 'undefined') {
            clipPastEvents = false
            parseGCalEvents(DebugFixtures.getEventData());
            parseWeatherForecast(DebugFixtures.getDailyWeatherData());
        }
    }
}
