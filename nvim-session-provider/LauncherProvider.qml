import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
    id: root

    // Plugin API provided by PluginService
    property var pluginApi: null

    // Provider metadata
    property string name: "Neovim Sessions"
    property var launcher: null
    property bool handleSearch: false
    property string supportedLayouts: "list"
    property bool supportsAutoPaste: false

    // Constants
    property int maxResults: 50

    // Database
    property string sessionDir
    property var database: null
    property bool loaded: false
    property bool loading: false

    Process {
        id: nvimSessionDirLoader
        command: ["ls", "-1t", "placeholder"]
        stdout: StdioCollector {
        }
        stderr: StdioCollector {
        }
        onExited: (exitCode) => root.parseSessionFiles(exitCode)
    }

    Component {
        id: sessionFileParser

        FileView {
            id: fileView
        }
    }


    // Load database on init
    function init() {
        Logger.i("NeovimSessionProvider", "init called, pluginDir:", pluginApi?.pluginDir);
        name = pluginApi.tr("launcher.title");
        sessionDir = pluginApi.pluginSettings.sessionDir || pluginApi.manifest.metadata.defaultSettings.sessionDir
        sessionDir = sessionDir.replace(/~/g, Quickshell.env("HOME"));
        fetchSessionFiles()
    }

    function fetchSessionFiles() {
        if(nvimSessionDirLoader.running) {
            Logger.w("NeovimSessionProvider", "Already fetching session files!");
            return;
        }
        Logger.i("NeovimSessionProvider", "Fetching session files");
        loaded = false;
        loading = true;
        nvimSessionDirLoader.command[2] = sessionDir;
        nvimSessionDirLoader.running = true;
    }

    function parseSessionFiles(exitCode: int) {
        if( exitCode != 0 ) {
            Logger.e("NeovimSessionProvider", "Error listing session files: ", nvimSessionDirLoader.stderr.text);
        }

        try {
            let fileList = nvimSessionDirLoader.stdout.text.split('\n');
            root.database = fileList
                .filter((filename) => !!filename.trim())
                .map((filename) => {
                const entry = {
                    fullPath: sessionDir.concat("/", filename),
                    displayName: simplifyFilename(filename),
                    loaded: false,
                    workspacePath: ""
                };

                const loader = sessionFileParser.createObject(root);
                // Connect the signal handler before setting the path to avoid race condition
                //Logger.d("NeovimSessionProvider", Object.entries(loader));
                loader.textChanged.connect( () => root.sessionFileLoaded(entry, loader.text()) );
                loader.path = entry.fullPath;

                return entry;
            });
        } catch (e) {
            Logger.e("NeovimSessionProvider", "Error parsing session files: ", e);
        }
    }

    function simplifyFilename(fullname: string): string {
        let pathSep = null;
        let branchSep = null;
        let stripSuffix = false; // Whether to remove ".vim" from the end of the filename
        if(fullname.startsWith("__")) {
            // neovim_session_manager style separator
            pathSep = /__/g;
        } else if(fullname.startsWith("%2F")) {
            // auto-session style separator
            pathSep = /%2F/g;
            branchSep = /%7C/;
            stripSuffix = true;
        } else if(fullname.startsWith("%")) {
            // persistence style separator
            pathSep = /%/g;
            branchSep = /%%/;
            stripSuffix = true;
        }

        if(stripSuffix) {
            fullname = fullname.replace(/\.vim$/, "");
        }

        let branchName = null;
        if(!!branchSep) {
            const parts = fullname.split(branchSep);
            if(parts.length > 1) {
                branchName = parts.pop();
                fullname = parts.pop();
            }
        }

        let dirname = fullname;
        if(!!pathSep) {
            dirname = fullname.split(pathSep).pop();
        }

        if(!!branchName) {
            return `${dirname} (${branchName})`;
        } else {
            return dirname;
        }
    }

    function sessionFileLoaded(entry, sessionText) {
        entry.workspacePath = getWorkspacePath(sessionText);
        entry.loaded = true;

        // Check to see if we've finished loading all the session files
        for(let e of database) {
            if(!e.loaded) {
                return;
            }
        }

        loaded = true;
        loading = false;
        Logger.i("NeovimSessionProvider", "Finished loading session files");
    }

    function getWorkspacePath(sessionText) {
        const lines = sessionText.split('\n');
        for(let line of lines) {
            if(line.startsWith('cd ')) {
                return line.slice(3);
            }
        }
    }

    function handleCommand(searchText) {
        return searchText.startsWith(">nvim");
    }

    // Return available commands when user types ">"
    function commands() {
        return [{
            "name": ">nvim",
            "description": pluginApi?.tr("launcher.description") || "Search and open Neovim sessions",
            "icon": "code",
            "isTablerIcon": true,
            "isImage": false,
            "onActivate": function() {
                launcher.setSearchText(">nvim ");
            }
        }];
    }

    // Get search results
    function getResults(searchText) {

        if (loading) {
          return [{
            "name": pluginApi?.tr("launcher.loading.title") || "Loading...",
            "description": pluginApi?.tr("launcher.loading.description") || "Loading sessions...",
            "icon": "refresh",
            "isTablerIcon": true,
            "isImage": false,
            "onActivate": function() {}
          }];
        }

        if (!loaded) {
          return [{
            "name": pluginApi?.tr("launcher.error.title") || "Neovim sessions not loaded",
            "description": pluginApi?.tr("launcher.error.description") || "Check your log for error messages",
            "icon": "alert-circle",
            "isTablerIcon": true,
            "isImage": false,
            "onActivate": function() {
              root.init();
            }
          }];
        }

        if (!searchText.startsWith(">nvim")) {
            return [];
        }

        let query = searchText.slice(6).trim().toLowerCase();
        if(!!query) {
            return FuzzySort.go(query, database, {
                limit: maxResults,
                key: "displayName"
            }).map(r => formatEntry(r.obj));
        } else {
            return database.map(formatEntry); // Database is already sorted by most recently updated workspace
        }

    }

    function formatEntry(entry) {
        return {
          // Display
          "name": entry.displayName,           // Main text
          "description": entry.workspacePath || "",   // Secondary text (optional)

          // Icon options (choose one)
          "icon": "nvim",                   // Icon name
          "isTablerIcon": false,             // Use Tabler icon set
          "isImage": false,                 // Is this an image?
          "hideIcon": false,                // Hide the icon entirely

          // Layout
          "singleLine": false,              // Clip to single line height

          // Reference
          "provider": root,                 // Reference to provider (for actions)

          // Callbacks
          "onActivate": function() {        // Called when result is selected
              root.activateEntry(entry);
              launcher.close();
          },
        }
    }

    function activateEntry(entry) {
        Logger.i("NeovimSessionProvider", "Opening session:", entry.fullPath );
        const runInTerminal = pluginApi.pluginSettings.runInTerminal ?? pluginApi.manifest.metadata.defaultSettings.runInTerminal;
        const nvim = (pluginApi.pluginSettings.nvim || pluginApi.manifest.metadata.defaultSettings.nvim).split(" ");
        if(runInTerminal) {
            const terminal = Settings.data.appLauncher.terminalCommand.split(" ");
            const command = terminal.concat(nvim, "-S", enquote(entry.fullPath));
            Quickshell.execDetached(command);
        } else {
            Quickshell.execDetached(nvim.concat("-S", entry.fullPath));
        }
    }

    function enquote(text: string): string {
        return "'" + text.replace(/'/g, "'\\''") + "'";
    }

}

