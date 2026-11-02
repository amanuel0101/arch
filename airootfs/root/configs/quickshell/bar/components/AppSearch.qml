import QtQuick
import Quickshell
import QtQuick.Controls
import ".."
import "theme"

Rectangle {
    property bool active: AppState.morpher_state === "launcher"
    property var a_st: AppLauncherState
    property var all_apps: DesktopEntries.applications.values

    onActiveChanged: {
        if (active) {
            input.focus = true
        }
        else {
            input.focus = false
            Qt.callLater(() => {
                input.clear()
                //a_st.apps = []
            })
        }
    }

    id: root

    anchors.fill: parent

    color: Colors.background

    radius: Vars.rad

    TextField {
        onTextChanged: {
            a_st.apps = text.trim() === "" ? [] : search(text)
        }
        id: input

        anchors.fill: parent

        leftPadding: Vars.rad / 2
        rightPadding: Vars.rad / 2

        placeholderText: "Search..."
        placeholderTextColor: Qt.alpha(Colors.foreground, 0.5)

        font {
            family: "SF Mono"
            pixelSize: 15
        }

        color: Colors.foreground

        background: Rectangle {
            color: "transparent"
            radius: Vars.rad
        }

        Keys.onReturnPressed: {
            if (a_st.apps.length > 0) {
                a_st.apps[0].execute()
                AppState.change_state("bar")
            }
        }

        Keys.onEnterPressed: {
            if (a_st.apps.length > 0) {
                a_st.apps[0]?.execute()
                AppState.change_state("bar")
            }
        }

        Keys.onEscapePressed: {
            AppState.change_state("bar")
        }
    }

    function search(txt) {
        const query = txt.toLowerCase();
        let results = [];

        function score(name) {
            const n = name.toLowerCase();

            if (n === query) return 1000;
            if (n.startsWith(query)) return 900;
            if (n.includes(query)) return 700;

            // Word-start matching
            let words = n.split(/[\s_-]+/);

            for (let i = 0; i < words.length; i++) {
                if (words[i].startsWith(query))
                    return 800;
            }

            // Fuzzy matching
            let qi = 0;
            let points = 0;
            let consecutive = 0;

            for (let i = 0; i < n.length && qi < query.length; i++) {
                if (n[i] === query[qi]) {
                    qi++;
                    consecutive++;
                    points += 10 + consecutive * 2;
                } else {
                    consecutive = 0;
                }
            }

            return qi === query.length ? points : 0;
        }

        for (let i = 0; i < root.all_apps.length; i++) {
            let app = root.all_apps[i];
            let s = score(app.name);

            if (s > 0)
                results.push({ app: app, score: s });
        }

        // Sort by score (descending)
        for (let i = 1; i < results.length; i++) {
            let current = results[i];
            let j = i - 1;

            while (j >= 0 && results[j].score < current.score) {
                results[j + 1] = results[j];
                j--;
            }

            results[j + 1] = current;
        }

        let output = [];

        for (let i = 0; i < results.length; i++)
            output.push(results[i].app);

        return output;
    }
}