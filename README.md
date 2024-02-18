# Description
Tempo is an online Flash-based music player, built to allow for a fully customizable interface. It is even capable of changing skins on the fly. Skinning is handled by making a simple SWF with movieclips with specific names. Tempo will look to see if the buttons exist, and if so, will assign actions to them. You can make a skin as simple as the Demo in minutes, or you can take the time to build one as unique as the Winamp skin. Tempo currently supports the following file types: flv, mp4, m4v, m4a, 3gp, mov, f4v, f4p, f4a, f4b, and mp3.

# Competitors
This is a list of other known Flash media players currently out. While some media players may seem fancy or elaborate, Tempo's goal is to be small, efficient and configurable. Below is a list of comparable players with similar capabilities and file sizes:
- AFComponents Embeddable FLV Player : 120kb
- Wimpy RAVE 2.0.7 : 109kb (Not Free)
- Wimpy MP3 6.0.15 : 64kb (Not Free)
- YouTube Player : 76kb
- JW Media Player 4.1 : 40kb
- Flowplayer 2.2.4 : 120kb
- TSVideo 1.0 : 115kb (Not free)
- MC Classic Media Player : 120kb
- MC Altair 0.8 : 33kb (Single file, no playlist)
- Tempo : 25kb

# Usage
## Item Object
An item object is used for handling a single item. You pass an item object to add audio or video to the play list. When you try to retrieve audio or video from the play list, it is returned as an item object. Below is the format of an item object :

```javascript
{title: "My Song", length: "100", url: "mySong.mp3", extOverride: "m4a"}
```

If no title is passed, it will be set to "". If no length is passed, it will be set to -1. If extOverride isn't passed, Tempo will get that last three letters of the file name to guess the file format.

## Support Video Formats
Below is a list of the supported video formats. This is basically a run down of the videos Flash can play.
- flv
- mp4
- m4v
- 3gp
- mov
- f4v
- f4p
- f4b

## Support Audio Formats
Below is a list of the supported audio formats, this is basically a run down of the sounds Flash can play.
- m4a
- f4a
- mp3

## Support Playlist Formats
You can pass the following playlist file types to Tempo. For each file type (if XML based) is a list of the corresponding tags as they relate to the Item Object described above.
- ASX
  - `<title>` = Title
  - `<ref>` or `<base>` = URL
  - `<duration>` = Length
  - Example
- XSPF
  - `<title>` = Title
  - `<location>` = URL
  - `<duration>` = Length
  - Example
- M3U
  - Example
- PLS
  - `<title>` = Title
  - `<media:group><media:content url="value">` = URL
  - `<duration>` = Length
  - [Spec](http://code.google.com/apis/youtube/developers_guide_protocol.html#Understanding_Video_Entries)

# Javascript API
## Methods
- `play()` - Plays selected item in the playlist 
- `playpause()` - Toggles between play and pause 
- `pause()` - Pauses selected item in the playlist 
- `stop()` - Stops the selected item in the playlist 
- `next()` - Plays the next item in the playlist 
- `prev()` - Plays the previous item in the playlist 
- `playItem(index:Number)` - Plays specified item in the playlist 
- `loadFile(item:Object, autoStart:Boolean = true)` - Creates a playlist of a single item and load the item 
- `loadSkin(url:String = "DefaultSkin.swf")` - Loads a new skin 
- `loadPlayList(url:String = "playlists/Tempo.m3u")` - Loads a new playlist 
- `addItem(item:Object, index:Number = undefined)` - Adds an item to the playlist at the end, or at index specified 
- `removetem(index:Number = undefined)` - Removes an item from the playlist from the end, or at index specified 
- `clearItems()` - Clears the playlist 
- `mute(b:Boolean)` - Turns audio off or on 

## Properties
- `setId : Number` / `getId : Number` - A unique id for this specific player. Useful where more than one player is on the page (default "1") 
- `setRepeat : Boolean` / `getRepeat : Boolean` - Whether to loop the playlist (false) or a single item (true) (default false) 
- `setShuffle : Boolean` / `getShuffle : Boolean` - Whether to shuffle the playlist or not (default false) 
- `setVolume : Number` / `getVolume : Number` - A number from 0 to 1 determines volume (default 0.5) 
- `setSeekPercent : Number` / `getSeekPercent : Number` - Current play percentage through item 
- `getItemData : Object` - Returns current playlist item object 
- `getItemIndex : Number` - Returns current playlist item index 
- `getLength : Number` - Returns number of items in playlist 
- `getLoadPercent : Number` - Returns the load percentage 
- `getTimeElapsed : Number` - Returns current play time, in 00:00 format 
- `getTimeRemaining : Number` - Returns current remaining play time, in 00:00 format 
- `getObjectID : String` - Returns unique SWF object ID in the html 

## Events
- `onPlay` - Dispatched when item begins playing 
- `onMetaData : Object` - Dispatched when metadata for current item is retrieved. Passes metadata as an object. 
- `onPlayProgress : Object` - Dispatches when play progress is updated. 
    ```javascript
	{percent:currentPercent, elapsed:timeCurrent, remain:timeLeft, total:timeTotal}
	```
    percent : Current play percentage through item
    elapsed : Current play time, in 00:00 format
    remain : Current remaining play time, in 00:00 format
    total : Total length of item, in 00:00 format
- `onPlayComplete : Void` - Dispatched when item has finished playing 
- `onLoad : Object` - Dispatched when a new item has begun to load.
    ```javascript
	{url:strURL, type:"audio", time:timeTotal}
	```
    url : URL of item loading 
    type : Either "audio" or "video" 
    time : Elapsed play time 
- `onLoadProgress` - Dispatches when load progress is updated. 
    ```javascript
	{loaded:bytesLoaded, total:bytesTotal}
	```
    loaded : Current bytes loaded 
    total : Bytes to load 
- `onVolume : Number` - Dispatched when the volume has changed. Passes the new volume setting. 
- `onShuffle : Boolean` - Dispatched when the shuffle setting has changed. Pass the new shuffle setting. 
- `onRepeat : Boolean` - Dispatched when the repeat setting has changed. Pass the new repeat setting. 

## Flashvars API
- `autoStart : Boolean` - Determines if the player will immediately play the first item (default true) 
- `autoStartIndex : Number` - The index of an item in the playlist to play if 'autoStart' is set to true (default 0) 
- `bufferTime : Number` - Seconds to pre-buffer before playing an item (default 1) 
- `fileURL : String` - The URL to an item to play, will create a playlist consisting on this single item 
- `playerId : String` - A unique id for this specific player. Useful where more than one player is on the page (default "1") 
- `playlistURL : String` - The URL of the playlist to load (default "playlists/Tempo.m3u") 
- `repeat : Boolean` - Whether to loop the playlist (false) or a single item (true) (default false) 
- `shuffle : Boolean` - Whether to shuffle the playlist or not (default false) 
- `skinURL : String` - The URL to the skin to load (default "DefaultSkin.swf") 
- `volume : Number` - A number from 0 to 1 determines volume (default 0.5) 
