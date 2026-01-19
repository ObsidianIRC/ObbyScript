# UnrealIRCd JavaScript Scripting Module

A powerful server-side JavaScript scripting module for UnrealIRCd using the embedded Duktape engine. Write IRC bot features, custom commands, and automated behaviors in JavaScript without compiling C code.

## Features

- **Custom Commands**: Register new IRC commands that users can execute
- **Event Hooks**: React to IRC events (joins, parts, messages, etc.)
- **HTTP API**: Make async HTTP requests to external APIs
- **Timers**: Schedule code with `setInterval()` and `setTimeout()`
- **Client Info**: Access full client data like nick, IP, account, modes
- **Message Tags**: Work with IRCv3 message tags (msgid, time, reply, etc.)
- **Special Lists**: Iterate all clients, servers, channels, and operators
- **RPC Methods**: Register custom JSON-RPC methods for remote control
- **Extended Bans**: Create custom extban types for advanced channel control
- **Channel/User Modes**: Register custom channel and user modes
- **ModData Storage**: Store persistent data on clients and channels
- **Database API**: Persistent storage with optional encryption via UnrealDB

## Installation
### Use the installer script
1. Setup: `chmod +x install.sh`
2. Run: `./install.sh`
3. Type in your UnrealIRCd build directory
   
