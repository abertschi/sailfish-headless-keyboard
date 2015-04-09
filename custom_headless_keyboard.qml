// The MIT License (MIT)
// 
// Copyright (c) 2015 Andrin Bertschi
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import ".."

KeyboardLayout {
    property
    var db: null

    KeyboardRow {
        SpacebarKey {
            id: spacebar
            languageLabel: getSetting("label", "headless keyboard")
        }
        EnterKey {}
    }

    Connections {
        target: Clipboard
        onTextChanged: {
            debug('new text for clipboard')

            var text = Clipboard.text

            text = '{ cmds: [{ cmd: "set_label", "arg": "this is a label"}]}'

            var command = parseJson(text)

            if (command == null) {
                return
            }

            if (command.cmd != 'undefined') {
                evalCmd(command.cmd, command.arg)
            }

            if (command.cmds != 'undefined') {
                for (var i = 0; i < command.cmds.length; i++) {
                    var cmd = command.cmds[i]
                    evalCmd(cmd.cmd, cmd.arg)
                }
            }
        }
    }

    function evalCmd(cmd, msg) {
        var ret = processCmd(cmd, msg)
        if (ret != -1) {
            Clipboard.text = ''
        }
    }

    // returns -1 if unknown command 'cmd' was given
    function processCmd(cmd, msg) {
        debug('processing cmd and msg(' + cmd + ',' + msg + ')')

        switch (cmd) {
            case 'set_label':
                saveSetting('label', msg)
                spacebar.languageLabel = msg
                break;

            case 'insert_text':
                MInputMethodQuick.sendCommit(msg)
                break;

            case 'key_backspace':
                //MInputMethodQuick.sendCommit(msg)
                break;

            case 'key_return':
                //MInputMethodQuick.sendCommit(msg)
                break;

            default:
                debug('unknown command: (' + cmd + ',' + msg + ')'
                return -1
        }
        return 0
    }

    function debug(msg) {
        MInputMethodQuick.sendCommit('- ' + msg + '\r')
    }

    function parseJson(json) {
        var command;
        try {
            command = JSON.parse(text)
        } catch (e) {
            command = null
        }
        return command
    }

    function openDB() {
        if (db !== null) return;
        db = LocalStorage.openDatabaseSync("headless-keyboard", "0.1", "headless keyboard layout", 100000);
        MInputMethodQuick.sendCommit(db)
        try {
            db.transaction(function(tx) {
                tx.executeSql('CREATE TABLE IF NOT EXISTS settings(key TEXT UNIQUE, value TEXT)');
                var table = tx.executeSql("SELECT * FROM settings");
            });
        } catch (err) {
            MInputMethodQuick.sendCommit(err)
            return err;
        };
    }

    function saveSetting(key, value) {
        openDB();
        db.transaction(function(tx) {
            tx.executeSql('INSERT OR REPLACE INTO settings VALUES(?, ?)', [key, value]);
        });
    }

    function getSetting(key, defvalue) {
        openDB();
        var res = null;
        db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT value FROM settings WHERE key=?;', [key]);
            if (rs.rows.length) {
                res = rs.rows.item(0).value
            }
        });
        return ((typeof(res) == 'undefined') || (res === null)) ? defvalue : res;
    }
}