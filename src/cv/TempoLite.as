/**
* TempoLite ©2009 Gabriel Mariani. March 30th, 2009
* Visit http://blog.coursevector.com/tempolite for documentation, updates and more free code.
*
*
* Copyright (c) 2009 Gabriel Mariani
* 
* Permission is hereby granted, free of charge, to any person
* obtaining a copy of this software and associated documentation
* files (the "Software"), to deal in the Software without
* restriction, including without limitation the rights to use,
* copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the
* Software is furnished to do so, subject to the following
* conditions:
* 
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
* OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
* HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
* OTHER DEALINGS IN THE SOFTWARE.
**/

package cv {

	import cv.data.MediaError;
	import cv.data.NetworkState;
	import cv.data.ReadyState;
	import cv.events.LoadEvent;
	import cv.events.MetaDataEvent;
	import cv.events.PlayProgressEvent;
	import cv.events.TempoEvent;
	import cv.interfaces.IMediaPlayer;
	import cv.util.MathUtil;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	//--------------------------------------
    //  Events
    //--------------------------------------
	
	/**
	 * Dispatched from the PlayList when a change has occured
	 *
	 * @eventType flash.events.Event.CHANGE
	 */
	[Event(name = "change", type = "flash.events.Event")]
	
	/**
	 * Dispatched everytime a cue point is encountered
	 *
	 * @eventType cv.events.MetaDataEvent.CUE_POINT
	 */
	[Event(name = "cuePoint", type = "cv.events.MetaDataEvent")]
	
	/**
	 * Dispatched as a media file has completed loading
	 *
	 * @eventType cv.events.LoadEvent.LOAD_COMPLETE
	 */
	[Event(name = "loadComplete", type = "cv.events.LoadEvent")]
	
	/**
	 * Dispatched as a media file is loaded
	 *
	 * @eventType cv.events.LoadEvent.LOAD_PROGRESS
	 */
	[Event(name = "loadProgress", type = "flash.events.ProgressEvent")]
	
	/**
	 * Dispatched as a media file begins loading
	 *
	 * @eventType cv.events.LoadEvent.LOAD_START
	 */
	[Event(name = "loadStart", type = "cv.events.LoadEvent")]
	
	/**
	 * Dispatched after Tempo has begun loading the next item, also at the end of an item playing
	 *
	 * @eventType cv.TempoLite.NEXT
	 */
	[Event(name = "next", type = "flash.events.Event")]
	
	/**
	 * Dispatched as a media file finishes playing
	 *
	 * @eventType flash.events.ProgressEvent.PLAY_COMPLETE
	 */
	[Event(name = "playComplete", type = "flash.events.Event")]
	
	/**
	 * Dispatched as a media file is playing
	 *
	 * @eventType cv.events.PlayProgressEvent.PLAY_PROGRESS
	 */
	[Event(name="playProgress", type="cv.events.PlayProgressEvent")]
	
	/**
	 * Dispatched once as a media file first begins to play
	 *
	 * @eventType cv.TempoLite.PLAY_START
	 */
	[Event(name = "playStart", type = "flash.events.Event")]
	
	/**
	 * Dispatched after Tempo has begun loading the previous item
	 *
	 * @eventType cv.TempoLite.PREVIOUS
	 */
	[Event(name = "previous", type = "flash.events.Event")]
	
	/**
	 * Dispatched from the PlayListManager when ever an item is removed, or updated, or the entire list is updated
	 *
	 * @eventType cv.TempoLite.REFRESH_PLAYLIST
	 */
	[Event(name = "refreshPlaylist", type = "flash.events.Event")]
	
	/**
	 * Dispatched whenever the isPlaying, isReadyToPlay or isPause properties have changed.
	 *
	 * @eventType cv.events.PlayProgressEvent.STATUS
	 */
	[Event(name = "status", type = "flash.events.PlayProgressEvent")]
	
	/**
	 * Dispatched as metadata is receieved from a player
	 *
	 * @eventType cv.events.MetaDataEvent.METADATA
	 */
	[Event(name = "metadata", type = "cv.events.MetaDataEvent")]
	
	/**
	 * Dispatched whenever the volume has changed
	 *
	 * @eventType cv.TempoLite.VOLUME
	 */
	[Event(name = "volume", type = "flash.events.Event")]
	
	//--------------------------------------
    //  Class description
    //--------------------------------------	
    /**
	 * <h3>Version:</h3> 3.0.5<br>
	 * <h3>Date:</h3> 5/04/2009<br>
	 * <h3>Updates At:</h3> http://blog.coursevector.com/tempolite<br>
	 * <br>
	 * TempoLite is based off of its sister project Tempo this is a parsed down version that 
	 * does not handle a UI. TempoLite is best compared with players like video.Maru, in 
	 * the sense that it’s just a component that is dragged on stage and handles all of 
	 * the media playback. This allows for a UI as complicated as you want to make it while 
	 * the actually playback is handled by TempoLite.
	 * <br>
	 * <br>
	 * <h3>Coded By:</h3> Gabriel Mariani, gabriel[at]coursevector.com<br>
	 * Copyright 2009, Course Vector (This work is subject to the terms in http://blog.coursevector.com/terms.)<br>
	 * <br>
	 * <h3>Notes:</h3>
	 * <ul>
	 * 		<li>This class will add about 15kb to your Flash file.</li>
	 * </ul>
	 * <hr>
	 * <ul>
	 * <li>3.1.0
	 * <ul>
	 * 		<li>Added volume event</li>
	 * </ul>
	 * </li>
	 * <li>3.0.5
	 * <ul>
	 * 		<li>Updated NetStreamPlayer to 3.0.5</li>
	 * 		<li>Updated SoundPlayer to 3.0.5</li>
	 * 		<li>Updated ImagePlayer to 1.0.4</li>
	 * </ul>
	 * </li>
	 * <li>3.0.4
	 * <ul>
	 * 		<li>Updated NetStreamPlayer to 3.0.4</li>
	 * 		<li>Updated SoundPlayer to 3.0.4</li>
	 * 		<li>Updated ImagePlayer to 1.0.3</li>
	 * 		<li>currentPercent is now a number from 0 - 1</li>
	 * 		<li>seekPercent is now accepts a number from 0 - 1</li>
	 * </ul>
	 * </li>
	 * <li>3.0.3
	 * <ul>
	 * 		<li>Updated NetStreamPlayer to 3.0.3</li>
	 * </ul>
	 * </li>
	 * <li>3.0.2
	 * <ul>
	 * 		<li>Changed loadCurrent and loadTotal to uint</li>
	 * </ul>
	 * </li>
	 * <li>3.0.1
	 * <ul>
	 * 		<li>load() and seek() are now typed to *. </li>
	 * </ul>
	 * </li>
	 * <li>3.0.0
	 * <ul>
	 * 		<li>Changed unloadMedia() to just unload()</li>
	 * 		<li>Changed bufferTime to just buffer</li>
	 * </ul>
	 * </li>
	 * </ul>
	 * 
	 * @example This is the same code as in the TempoLiteDemo.fla
	 * <br/><br/>
	 * <listing version="3.0">
	 * import cv.TempoLite;
	 * import cv.media.SoundPlayer;
	 * import cv.media.NetStreamPlayer;
	 * import cv.media.RTMPPlayer;
	 * import cv.media.ImagePlayer;
	 * import flash.events.Event;
	 * import cv.events.LoadEvent;
	 * import cv.events.PlayProgressEvent;
	 * import cv.events.MetaDataEvent;
	 * import cv.formats.*;
	 * 
	 * var tempo:TempoLite = new TempoLite(null, [ASX, ATOM, B4S, M3U, PLS, XSPF]);
	 * tempo.debug = true;
	 * 
	 * var nsP:NetStreamPlayer = new NetStreamPlayer();
	 * nsP.video = vidScreen;
	 * tempo.addPlayer(nsP);
	 * nsP.debug = true;
	 * 
	 * var sndP:SoundPlayer = new SoundPlayer();
	 * sndP.debug = true;
	 * tempo.addPlayer(sndP);
	 * 
	 * var imgP:ImagePlayer = new ImagePlayer();
	 * this.addChildAt(imgP, 0);
	 * imgP.debug = true;
	 * tempo.addPlayer(imgP);
	 * 
	 * var rtP:RTMPPlayer = new RTMPPlayer();
	 * rtP.streamHost = "rtmp://cp34534.edgefcs.net/ondemand";
	 * //rtP.video = vidScreen;
	 * //rtP.debug = true;
	 * //tempo.addPlayer(rtP);
	 * 
	 * //tempo.load("images/2_1600.jpg");
	 * //tempo.load({url:"34548/PodcastIntro", extOverride:"flv"});
	 * //tempo.load("music/01 Sunrise Projector.mp3");
	 * //tempo.loadPlayList("playlists/xspf_example.xml");
	 * //tempo.loadPlayList("playlists/pls_example.pls");
	 * //tempo.loadPlayList("playlists/m3u_example.m3u");
	 * //tempo.loadPlayList("playlists/b4s_example.b4s");
	 * //tempo.loadPlayList("playlists/asx_example.xml");
	 * tempo.loadPlayList("playlists/atom_example.xml");
	 * </listing>
     */
	
    public class TempoLite extends EventDispatcher implements IMediaPlayer {
		
		/**
         * The current version of TempoLite in use.
		 */
		public static const VERSION:String = "4.0.0";
		
		/**
		 * Enables/Disables debug traces
		 */
		public var debug:Boolean = false;
		
		// Private
		protected var _autoPlay:Boolean = false;
		protected var _buffer:int = 0;
		protected var _cM:IMediaPlayer;
		protected var _players:Array = new Array();
		protected var _loop:Boolean = false;
		protected var _volume:Number = 1;
		protected var _muted:Boolean = false;
		protected var _paused:Boolean = false;
		
		/**
		 * Constructor. 
		 * 
		 * This creates a new TempoLite instance.
		 * 
		 * @param	players An array of players to use with TempoLite
		 */
		public function TempoLite(players:Array = null) {
			trace2("Course Vector TempoLite: v" + VERSION);
			
			var i:int = players ? players.length : 0;
			while (i--) {
				addPlayer(players[i]);
			}
			
			// Set current media manager
			if (_players[0]) _cM = _players[0];
		}
		
		//--------------------------------------
		// IMediaPlayer Properties
		//--------------------------------------
		
		public function get autoPlay():Boolean { return _autoPlay; }
		/** @private **/
		public function set autoPlay(b:Boolean):void {
			_autoPlay = b;
			setPlayersProp("autoPlay", _autoPlay);
		}
		
		public function get buffer():int { return _buffer; }
		/** @private **/
		public function set buffer(n:int):void {
			_buffer = n;
			setPlayersProp("buffer", _buffer);
		}
		
		public function get currentSrc():String { return _cM ? _cM.currentSrc : ''; }
		
		public function get currentTime():Number { return _cM ? _cM.currentTime : 0 }
		/** @private **/
		public function set currentTime(n:Number):void { if (_cM) _cM.currentTime = n; }
		
		public function get duration():Number { return _cM ? _cM.duration : 0; }
		
		public function get ended():Boolean { return _cM ? _cM.ended : false; }
		
		public function get error():MediaError { return _cM ? _cM.error : null; }
		
		public function get loop():Boolean { return _loop; }
		/** @private **/
		public function set loop(b:Boolean):void {
			_loop = b;
			setPlayersProp("loop", _loop);
		}
		
		public function get muted():Boolean { return _muted; }
		/** @private **/
		public function set muted(b:Boolean):void {
			_muted = b;
			setPlayersProp("muted", _muted);
		}
		
		public function get networkState():uint { return _cM ? _cM.networkState : NetworkState.NETWORK_EMPTY;	}
		
		/** 
		 * If TempoLite is currently paused.
		 */
		public function get paused():Boolean { return _cM ? _cM.paused : true }
		
		/**
		 *  Provides a hint to the user agent about what the author thinks will lead to the 
		 * best user experience. The attribute may be ignored altogether, for example based 
		 * on explicit user preferences or based on the available connectivity.
		 */
		// preload
		
		public function get readyState():uint {	return _cM ? _cM.readyState : ReadyState.HAVE_NOTHING }
		
		public function get seeking():Boolean { return _cM ? _cM.seeking : false }
		
		public function get src():String {	return _cM ? _cM.src : ''; }
		/** @private **/
		public function set src(str:String):void { if (_cM) _cM.src = str; }
		
		/**
		 * Retrieve the current bytes loaded of the current item.
		 */
		public function get bytesLoaded():uint { return _cM ? _cM.bytesLoaded : 0 }
		
		/**
		 * Retrieve the total bytes to load of the current item.
		 */
		public function get bytesTotal():uint {	return _cM ? _cM.bytesTotal : 0 }
		
		/** 
		 * A number from 0 to 1 determines volume.
		 *
		 * @default 1
		 */
		public function get volume():Number { return _muted ? 0 : _volume }
		/** @private **/
		public function set volume(v:Number):void {
			_volume = MathUtil.clamp(0, 1, v);
			setPlayersProp("volume", _volume);
		}
		
		/**
		 * Retrieve the metadata from the current item playing if available.
		 */
		public function get metaData():Object { return _cM ? _cM.metaData : null }
		
		//--------------------------------------
		//  IMediaPlayer Methods
		//--------------------------------------
		
		public function canPlayType(type:String):Boolean {
			var canPlay:Boolean = false;
			var i:uint = _players.length;
			while (i--) {
				if (!canPlay) canPlay = _players[i].canPlayType(type);
				if (canPlay) return true;
			}
			
			return false;
		}
		
		/**
		 * Create a playlist of a single item and load the item.
		 * 
		 * @param item The url or the item object to be played.
		 */
		public function load():void {
			if (_cM) _cM.load();
		}
		
		/**
		 * Pauses the current playback.
		 * 
		 * @default true
		 * @param b Value to set pause to
		 */
		public function pause():void {
			if (_cM) _cM.pause();
		}
		
		/**
		 * Plays starting at the given position.
		 * 
		 * @default 0
		 * @param pos	Position to play from
		 */
		public function play():void {
			if (_cM) _cM.play();
		}
		
		//--------------------------------------
		// TempoLite Methods
		//--------------------------------------
		
		/**
		 * Adds a player for use by TempoLite. Which can enable TempoLite to
		 * handle more types of media.
		 * 
		 * @param	player	The player to add
		 */
		public function addPlayer(player:IMediaPlayer):uint {
			var f:Function = player.addEventListener;
			f(MetaDataEvent.METADATA, 			eventHandler, false, 0, true); //MetaDataEvent
			f(MetaDataEvent.CUE_POINT, 			eventHandler, false, 0, true);
			f(TempoEvent.ABORT, eventHandler, false, 0, true);
			f(TempoEvent.CAN_PLAY, eventHandler, false, 0, true);
			f(TempoEvent.CAN_PLAY_THROUGH, eventHandler, false, 0, true);
			f(TempoEvent.DURATION_CHANGE, eventHandler, false, 0, true);
			f(TempoEvent.EMPTIED, eventHandler, false, 0, true);
			f(TempoEvent.ENDED, eventHandler, false, 0, true);
			f(TempoEvent.ERROR, eventHandler, false, 0, true);
			f(TempoEvent.LOAD_START, eventHandler, false, 0, true);
			f(TempoEvent.LOADED_DATA, eventHandler, false, 0, true);
			f(TempoEvent.LOADED_METADATA, eventHandler, false, 0, true);
			f(TempoEvent.PAUSE, eventHandler, false, 0, true);
			f(TempoEvent.PLAY, eventHandler, false, 0, true);
			f(TempoEvent.PLAYING, eventHandler, false, 0, true);
			f(TempoEvent.PROGRESS, eventHandler, false, 0, true);
			f(TempoEvent.RATE_CHANGE, eventHandler, false, 0, true);
			f(TempoEvent.SEEKED, eventHandler, false, 0, true);
			f(TempoEvent.SEEKING, eventHandler, false, 0, true);
			f(TempoEvent.STALLED, eventHandler, false, 0, true);
			f(TempoEvent.SUSPEND, eventHandler, false, 0, true);
			f(TempoEvent.TIME_UPDATE, eventHandler, false, 0, true);
			f(TempoEvent.VOLUME_CHANGE, eventHandler, false, 0, true);
			f(TempoEvent.WAITING, eventHandler, false, 0, true);
			var index:uint = _players.push(player);
			
			if (_cM == null) _cM = _players[0];
			return index;
		}
		
		/**
		 * Remove a player from TempoLite.
		 * 
		 * @param	player	The player to be removed.
		 */
		public function removePlayer(player:IMediaPlayer):void {
			var i:uint = _players.length;
			while (i--) {
				if (_players[i] === player) {
					player.unload();
					var f:Function = player.removeEventListener;
					f(MetaDataEvent.METADATA, 			eventHandler); //MetaDataEvent
					f(MetaDataEvent.CUE_POINT, 			eventHandler);
					f(TempoEvent.ABORT, eventHandler);
					f(TempoEvent.CAN_PLAY, eventHandler);
					f(TempoEvent.CAN_PLAY_THROUGH, eventHandler);
					f(TempoEvent.DURATION_CHANGE, eventHandler);
					f(TempoEvent.EMPTIED, eventHandler);
					f(TempoEvent.ENDED, eventHandler);
					f(TempoEvent.ERROR, eventHandler);
					f(TempoEvent.LOAD_START, eventHandler);
					f(TempoEvent.LOADED_DATA, eventHandler);
					f(TempoEvent.LOADED_METADATA, eventHandler);
					f(TempoEvent.PAUSE, eventHandler);
					f(TempoEvent.PLAY, eventHandler);
					f(TempoEvent.PLAYING, eventHandler);
					f(TempoEvent.PROGRESS, eventHandler);
					f(TempoEvent.RATE_CHANGE, eventHandler);
					f(TempoEvent.SEEKED, eventHandler);
					f(TempoEvent.SEEKING, eventHandler);
					f(TempoEvent.STALLED, eventHandler);
					f(TempoEvent.SUSPEND, eventHandler);
					f(TempoEvent.TIME_UPDATE, eventHandler);
					f(TempoEvent.VOLUME_CHANGE, eventHandler);
					f(TempoEvent.WAITING, eventHandler);
					_players.splice(i, 1);
					if (_cM === player) _cM = _players[0] || null;
				}
			}
		}
		
		/**
		 * Converts a time in 00:00:000 format and converts it back into a number.
		 * 
		 * @param	text The string to convert
		 * @return The converted number
		 */
		public static function stringToTime(text:String):int {
            var arr:Array = text.split(":");
            var time:Number = 0;
            if (arr.length > 1) {
				// Milliseconds
                time = Number(arr[arr.length--]);
				// Seconds
				time += Number(arr[arr.length - 2]) * 60;
                if (arr.length == 3) {
					// Minutes
                    time += Number(arr[arr.length - 3]) * 3600;
                }
            } else {
                time = Number(text);
            }
            return int(time);
		}
		
		/**
		 * Converts milliseconds to a 00:00:000 format.
		 * 
		 * @param	n Milliseconds to convert
		 * @return The converted string
		 */
		public static function timeToString(n:int):String {
			var ms:int = int(n % 1000);
			var s:int = n / 1000;
			var m:int = int(s / 60);
			s = int(s % 60);
			return zero(m) + ":" + zero(s) + ":" + zero(ms, true);
		}
		
		public function unload():void {
			//
		}
		
		//--------------------------------------
		//  Private
		//--------------------------------------
		
		protected function callPlayersMethod(methodName:String, methodValue:* = null):void {
			var i:int = _players.length;
			while (i--) {
				if (methodValue != null) {
					_players[i][methodName](methodValue);
				} else {
					_players[i][methodName]();
				}
			}
		}
		
		protected function eventHandler(e:Event):void {
			dispatchEvent(e.clone());
		}
		
		protected function setPlayersProp(propName:String, propValue:*):void {
			var i:int = _players.length;
			while (i--) {
				_players[i][propName] = propValue;
			}
		}
		
		protected function trace2(...args):void {
			if (debug) trace(args);
		}
		
		protected static function zero(n:int, isMS:Boolean = false):String {
			if(isMS) {
				if(n < 10) return "00" + n;
				if(n < 100) return "0" + n;
			}
			if (n < 10) return "0" + n;
			return "" + n;
		}
    }
}