And then go to step 5 in [the Loading section](README.md#Loading)

### Manual Installation
1. Place `obbyscript.c` in `src/modules/third/`
2. Place Duktape source files (`duktape.c`, `duktape.h`, `duk_config.h`) in the same directory
3. Build: `EXLIBS="-lm" make` from the UnrealIRCd source directory
4. Install: `make install` from the UnrealIRCd source directory

### Loading
5. Add to config: `loadmodule "third/obbyscript";`
6. Create scripts directory: `mkdir /path/to/unrealircd/conf/scripts`
7. Rehash the server: `/REHASH`

## Quick Start

Create a file `conf/scripts/hello.js`:

```javascript
// Simple hello command
registerCommand({
    name: 'HELLO',
    handler: function() {
        sendNotice($client, 'Hello ' + $client.name + '!');
        return 1;
    }
});

// Welcome new users
registerHook({
    type: HOOKTYPE_LOCAL_CONNECT,
    handler: function() {
        sendNotice($client, 'Welcome to the server, ' + $client.name + '!');
        return 0;
    }
});
```

---

## API Reference

### Global Variables

In command handlers:
| Variable | Description |
|----------|-------------|
| `$client` | The client object who issued the command |
| `$parc` | Number of parameters (argc style) |
| `$parv[]` | Array of parameters (0-indexed, starts at first actual param) |

In hook handlers, additional variables are set based on the hook type (see Hooks section).

### Client Object Properties

```javascript
$client.name        // Nickname
$client.username    // Ident/username
$client.ip          // IP address
$client.realhost    // Real hostname
$client.vhost       // Virtual host (cloaked)
$client.info        // GECOS/realname
$client.server      // Server the client is on
$client.account     // NickServ account (if logged in)
$client.isOper      // Boolean: is IRC operator
$client.isUser      // Boolean: is a user (not server)
$client.isServer    // Boolean: is a server
$client.umodes      // User modes as integer bitmask
$client.id          // Client UID (for linking)
```

### Channel Object Properties

```javascript
$channel.name       // Channel name (e.g., "#chat")
$channel.topic      // Current topic
$channel.users      // Number of users in channel
$channel.modes      // Channel modes as integer bitmask
```

---

## Functions

### Core Functions

#### sendNotice(client, message)
Send a NOTICE to a client.

```javascript
sendNotice($client, 'Hello, world!');
```

#### sendNumeric(client, numeric, message)
Send a numeric reply to a client.

```javascript
sendNumeric($client, 461, 'COMMAND :Not enough parameters');
```

#### sendRaw(client, message)
Send a raw IRC protocol line to a client.

```javascript
sendRaw($client, ':server PRIVMSG ' + $client.name + ' :Hello');
```

#### log(message)
Write a message to the UnrealIRCd log.

```javascript
log('Something happened: ' + $client.name);
```

---

### Lookup Functions

#### findClient(name)
Look up a client by nickname. Returns client object or null.

```javascript
var target = findClient('SomeNick');
if (target) {
    sendNotice(target, 'Found you!');
}
```

#### findChannel(name)
Look up a channel by name. Returns channel object or null.

```javascript
var chan = findChannel('#chat');
if (chan) {
    log('Channel ' + chan.name + ' has ' + chan.users + ' users');
}
```

#### findServer(name)
Look up a server by name. Returns server object or null.

```javascript
var srv = findServer('irc.example.com');
if (srv) {
    log('Found server: ' + srv.name);
}
```

---

### Client Check Functions

#### isOper(client)
Check if a client is an IRC operator.

```javascript
if (isOper($client)) {
    sendNotice($client, 'You are an IRCOp');
}
```

#### isUser(client)
Check if a client is a user (not a server).

```javascript
if (isUser($client)) {
    sendNotice($client, 'You are a user');
}
```

#### isServer(client)
Check if a client is a server.

```javascript
if (isServer($client)) {
    log('This is a server connection');
}
```

#### isLoggedIn(client)
Check if a client is logged into services (has an account).

```javascript
if (isLoggedIn($client)) {
    sendNotice($client, 'Logged in as: ' + $client.account);
}
```

#### isSecure(client)
Check if a client is using TLS/SSL.

```javascript
if (isSecure($client)) {
    sendNotice($client, 'Your connection is secure');
}
```

#### isULine(client)
Check if a client is a U-lined server (services).

```javascript
if (isULine($client)) {
    log('This is a services server');
}
```

#### hasMode(client, mode)
Check if a client has a specific user mode.

```javascript
if (hasMode($client, 'o')) {
    // User has +o (oper mode)
}
```

---

### Registration Functions

#### registerCommand(config)
Register a new IRC command.

```javascript
registerCommand({
    name: 'MYCOMMAND',
    handler: function() {
        // $client, $parc, $parv available here
        sendNotice($client, 'You ran MYCOMMAND!');
        if ($parc > 0) {
            sendNotice($client, 'First param: ' + $parv[0]);
        }
        return 1;
    }
});
```

#### registerHook(config)
Register a hook to respond to IRC events.

```javascript
registerHook({
    type: HOOKTYPE_LOCAL_JOIN,
    handler: function() {
        // $client and $channel available
        log($client.name + ' joined ' + $channel.name);
        return 0;
    }
});
```

---

### Channel Mode Functions

#### registerChannelMode(config)
Register a custom channel mode.

```javascript
registerChannelMode({
    letter: 'X',              // Mode letter
    type: 'NORMAL',           // NORMAL, PARAM, PARAM_SET, or LIST
    handler: function() {
        // Called when mode is set/unset
        // $client, $channel, $param, $adding available
        if ($adding) {
            log($client.name + ' set +X on ' + $channel.name);
        }
        return 0; // 0 = allow, non-zero = deny
    }
});
```

Mode types:
- `NORMAL` - Simple on/off mode (like +n, +t)
- `PARAM` - Always requires a parameter (like +k)
- `PARAM_SET` - Parameter only when setting (like +l)
- `LIST` - List mode (like +b)

#### registerPrefixMode(config)
Register a custom channel prefix mode (like +o/@, +v/+).

```javascript
registerPrefixMode({
    letter: 'y',              // Mode letter
    prefix: '!',              // Prefix character shown before nick
    rank: 5,                  // Rank (higher = more power)
    handler: function() {
        // $client = who set it, $target = affected user
        // $channel, $adding available
        if ($adding) {
            log($target.name + ' got +y in ' + $channel.name);
        }
        return 0;
    }
});
```

#### setChannelMode(channel, from, modes)
Set or remove channel mode(s) programmatically.

```javascript
var chan = findChannel('#test');
setChannelMode(chan, $client, '+k secretkey');
setChannelMode(chan, $client, '+nt');
setChannelMode(chan, $client, '-k *');
```

---

### User Mode Functions

#### registerUserMode(config)
Register a custom user mode.

```javascript
registerUserMode({
    letter: 'Y',              // Mode letter
    handler: function() {
        // $client = user, $adding = true/false
        if ($adding) {
            log($client.name + ' set +Y');
        }
        return 0;
    }
});
```

#### setUserMode(client, modes)
Set or remove a user mode programmatically.

```javascript
setUserMode($client, '+x');  // Set cloaked host
setUserMode($client, '-x');  // Remove cloaked host
```

---

### ModData Functions (Persistent Storage)

#### registerModData(config)
Register a ModData field for storing custom data on clients, channels, etc.

```javascript
registerModData({
    name: 'mydata',           // Unique name for this data
    type: 'client',           // 'client', 'channel', 'member', 'membership', or 'local_client'
    sync: true                // Sync across servers? (default: false)
});
```

#### setModData(target, name, value)
Store data on a client or channel.

```javascript
// Store on client
setModData($client, 'mydata', 'some value');

// Store on channel
var chan = findChannel('#test');
setModData(chan, 'chandata', 'channel specific value');
```

#### getModData(target, name)
Retrieve stored data from a client or channel.

```javascript
var data = getModData($client, 'mydata');
if (data) {
    sendNotice($client, 'Your stored data: ' + data);
}
```

---

### Channel Operations

#### checkChannelAccess(client, channel, access)
Check if a client has specific access in a channel.

```javascript
var chan = findChannel('#test');
if (checkChannelAccess($client, chan, 'o')) {
    sendNotice($client, 'You are an op in ' + chan.name);
}
```

#### getChannelMembers(channel)
Get an array of all members in a channel.

```javascript
var chan = findChannel('#test');
var members = getChannelMembers(chan);
sendNotice($client, 'Users in ' + chan.name + ':');
for (var i = 0; i < members.length; i++) {
    sendNotice($client, '  ' + members[i].name);
}
```

#### getUserChannels(client)
Get an array of all channels a user is in.

```javascript
var channels = getUserChannels($client);
sendNotice($client, 'You are in ' + channels.length + ' channels');
for (var i = 0; i < channels.length; i++) {
    sendNotice($client, '  ' + channels[i].name);
}
```

#### joinChannel(client, channel)
Make a client join a channel.

```javascript
joinChannel($client, '#welcome');
```

#### partChannel(client, channel, reason)
Make a client part a channel.

```javascript
partChannel($client, '#oldchan', 'Moving on');
```

#### kickUser(channel, client, victim, reason)
Kick a user from a channel.

```javascript
var chan = findChannel('#test');
var target = findClient('BadUser');
kickUser(chan, $client, target, 'Bye bye!');
```

#### setTopic(channel, topic, client)
Set the topic of a channel.

```javascript
var chan = findChannel('#test');
setTopic(chan, 'New topic set by JavaScript!', $client);
```

---

### Client Operations

#### sendToChannel(channel, client, message, skip)
Send a message to all members of a channel.

```javascript
var chan = findChannel('#test');
sendToChannel(chan, $client, 'PRIVMSG ' + chan.name + ' :Hello everyone!', false);
```

#### sendToServer(server, message)
Send a raw message to a specific server.

```javascript
var srv = findServer('hub.example.com');
sendToServer(srv, 'PING :timestamp');
```

#### sendToAllServers(message)
Broadcast a raw message to all linked servers.

```javascript
sendToAllServers(':myserver NOTICE $* :Server maintenance in 5 minutes');
```

#### doCmd(client, command, ...args)
Execute an IRC command as if the client sent it. Can be called multiple ways:

```javascript
// Single string - parsed automatically
doCmd($client, 'JOIN #welcome');
doCmd($client, 'PRIVMSG #test :Hello!');

// Separate arguments
doCmd($client, 'JOIN', '#welcome');
doCmd($client, 'PRIVMSG', '#test', 'Hello everyone!');
```

#### exitClient(client, source, reason)
Disconnect a client from the server.

```javascript
exitClient($client, null, 'Disconnected by JavaScript');
```

#### changeNick(client, newnick)
Force a client to change their nickname.

```javascript
changeNick($client, 'NewNick');
```

#### setHost(client, newhost)
Set a virtual host (vhost) on a client.

```javascript
setHost($client, 'cool.vhost.example.com');
```

---

### TKL (Ban) Functions

#### addTKL(type, ident, host, setter, expire, reason)
Add a server ban (G-line, K-line, etc.).

```javascript
// Add a 1-hour G-line
var expireTime = Math.floor(Date.now() / 1000) + 3600;
addTKL('G', '*', 'evil.host.com', 'JavaScript', expireTime, 'Banned by script');
```

TKL types:
- `G` - G-line (global ban)
- `K` - K-line (local ban)
- `Z` - Z-line (IP ban)
- `s` - Shun
- `Q` - Q-line (nick ban)

#### delTKL(type, ident, host)
Remove a server ban.

```javascript
delTKL('G', '*', 'evil.host.com');
```

---

### Message Tags API

IRC message tags (IRCv3) allow metadata to be attached to messages. These functions let you work with message tags in JavaScript.

#### createMtag(name, value)
Create a single message tag object.

```javascript
var tag = createMtag('msgid', 'abc123');
// Returns: { name: 'msgid', value: 'abc123' }
```

#### addMtag(mtags, name, value)
Add a new tag to an existing mtags array.

```javascript
var mtags = [];
mtags = addMtag(mtags, 'msgid', 'abc123');
mtags = addMtag(mtags, '+draft/reply', 'xyz789');
```

#### findMtag(mtags, name)
Find a tag by name in an mtags array.

```javascript
var tag = findMtag($mtags, 'msgid');
if (tag) {
    log('Message ID: ' + tag.value);
}
```

#### deleteMtag(mtags, name)
Remove a tag from an mtags array by name.

```javascript
mtags = deleteMtag(mtags, 'msgid');
```

#### mtagsToString(mtags, client)
Convert an mtags array to the IRC protocol string format.

```javascript
var tagString = mtagsToString($mtags, $client);
// Returns: "@msgid=abc123;time=2024-01-01T00:00:00Z"
```

#### newMessageTags(sender)
Create a new mtags array with standard tags (msgid, time) prepopulated.

```javascript
var mtags = newMessageTags($client);  // Create with client as sender
var mtags = newMessageTags(null);     // Create with server as sender
```

#### $mtags Variable
In hooks that receive message tags (JOIN, PART, KICK, QUIT, CHANMSG, USERMSG, NICKCHANGE, TOPIC, AWAY), the `$mtags` variable contains the incoming message tags as an array of objects.

```javascript
registerHook({
    type: HOOKTYPE_CHANMSG,
    handler: function() {
        // Access incoming message tags
        for (var i = 0; i < $mtags.length; i++) {
            log('Tag: ' + $mtags[i].name + ' = ' + $mtags[i].value);
        }
        return 0;
    }
});
```

#### Sending Messages with Tags
Both `sendToChannel` and `sendToServer` accept an optional mtags parameter:

```javascript
var mtags = newMessageTags($client);
mtags = addMtag(mtags, '+draft/reply', 'originalMsgId');
sendToChannel(channel, SEND_TYPE_PRIVMSG, $client, 'Hello!', mtags);
```

---

### Special List Functions

These functions let you iterate over all clients, servers, channels, and operators on the network.

#### getAllClients()
Get an array of all users (not servers) on the network.

```javascript
var users = getAllClients();
log('Total users on network: ' + users.length);
for (var i = 0; i < users.length; i++) {
    log('User: ' + users[i].name);
}
```

#### getAllLocalClients()
Get an array of all locally connected users.

```javascript
var localUsers = getAllLocalClients();
log('Local users: ' + localUsers.length);
```

#### getAllServers()
Get an array of all servers on the network.

```javascript
var servers = getAllServers();
log('Servers on network: ' + servers.length);
for (var i = 0; i < servers.length; i++) {
    log('Server: ' + servers[i].name);
}
```

#### getAllLocalServers()
Get an array of locally connected servers.

```javascript
var localServers = getAllLocalServers();
log('Directly linked servers: ' + localServers.length);
```

#### getAllOpers()
Get an array of all locally connected IRC operators.

```javascript
var opers = getAllOpers();
log('Online IRCOps: ' + opers.length);

// Broadcast to all opers
for (var i = 0; i < opers.length; i++) {
    sendNotice(opers[i], 'Admin broadcast: Server maintenance in 5 minutes');
}
```

#### getAllChannels()
Get an array of all channels on the network.

```javascript
var channels = getAllChannels();
log('Total channels: ' + channels.length);
for (var i = 0; i < channels.length; i++) {
    log('Channel: ' + channels[i].name + ' (' + channels[i].users + ' users)');
}
```

---

## Timers

### setInterval(callback, milliseconds)
Execute a function repeatedly at the specified interval. Returns a timer ID.

```javascript
var timerId = setInterval(function() {
    log('This runs every 5 seconds');
}, 5000);
```

### setTimeout(callback, milliseconds)
Execute a function once after the specified delay. Returns a timer ID.

```javascript
setTimeout(function() {
    log('This runs once after 10 seconds');
}, 10000);
```

### clearInterval(timerId) / clearTimeout(timerId)
Cancel a timer.

```javascript
var id = setInterval(function() { log('tick'); }, 1000);
// Later...
clearInterval(id);
```

**Note**: Minimum interval is 100ms for setInterval, 10ms for setTimeout.

---

## HTTP Requests

### httpGet(url, callback)
Make an asynchronous HTTP GET request.

```javascript
httpGet('https://api.example.com/data', function(error, body) {
    if (error) {
        log('HTTP Error: ' + error);
        return;
    }
    try {
        var data = JSON.parse(body);
        log('Got data: ' + data.message);
    } catch (e) {
        log('JSON parse error: ' + e);
    }
});
```

The callback receives two arguments:
- `error`: Error message string, or null on success
- `body`: Response body string, or null on error

---

## Database API (UnrealDB)

The JavaScript module provides access to UnrealIRCd's database system for persistent storage. Databases are stored in the `data/` directory and support optional encryption using secret blocks.

**Security Note**: All database paths are restricted to the `data/` directory. Absolute paths and path traversal (`..`) are not allowed.

### Mode Constants

| Constant | Description |
|----------|-------------|
| `DB_READ` | Open database for reading |
| `DB_WRITE` | Open database for writing (creates new file) |

### Error Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `DB_ERROR_SUCCESS` | 0 | Operation successful |
| `DB_ERROR_FILENOTFOUND` | 1 | File does not exist |
| `DB_ERROR_CRYPTED` | 2 | File is encrypted but no password provided |
| `DB_ERROR_NOTCRYPTED` | 3 | File is not encrypted but password was provided |
| `DB_ERROR_HEADER` | 4 | Corrupt or invalid file header |
| `DB_ERROR_SECRET` | 5 | Invalid secret block |
| `DB_ERROR_PASSWORD` | 6 | Wrong password |
| `DB_ERROR_IO` | 7 | I/O error (disk full, permission denied, etc.) |
| `DB_ERROR_API` | 8 | API misuse (e.g., reading from write-mode file) |
| `DB_ERROR_INTERNAL` | 9 | Internal error |

### dbOpen(filename, mode, secret_block)

Opens a database file for reading or writing.

```javascript
// Open for writing (unencrypted)
var db = dbOpen('mybot/userdata.db', DB_WRITE, null);
if (db === null) {
    var err = dbGetError();
    log('Failed to open database: ' + err.message);
    return;
}

// Open for reading (encrypted using secret block)
var db = dbOpen('mybot/secrets.db', DB_READ, 'mybot-secret');
```

**Parameters**:
- `filename`: Path relative to data/ directory (e.g., `mybot/data.db`)
- `mode`: `DB_READ` or `DB_WRITE`
- `secret_block`: Name of secret block for encryption, or `null` for unencrypted

**Returns**: Database handle ID on success, or `null` on failure

### dbClose(handle)

Closes an open database handle. Always close databases when done to ensure data is flushed.

```javascript
var success = dbClose(db);
if (!success) {
    log('Warning: database close may have failed');
}
```

**Returns**: `true` on success, `false` on failure

### Write Functions

#### dbWriteInt64(handle, value)
Writes a 64-bit integer to the database.

```javascript
dbWriteInt64(db, Date.now());  // Store timestamp
dbWriteInt64(db, 9007199254740991);  // Large number
```

#### dbWriteInt32(handle, value)
Writes a 32-bit integer to the database.

```javascript
dbWriteInt32(db, 12345);
dbWriteInt32(db, userCount);
```

#### dbWriteInt16(handle, value)
Writes a 16-bit integer (0-65535) to the database.

```javascript
dbWriteInt16(db, 1);  // Version number
dbWriteInt16(db, arrayLength);
```

#### dbWriteStr(handle, value)
Writes a string to the database. Can store `null`.

```javascript
dbWriteStr(db, 'Hello World');
dbWriteStr(db, $client.name);
dbWriteStr(db, null);  // Store null value
```

#### dbWriteChar(handle, value)
Writes a single character/byte to the database.

```javascript
dbWriteChar(db, 'Y');  // From string
dbWriteChar(db, 65);   // From ASCII code ('A')
```

### Read Functions

#### dbReadInt64(handle)
Reads a 64-bit integer from the database.

```javascript
var timestamp = dbReadInt64(db);
if (timestamp === null) {
    log('Failed to read timestamp');
}
```

#### dbReadInt32(handle)
Reads a 32-bit integer from the database.

```javascript
var count = dbReadInt32(db);
```

#### dbReadInt16(handle)
Reads a 16-bit integer from the database.

```javascript
var version = dbReadInt16(db);
if (version !== 1) {
    log('Unsupported database version');
}
```

#### dbReadStr(handle)
Reads a string from the database.

```javascript
var name = dbReadStr(db);
if (name === null) {
    // Could be stored null or read error - check dbGetError()
}
```

#### dbReadChar(handle)
Reads a single character from the database.

```javascript
var flag = dbReadChar(db);
if (flag === 'Y') {
    // Feature enabled
}
```

### dbGetError()

Gets information about the last database error.

```javascript
var err = dbGetError();
log('Error code: ' + err.code);
log('Error message: ' + err.message);

if (err.code === DB_ERROR_FILENOTFOUND) {
    // Create new database
}
```

**Returns**: Object with `code` (number) and `message` (string or null) properties

### Complete Database Example

```javascript
// User warning system with persistent storage
var WARNINGS_FILE = 'warnings.db';
var WARNINGS_VERSION = 1;
var warnings = {};  // nick -> {count, reason, time}

// Load warnings on startup
function loadWarnings() {
    var db = dbOpen(WARNINGS_FILE, DB_READ, null);
    if (db === null) {
        var err = dbGetError();
        if (err.code === DB_ERROR_FILENOTFOUND) {
            log('No warnings database found, starting fresh');
            return;
        }
        log('Error loading warnings: ' + err.message);
        return;
    }

    // Read version
    var version = dbReadInt16(db);
    if (version !== WARNINGS_VERSION) {
        log('Unsupported warnings database version');
        dbClose(db);
        return;
    }

    // Read count
    var count = dbReadInt32(db);

    // Read each warning
    for (var i = 0; i < count; i++) {
        var nick = dbReadStr(db);
        var warnCount = dbReadInt32(db);
        var reason = dbReadStr(db);
        var time = dbReadInt64(db);

        warnings[nick] = {
            count: warnCount,
            reason: reason,
            time: time
        };
    }

    dbClose(db);
    log('Loaded ' + count + ' warnings from database');
}

// Save warnings to disk
function saveWarnings() {
    var db = dbOpen(WARNINGS_FILE, DB_WRITE, null);
    if (db === null) {
        log('Error saving warnings: ' + dbGetError().message);
        return;
    }

    // Write version
    dbWriteInt16(db, WARNINGS_VERSION);

    // Count entries
    var keys = Object.keys(warnings);
    dbWriteInt32(db, keys.length);

    // Write each warning
    for (var i = 0; i < keys.length; i++) {
        var nick = keys[i];
        var warn = warnings[nick];

        dbWriteStr(db, nick);
        dbWriteInt32(db, warn.count);
        dbWriteStr(db, warn.reason);
        dbWriteInt64(db, warn.time);
    }

    if (!dbClose(db)) {
        log('Warning: database may not have saved properly');
    }
}

// Initialize
loadWarnings();

// Command to warn a user
registerCommand({
    name: 'WARN',
    handler: function() {
        if (!isOper($client)) {
            sendNotice($client, 'Permission denied');
            return 1;
        }

        if ($parc < 2) {
            sendNotice($client, 'Usage: /WARN <nick> <reason>');
            return 1;
        }

        var nick = $parv[0];
        var reason = $parv.slice(1).join(' ');

        if (!warnings[nick]) {
            warnings[nick] = { count: 0, reason: '', time: 0 };
        }

        warnings[nick].count++;
        warnings[nick].reason = reason;
        warnings[nick].time = Date.now();

        sendNotice($client, 'Warning #' + warnings[nick].count + ' issued to ' + nick);

        // Auto-save
        saveWarnings();

        return 1;
    }
});

// Command to check warnings
registerCommand({
    name: 'WARNINGS',
    handler: function() {
        if ($parc < 1) {
            sendNotice($client, 'Usage: /WARNINGS <nick>');
            return 1;
        }

        var nick = $parv[0];
        var warn = warnings[nick];

        if (!warn) {
            sendNotice($client, nick + ' has no warnings');
        } else {
            sendNotice($client, nick + ' has ' + warn.count + ' warning(s)');
            sendNotice($client, 'Last reason: ' + warn.reason);
        }

        return 1;
    }
});
```

---

## RPC API

Register custom JSON-RPC methods that can be called via UnrealIRCd's RPC interface.

### registerRPCMethod(config)
Register a new RPC method handler.

```javascript
registerRPCMethod({
    method: 'mybot.getStats',
    loglevel: 'debug',        // Optional: 'debug', 'info', 'warning', 'error'
    handler: function() {
        // $client = RPC caller
        // $params = RPC call parameters
        // $request = Full RPC request
        
        rpcResponse({
            success: true,
            users: getAllClients().length,
            channels: getAllChannels().length
        });
    }
});
```

### rpcResponse(result)
Send a successful RPC response. Only valid inside an RPC handler.

```javascript
registerRPCMethod({
    method: 'mybot.echo',
    handler: function() {
        rpcResponse({
            message: $params.text,
            from: $client.name
        });
    }
});
```

### rpcError(code, message)
Send an RPC error response. Only valid inside an RPC handler.

```javascript
registerRPCMethod({
    method: 'mybot.requireAuth',
    handler: function() {
        if (!$params.token) {
            rpcError(JSON_RPC_ERROR_INVALID_PARAMS, 'Missing token parameter');
            return;
        }
        rpcResponse({ success: true });
    }
});
```

### RPC Variables
Inside an RPC handler, these variables are available:

| Variable | Description |
|----------|-------------|
| `$client` | The RPC client making the request |
| `$params` | The parameters object from the RPC call |
| `$request` | The full JSON-RPC request object |

### RPC Error Codes
Standard JSON-RPC error codes are available as constants:

| Constant | Value | Description |
|----------|-------|-------------|
| `JSON_RPC_ERROR_PARSE_ERROR` | -32700 | JSON parse error |
| `JSON_RPC_ERROR_INVALID_REQUEST` | -32600 | Invalid request |
| `JSON_RPC_ERROR_METHOD_NOT_FOUND` | -32601 | Method not found |
| `JSON_RPC_ERROR_INVALID_PARAMS` | -32602 | Invalid parameters |
| `JSON_RPC_ERROR_INTERNAL_ERROR` | -32603 | Internal error |
| `JSON_RPC_ERROR_NOT_FOUND` | -1000 | Target not found |
| `JSON_RPC_ERROR_ALREADY_EXISTS` | -1001 | Resource exists |
| `JSON_RPC_ERROR_INVALID_NAME` | -1002 | Invalid name |
| `JSON_RPC_ERROR_DENIED` | -1005 | Permission denied |

---

## Extended Bans (Extbans)

Register custom extended ban types that can be used with channel modes +b, +e, +I.

### registerExtban(config)
Register a new extended ban type.

```javascript
registerExtban({
    letter: 'w',              // Single letter for the extban
    name: 'webchat',          // Name for ~webchat: syntax
    options: EXTBOPT_INVEX | EXTBOPT_TKL,  // Optional flags
    
    // Called to check if a user is banned (required)
    is_banned: function() {
        // $ban.client = User being checked
        // $ban.channel = Channel being checked
        // $ban.banstr = The part after ~w: (e.g., "yes" for ~w:yes)
        
        if ($ban.banstr === 'yes') {
            // Ban webchat users (those with realname containing "webchat")
            return $ban.client.info.toLowerCase().indexOf('webchat') !== -1;
        }
        return false;
    },
    
    // Called to validate/convert ban parameters (optional)
    conv_param: function() {
        // $ban.banstr = Raw parameter entered by user
        // Return the normalized parameter, or null to reject
        
        var param = $ban.banstr.toLowerCase();
        if (param === 'yes' || param === 'no') {
            return param;
        }
        return null;  // Reject invalid parameter
    },
    
    // Called to validate if the ban is allowed (optional)
    is_ok: function() {
        // $ban.client = User setting the ban
        // $ban.banstr = Ban parameter
        // Return true to allow, false to deny
        return true;
    }
});
```

### Extban Variables
Inside extban callbacks, the `$ban` object is available:

| Property | Description |
|----------|-------------|
| `$ban.client` | The user being checked (is_banned) or setting the ban (is_ok) |
| `$ban.channel` | The channel involved |
| `$ban.banstr` | The ban parameter (part after ~letter:) |
| `$ban.checkType` | Type of ban check being performed |
| `$ban.isCheck` | Boolean for is_ok validation mode |

### Extban Option Flags
Combine with `|` operator:

| Constant | Description |
|----------|-------------|
| `EXTBOPT_ACTMODIFIER` | Action modifier (like ~quiet, not a matcher) |
| `EXTBOPT_NOSTACKCHILD` | Disallow stacking (e.g., ~n:~a:account) |
| `EXTBOPT_INVEX` | Can be used with +I (invite exception) |
| `EXTBOPT_TKL` | Can be used in server bans (G-line, etc.) |

### Example: Account Age Extban
```javascript
// Ban users whose accounts are newer than X days
// Usage: +b ~age:7 (ban accounts less than 7 days old)
registerExtban({
    letter: 'A',
    name: 'accountage',
    options: EXTBOPT_INVEX,
    
    is_banned: function() {
        if (!isLoggedIn($ban.client)) {
            return false;  // Not logged in, doesn't match
        }
        
        var days = parseInt($ban.banstr);
        if (isNaN(days)) return false;
        
        // This is a simplified example - real implementation would check account age
        // For demo, just check if account name length < days (silly but demonstrates concept)
        return $ban.client.account.length < days;
    },
    
    conv_param: function() {
        var days = parseInt($ban.banstr);
        if (isNaN(days) || days < 1 || days > 365) {
            return null;  // Invalid
        }
        return String(days);
    }
});
```

---

### registerMessageTag(config)

Registers a custom message tag handler, allowing scripts to define tags that can be attached to messages.

```javascript
registerMessageTag({
    name: '+draft/myapp',              // Tag name (must start with + for client tags)
    flags: MTAG_HANDLER_FLAGS_NO_CAP_NEEDED,  // Optional: allow without CAP negotiation
    is_ok: function() {                // Optional: validate if client can send this tag
        // Return true to accept the tag, false to reject
        return true;
    }
});
```

**Parameters**:
- `name` (string, required): The tag name. Client-only tags should start with `+` (e.g., `+draft/myapp`).
- `flags` (number, optional): Handler flags:
  - `MTAG_HANDLER_FLAGS_NO_CAP_NEEDED` (1): Allow tag without CAP negotiation
- `is_ok` (function, optional): Validates whether a client can send this tag. Variables available:
  - `$client`: The client trying to send the tag
  - `$tagName`: The tag name
  - `$tagValue`: The tag value (may be empty string)
  - Return `true` to accept, `false` to reject

**Returns**: `true` on success, `false` on failure

**Note**: The `should_send_to_client` callback is not supported because the underlying API doesn't provide the tag name to the callback, making it impossible to identify which handler should process the call.

**Example - Simple Custom Tag**:

```javascript
// Register a tag that any authenticated user can send
registerMessageTag({
    name: '+draft/mood',
    flags: MTAG_HANDLER_FLAGS_NO_CAP_NEEDED,
    is_ok: function() {
        // Only logged-in users can set their mood
        if (!isLoggedIn($client)) {
            return false;
        }
        // Validate mood value
        var validMoods = ['happy', 'sad', 'excited', 'tired'];
        return validMoods.indexOf($tagValue) >= 0;
    }
});

// Usage with sendto:
// sendto('PRIVMSG', client, target, message, { '+draft/mood': 'happy' });
```

**Example - Application Identifier Tag**:

```javascript
// Tag to identify messages from specific applications
registerMessageTag({
    name: '+draft/app-id',
    flags: MTAG_HANDLER_FLAGS_NO_CAP_NEEDED,
    is_ok: function() {
        // Everyone can tag their messages with an app identifier
        // Just validate it's a reasonable length
        return $tagValue.length > 0 && $tagValue.length <= 32;
    }
});
```

---

## Configuration Blocks

### registerConfigBlock(config)

Registers a custom configuration block handler, allowing scripts to define and read their own config blocks from unrealircd.conf.

```javascript
registerConfigBlock({
    name: 'mymodule',         // Block name in config file
    test: function() {        // Validation during config test
        // Return true if valid, false if invalid
        return true;
    },
    run: function() {         // Called when config is loaded/rehashed
        // Read and apply configuration
        return true;
    }
});
```

**Parameters**:
- `name` (string, required): The configuration block name (e.g., `mymodule` for a `mymodule { }` block)
- `test` (function, optional): Validation handler called during `./unrealircd configtest`. Should return `true` if config is valid, `false` if invalid.
- `run` (function, optional): Handler called when configuration is loaded or rehashed. Reads and applies the configuration.

**Variables available in test/run handlers**:
- `$config`: ConfigEntry object with properties:
  - `name`: Block or directive name
  - `value`: Value (for simple directives)
  - `items`: Array of child ConfigEntry objects
  - `file`: Filename where this config appears
  - `line`: Line number in config file
- `$configFile`: Current config filename (for error reporting)
- `$configLine`: Current line number (for error reporting)

**Config error/warning functions**:
- `config_error(message)`: Report a configuration error (will fail config test)
- `config_warn(message)`: Report a configuration warning

**Returns**: `true` on success, `false` on failure

**Example - Simple Settings Block**:

```javascript
// Configuration example in unrealircd.conf:
// mybot {
//     nickname "BotNick";
//     channel "#help";
//     trigger "!";
// }

var botConfig = {
    nickname: 'DefaultBot',
    channel: '#lobby',
    trigger: '!'
};

registerConfigBlock({
    name: 'mybot',
    
    test: function() {
        // Validate the configuration
        for (var i = 0; i < $config.items.length; i++) {
            var item = $config.items[i];
            
            if (item.name === 'nickname') {
                if (!item.value || item.value.length < 1) {
                    config_error('mybot::nickname must not be empty');
                    return false;
                }
            } else if (item.name === 'channel') {
                if (!item.value || item.value[0] !== '#') {
                    config_error('mybot::channel must start with #');
                    return false;
                }
            } else if (item.name === 'trigger') {
                if (!item.value || item.value.length !== 1) {
                    config_error('mybot::trigger must be a single character');
                    return false;
                }
            } else {
                config_warn('Unknown directive: mybot::' + item.name);
            }
        }
        return true;
    },
    
    run: function() {
        // Read and apply configuration
        for (var i = 0; i < $config.items.length; i++) {
            var item = $config.items[i];
            
            if (item.name === 'nickname') {
                botConfig.nickname = item.value;
            } else if (item.name === 'channel') {
                botConfig.channel = item.value;
            } else if (item.name === 'trigger') {
                botConfig.trigger = item.value;
            }
        }
        
        log('Bot configured: ' + botConfig.nickname + ' in ' + botConfig.channel);
        return true;
    }
});
```

**Example - Nested Configuration**:

```javascript
// Configuration example in unrealircd.conf:
// quotes {
//     category "funny" {
//         quote "Why do programmers prefer dark mode? Light attracts bugs!";
//         quote "There are 10 types of people...";
//     }
//     category "wisdom" {
//         quote "Code never lies, comments sometimes do.";
//     }
// }

var quotes = {};

registerConfigBlock({
    name: 'quotes',
    
    test: function() {
        for (var i = 0; i < $config.items.length; i++) {
            var cat = $config.items[i];
            
            if (cat.name !== 'category') {
                config_error('quotes only supports category blocks');
                return false;
            }
            
            if (!cat.value) {
                config_error('category must have a name');
                return false;
            }
            
            if (!cat.items || cat.items.length === 0) {
                config_error('category ' + cat.value + ' has no quotes');
                return false;
            }
        }
        return true;
    },
    
    run: function() {
        quotes = {};
        
        for (var i = 0; i < $config.items.length; i++) {
            var cat = $config.items[i];
            var categoryName = cat.value;
            quotes[categoryName] = [];
            
            for (var j = 0; j < cat.items.length; j++) {
                var quote = cat.items[j];
                if (quote.name === 'quote' && quote.value) {
                    quotes[categoryName].push(quote.value);
                }
            }
        }
        
        log('Loaded quotes in ' + Object.keys(quotes).length + ' categories');
        return true;
    }
});
```

---

## Available Hooks

### Connection Hooks

#### HOOKTYPE_LOCAL_CONNECT
Called when a local user connects (completes registration).

**Variables**: `$client`

```javascript
registerHook({
    type: HOOKTYPE_LOCAL_CONNECT,
    handler: function() {
        sendNotice($client, 'Welcome, ' + $client.name + '!');
        return 0;
    }
});
```

#### HOOKTYPE_REMOTE_CONNECT
Called when a remote user connects (from another server).

**Variables**: `$client`

#### HOOKTYPE_LOCAL_QUIT
Called when a local user disconnects.

**Variables**: `$client`, `$reason`

```javascript
registerHook({
    type: HOOKTYPE_LOCAL_QUIT,
    handler: function() {
        log($client.name + ' quit: ' + $reason);
        return 0;
    }
});
```

#### HOOKTYPE_REMOTE_QUIT
Called when a remote user disconnects.

**Variables**: `$client`, `$reason`

---

### Channel Hooks

#### HOOKTYPE_LOCAL_JOIN
Called when a local user joins a channel.

**Variables**: `$client`, `$channel`

```javascript
registerHook({
    type: HOOKTYPE_LOCAL_JOIN,
    handler: function() {
        log($client.name + ' joined ' + $channel.name);
        return 0;
    }
});
```

#### HOOKTYPE_REMOTE_JOIN
Called when a remote user joins a channel.

**Variables**: `$client`, `$channel`

#### HOOKTYPE_LOCAL_PART
Called when a local user parts a channel.

**Variables**: `$client`, `$channel`, `$reason`

```javascript
registerHook({
    type: HOOKTYPE_LOCAL_PART,
    handler: function() {
        log($client.name + ' left ' + $channel.name + ': ' + $reason);
        return 0;
    }
});
```

#### HOOKTYPE_REMOTE_PART
Called when a remote user parts a channel.

**Variables**: `$client`, `$channel`, `$reason`

#### HOOKTYPE_LOCAL_KICK
Called when a local user is kicked.

**Variables**: `$client` (kicker), `$victim`, `$channel`, `$reason`

```javascript
registerHook({
    type: HOOKTYPE_LOCAL_KICK,
    handler: function() {
        log($client.name + ' kicked ' + $victim.name + ' from ' + $channel.name);
        return 0;
    }
});
```

#### HOOKTYPE_REMOTE_KICK
Called when a remote user is kicked.

**Variables**: `$client` (kicker), `$victim`, `$channel`, `$reason`

#### HOOKTYPE_CHANNEL_CREATE
Called when a channel is created.

**Variables**: `$channel`

#### HOOKTYPE_CHANNEL_DESTROY
Called when a channel is destroyed (last user left).

**Variables**: `$channel`

---

### Message Hooks

#### HOOKTYPE_CHANMSG
Called when a message is sent to a channel.

**Variables**: `$client`, `$channel`, `$text`, `$target`, `$sendtype`, `$isPrivmsg`, `$isNotice`

```javascript
registerHook({
    type: HOOKTYPE_CHANMSG,
    handler: function() {
        if ($isPrivmsg && $text.indexOf('!hello') === 0) {
            sendNotice($client, 'Hello to you too!');
        }
        return 0;
    }
});
```

#### HOOKTYPE_USERMSG
Called when a private message is sent between users.

**Variables**: `$client` (sender), `$target` (recipient client object), `$text`, `$sendtype`, `$isPrivmsg`, `$isNotice`

```javascript
registerHook({
    type: HOOKTYPE_USERMSG,
    handler: function() {
        log('PM from ' + $client.name + ' to ' + $target.name + ': ' + $text);
        return 0;
    }
});
```

---

### Nick/User Hooks

#### HOOKTYPE_LOCAL_NICKCHANGE
Called when a local user changes their nick.

**Variables**: `$client`, `$newnick`

```javascript
registerHook({
    type: HOOKTYPE_LOCAL_NICKCHANGE,
    handler: function() {
        log($client.name + ' changed nick to ' + $newnick);
        return 0;
    }
});
```

#### HOOKTYPE_REMOTE_NICKCHANGE
Called when a remote user changes their nick.

**Variables**: `$client`, `$newnick`

---

### Topic Hook

#### HOOKTYPE_TOPIC
Called when a channel topic is changed.

**Variables**: `$client`, `$channel`, `$topic`

```javascript
registerHook({
    type: HOOKTYPE_TOPIC,
    handler: function() {
        log($client.name + ' set topic of ' + $channel.name + ' to: ' + $topic);
        return 0;
    }
});
```

---

### Away Hook

#### HOOKTYPE_AWAY
Called when a user sets or unsets away status.

**Variables**: `$client`, `$reason` (null if returning), `$isAway`, `$wasAlreadyAway`

```javascript
registerHook({
    type: HOOKTYPE_AWAY,
    handler: function() {
        if ($isAway) {
            log($client.name + ' is now away: ' + $reason);
        } else {
            log($client.name + ' is no longer away');
        }
        return 0;
    }
});
```

---

### Oper Hook

#### HOOKTYPE_LOCAL_OPER
Called when a user becomes (or stops being) an IRC operator.

**Variables**: `$client`, `$isOper` (boolean), `$operBlock`, `$operClass`

```javascript
registerHook({
    type: HOOKTYPE_LOCAL_OPER,
    handler: function() {
        if ($isOper) {
            log($client.name + ' is now IRCOp (class: ' + $operClass + ')');
        } else {
            log($client.name + ' is no longer IRCOp');
        }
        return 0;
    }
});
```

---

## Complete Example Script

```javascript
/*
 * example.js - Feature-rich example script
 */

// ===== COMMANDS =====

// Simple info command
registerCommand({
    name: 'JSINFO',
    handler: function() {
        sendNotice($client, '*** UnrealIRCd JavaScript Module v1.0');
        sendNotice($client, '*** Powered by Duktape JavaScript Engine');
        sendNotice($client, '*** Your nick: ' + $client.name);
        sendNotice($client, '*** Your IP: ' + $client.ip);
        if ($client.account) {
            sendNotice($client, '*** Logged in as: ' + $client.account);
        }
        return 1;
    }
});

// Dice roll command
registerCommand({
    name: 'DICE',
    handler: function() {
        var sides = 6;
        if ($parc > 0) {
            sides = parseInt($parv[0]) || 6;
            if (sides < 2) sides = 2;
            if (sides > 100) sides = 100;
        }
        var roll = Math.floor(Math.random() * sides) + 1;
        sendNotice($client, '🎲 You rolled a ' + roll + ' (d' + sides + ')');
        return 1;
    }
});

// Weather lookup (requires API)
registerCommand({
    name: 'WEATHER',
    handler: function() {
        if ($parc < 1) {
            sendNotice($client, 'Usage: /WEATHER <city>');
            return 1;
        }
        var city = $parv.join(' ');
        var clientName = $client.name;
        
        httpGet('https://wttr.in/' + encodeURIComponent(city) + '?format=3', function(err, body) {
            var target = findClient(clientName);
            if (!target) return;
            
            if (err) {
                sendNotice(target, 'Weather error: ' + err);
            } else {
                sendNotice(target, '🌤️ ' + body.trim());
            }
        });
        return 1;
    }
});

// ===== HOOKS =====

// Greet new users
registerHook({
    type: HOOKTYPE_LOCAL_CONNECT,
    handler: function() {
        sendNotice($client, '*** Welcome to the network, ' + $client.name + '!');
        log('New connection: ' + $client.name + ' from ' + $client.ip);
        return 0;
    }
});

// Log channel messages containing certain words
registerHook({
    type: HOOKTYPE_CHANMSG,
    handler: function() {
        if ($text.toLowerCase().indexOf('help') !== -1) {
            log('Help request in ' + $channel.name + ' by ' + $client.name + ': ' + $text);
        }
        return 0;
    }
});

// ===== TIMERS =====

// Periodic server stats log
var statsTimer = setInterval(function() {
    log('Periodic stats check running...');
}, 300000); // Every 5 minutes

// One-time startup message
setTimeout(function() {
    log('JavaScript module fully initialized!');
}, 5000);

log('example.js loaded successfully!');
```

---

## Tips & Best Practices

1. **Async callbacks**: When using `httpGet`, the client may disconnect before the callback runs. Always use `findClient()` to verify the client still exists.

2. **Error handling**: Wrap JSON parsing in try/catch blocks.

3. **Timer cleanup**: Clear intervals when no longer needed to prevent resource leaks.

4. **Return values**: Hook handlers should return `0` to continue normal processing. Commands should return `1`.

5. **Logging**: Use `log()` for debugging during development.

6. **Parameter validation**: Always check `$parc` before accessing `$parv` elements.

---

## Troubleshooting

**Scripts not loading?**
- Check that files have `.js` extension
- Check file permissions
- Check UnrealIRCd log for errors

**Commands not working?**
- Commands are case-insensitive but registered uppercase
- Use `/COMMAND` without slash prefix in the name

**HTTP requests failing?**
- Check network connectivity
- Some APIs require HTTPS
- Check for firewall issues

**Timer not firing?**
- Minimum interval is 100ms (setInterval) or 10ms (setTimeout)
- Make sure timer ID wasn't cleared

---

## License

GPLv3 or later

## Author

Valerie - v.a.pond@outlook.com
