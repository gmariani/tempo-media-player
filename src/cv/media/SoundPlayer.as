/**
* TempoLite ©2012 Gabriel Mariani.
* Visit http://blog.coursevector.com/tempolite for documentation, updates and more free code.
*
*
* Copyright (c) 2012 Gabriel Mariani
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

package cv.media {
	
	import cv.data.MediaError;
	import cv.data.NetworkState;
	import cv.data.ReadyState;
	import cv.events.LoadEvent;
	import cv.events.MetaDataEvent;
	import cv.events.PlayProgressEvent;
	import cv.events.TempoEvent;
	import cv.interfaces.IMediaPlayer;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.errors.IOError;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.media.SoundLoaderContext;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	
	//--------------------------------------
    //  Events
    //--------------------------------------
	
	/**
	 * Dispatched when the media file has completed loading
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
	 * @eventType cv.event.LoadEvent.LOAD_START
	 */
	[Event(name = "loadStart", type = "cv.events.LoadEvent")]
	
	/**
	 * Dispatched as ID3 metadata is receieved from an MP3
	 *
	 * @eventType cv.events.MetaDataEvent.METADATA
	 */
	[Event(name = "metadata", type = "cv.events.MetaDataEvent")]
	
	/**
	 * Dispatched as a media file finishes playing
	 *
	 * @eventType cv.events.PlayProgressEvent.PLAY_COMPLETE
	 */
	[Event(name = "playComplete", type = "cv.events.PlayProgressEvent")]
	
	/**
	 * Dispatched as a media file is playing
	 *
	 * @eventType cv.events.PlayProgressEvent.PLAY_PROGRESS
	 */
	[Event(name="playProgress", type="cv.events.PlayProgressEvent")]
	
	/**
	 * Dispatched once as a media file first begins to play
	 *
	 * @eventType cv.events.PlayProgressEvent.PLAY_START
	 */
	[Event(name = "playStart", type = "cv.events.PlayProgressEvent")]
	
	/**
	 * Dispatched when status has been updated.
	 *
	 * @eventType cv.events.PlayProgressEvent.STATUS
	 */
	[Event(name = "status", type = "cv.events.PlayProgressEvent")]

	//--------------------------------------
    //  Class description
    //--------------------------------------	
    /**
	 * <h3>Version:</h3> 3.1.0<br>
	 * <h3>Date:</h3> 9/26/2012<br>
	 * <h3>Updates At:</h3> http://blog.coursevector.com/tempolite<br>
	 * <br>
	 * The SoundPlayer class is a facade for controlling loading, and playing
	 * of MP3 files within Flash. It intelligently handles pausing, and
	 * loading.
	 * <hr>
	 * <ul>
	 * <li>3.1.0
	 * <ul>
	 * 		<li>Fixed pause typeerror bug, soundchannel not existing before file load</li>
	 * 		<li>Added muted property</li>
	 * </ul>
	 * </li>
	 * <li>3.0.5
	 * <ul>
	 * 		<li>Re-dispatches any error events</li>
	 * </ul>
	 * </li>
	 * <li>3.0.4
	 * <ul>
	 * 		<li>currentPercent is now a number from 0 - 1</li>
	 * 		<li>Updated SoundTransform handling</li>
	 * 		<li>Updated error handling and traces</li>
	 * 		<li>seekPercent is now accepts a number from 0 - 1</li>
	 * </ul>
	 * </li>
	 * <li>3.0.3
	 * <ul>
	 * 		<li>Tweaked how load complete reports</li>
	 * 		<li>loadCurrent and loadTotal are now uints and more accurate</li>
	 * </ul>
	 * </li>
	 * <li>3.0.2
	 * <ul>
	 * 		<li>Handles autostart and PLAY_START better. Also has a new status of STARTED to differentiate between when autoStart and the first play().</li>
	 * 		<li>Added autoRewind prop. If set, it will rewind after PLAY_COMPLETE so the play button can be used to resume.</li>
	 * </ul>
	 * </li>
	 * <li>3.0.1
	 * <ul>
	 * 		<li>Changed how PLAY_START and autoStart is handled. autoStart is no longer overwritten and will pause before any audio is heard.</li>
	 * </ul>
	 * </li>
	 * <li>3.0.0
	 * <ul>
	 * 		<li>Refactored release</li>
	 * </ul>
	 * </li>
	 * </ul>
     */
    public class SoundPlayer extends EventDispatcher implements IMediaPlayer {
		
		/**
         * The current version
		 */
		public static const VERSION:String = "4.0.0";
		
		/**
		 * Enables/Disables debug traces
		 */
		public var debug:Boolean = false;
		
		protected var _autoPlay:Boolean = false;
		protected var _buffer:Number = 1;
		protected var _loadCurrent:uint;
		protected var _loadTotal:uint;
		protected var _metaData:Object;
		protected var _muted:Boolean = false;
		protected var _volume:Number = 1;
		protected var arrMIMETypes:Array = ["audio/mpeg3", "audio/x-mpeg-3", "audio/mpeg"];
		protected var arrFileTypes:Array = ["mp3"];
		protected var _paused:Boolean = true;
		protected var playTimer:Timer = new Timer(10);
		protected var sc:SoundChannel;
		protected var snd:Sound = new Sound();
		protected var loadFlag:Boolean = false;
		
		protected var autoPlaying:Boolean = true;
		protected var jumped:Boolean = false;
		protected var _error:MediaError;
		protected var _src:String = '';
		protected var _ended:Boolean = false;
		protected var _loop:Boolean = false;
		protected var initialPlaybackPosition:uint = 0;
		protected var defaultPlaybackPosition:uint = 0;
		protected var _seeking:Boolean = false;
		protected var _networkState:uint = NetworkState.NETWORK_EMPTY;
		protected var _readyState:uint = ReadyState.HAVE_NOTHING;
		
		public function SoundPlayer() {
			playTimer.addEventListener(TimerEvent.TIMER, soundHandler);
        }
		
		//--------------------------------------
		//  HTML Properties
		//--------------------------------------
		
		public function get autoPlay():Boolean { return _autoPlay; }
		/** @private **/
		public function set autoPlay(b:Boolean):void { _autoPlay = b; }
		
		public function get currentSrc():String { return _src; }
		
		public function get currentTime():Number { return sc ? sc.position : 0 }
		/** @private **/
		public function set currentTime(n:Number):void {
			n = Math.max(0, Math.min(duration, n));
			if (readyState == ReadyState.HAVE_NOTHING) {
				defaultPlaybackPosition = n;
			} else {
				_seeking = true;
				dispatchEvent(new TempoEvent(TempoEvent.SEEKING));
				if (paused) {
					defaultPlaybackPosition = n;
				} else {
					createSoundChannel(defaultPlaybackPosition);
				}
				_seeking = false;
				dispatchEvent(new TempoEvent(TempoEvent.SEEKED));
			}
		}
		
		public function get duration():Number {
			var n:int = Math.ceil(snd.length / (snd.bytesLoaded / snd.bytesTotal));
			return (_metaData) ? (_metaData.TLEN) ? _metaData.TLEN : n : n;
		}
		
		public function get ended():Boolean { return _ended; }
		
		public function get error():MediaError { return _error; }
		
		public function get loop():Boolean { return _loop; }
		/** @private **/
		public function set loop(b:Boolean):void { _loop = b; }
		
		/** 
		 * Gets or sets the muted state
		 */
		public function get muted():Boolean { return _muted; }
		/** @private **/
		public function set muted(b:Boolean):void {
			_muted = b;
			if (sc) sc.soundTransform = getSoundTransform();
		}
		
		public function get networkState():uint { return _networkState;	}
		/** @private **/
		public function set networkState(n:uint):void {	_networkState = n; }
		
		/**
		 * Returns the pause status of the player.
		 */
		public function get paused():Boolean { return _paused; }
		
		public function get readyState():uint {	return _readyState;	}
		/** @private **/
		public function set readyState(n:uint):void {
			/*var str:String = '';
			if (n == 0) str = 'ReadyState.HAVE_NOTHING';
			if (n == 1) str = 'ReadyState.HAVE_METADATA';
			if (n == 2) str = 'ReadyState.HAVE_CURRENT_DATA';
			if (n == 3) str = 'ReadyState.HAVE_FUTURE_DATA';
			if (n == 4) str = 'ReadyState.HAVE_ENOUGH_DATA';
			
			var str2:String = '';
			if (readyState == 0) str2 = 'ReadyState.HAVE_NOTHING';
			if (readyState == 1) str2 = 'ReadyState.HAVE_METADATA';
			if (readyState == 2) str2 = 'ReadyState.HAVE_CURRENT_DATA';
			if (readyState == 3) str2 = 'ReadyState.HAVE_FUTURE_DATA';
			if (readyState == 4) str2 = 'ReadyState.HAVE_ENOUGH_DATA';
			trace2('readyState - ' + str2 + '->' + str + ' - autoPlay ' + autoPlay + ' - paused ' + _paused);*/
			
			if (readyState == ReadyState.HAVE_NOTHING && n == ReadyState.HAVE_METADATA) {
				dispatchEvent(new TempoEvent(TempoEvent.LOADED_METADATA));
			}
			
			if (readyState == ReadyState.HAVE_METADATA && n >= ReadyState.HAVE_CURRENT_DATA) {
				if (loadFlag) dispatchEvent(new TempoEvent(TempoEvent.LOADED_DATA));
				loadFlag = false;
				// if (n >= ReadyState.HAVE_FUTURE_DATA)
			}
			
			if (readyState >= ReadyState.HAVE_FUTURE_DATA && n <= ReadyState.HAVE_CURRENT_DATA) {
				if (!ended && !paused) { // and no errors
					dispatchEvent(new TempoEvent(TempoEvent.TIME_UPDATE));
					dispatchEvent(new TempoEvent(TempoEvent.WAITING));
				}
			}
			
			/*if (readyState <= ReadyState.HAVE_CURRENT_DATA && n == ReadyState.HAVE_FUTURE_DATA) {
				dispatchEvent(new TempoEvent(TempoEvent.CAN_PLAY));
				if (!paused) dispatchEvent(new TempoEvent(TempoEvent.PLAYING));
			}*/
			
			if (n >= ReadyState.HAVE_FUTURE_DATA) { // HAVE_ENOUGH_DATA
				if (readyState <= ReadyState.HAVE_CURRENT_DATA) {
					dispatchEvent(new TempoEvent(TempoEvent.CAN_PLAY));
					if (!paused) dispatchEvent(new TempoEvent(TempoEvent.PLAYING));
				}
				
				if (autoPlaying && autoPlay && paused) {
					play();
				} else if (autoPlaying) {
					_paused = false;
					pause();
				}
				
				dispatchEvent(new TempoEvent(TempoEvent.CAN_PLAY_THROUGH));
			}
			
			_readyState = n;
		}
		
		public function get seeking():Boolean {	return _seeking; }
		
		public function get src():String {	return _src; }
		/** @private **/
		public function set src(str:String):void {
			_src = unescape(str);
			mediaElementLoadAlgorithm();
		}
		
		/** 
		 * Gets or sets the current volume, from 0 - 1
		 */
		public function get volume():Number { return _volume }
		/** @private **/
		public function set volume(n:Number):void {
			_volume = Math.max(0, Math.min(1, n));
			if (sc) sc.soundTransform = getSoundTransform();
		}
		
		//--------------------------------------
		//  Flash Properties
		//--------------------------------------
		
		/** 
		 * Gets or sets how long SoundPlayer should buffer the audio before 
		 * playing, in seconds.
		 */
		public function get buffer():int { return _buffer }
		/** @private **/
		public function set buffer(n:int):void {
			if(n < 0) n = 0;
			_buffer = n;
		}
		
		/** 
		 * Gets the current load progress in terms of bytes
		 */
		public function get loadCurrent():uint { return _loadCurrent ? _loadCurrent : 0 }
		
		/** 
		 * Gets the total size to be loaded in terms of bytes
		 */
		public function get loadTotal():uint { return _loadTotal ? _loadTotal : 0 }
		
		/** 
		 * Gets the metadata if available for the currently playing audio file
		 * 
		 * -MetaData
		 * ** Flash Player 9 and later supports ID3 2.0 tags, specifically 2.3 and 2.4
		 * -IDE 2.0 tag
		 * COMM Sound.id3.comment
		 * TABL Sound.id3.album
		 * TCON Sound.id3.genre
		 * TIT2 Sound.id3.songName
		 * TPE1 Sound.id3.artist
		 * TRCK Sound.id3.track
		 * TYER Sound.id3.year
		 * 
		 * -ID3 Earlier
		 * TFLT File type
		 * TIME Time
		 * TIT1 Content group description
		 * TIT2 Title/song name/content description
		 * TIT3 Subtitle/description refinement
		 * TKEY Initial key
		 * TLAN Languages
		 * TLEN Length
		 * TMED Media type
		 * TOAL Original album/movie/show title
		 * TOFN Original filename
		 * TOLY Original lyricists/text writers
		 * TOPE Original artists/performers
		 * TORY Original release year
		 * TOWN File owner/licensee
		 * TPE1 Lead performers/soloists
		 * TPE2 Band/orchestra/accompaniment
		 * TPE3 Conductor/performer refinement
		 * TPE4 Interpreted, remixed, or otherwise modified by
		 * TPOS Part of a set
		 * TPUB Publisher
		 * TRCK Track number/position in set
		 * TRDA Recording dates
		 * TRSN Internet radio station name
		 * TRSO Internet radio station owner
		 * TSIZ Size
		 * TSRC ISRC (international standard recording code)
		 * TSSE Software/hardware and settings used for encoding
		 * TYER Year
		 * WXXX URL Link frame
		 */
		public function get metaData():Object { return _metaData }
		
		//--------------------------------------
		//  Methods
		//--------------------------------------
		
		protected function mediaElementLoadAlgorithm():void {
			unload();
			
			if (networkState == NetworkState.NETWORK_LOADING || networkState == NetworkState.NETWORK_IDLE) {
				dispatchEvent(new TempoEvent(TempoEvent.ABORT));
			}
			
			if (networkState != NetworkState.NETWORK_EMPTY) {
				dispatchEvent(new TempoEvent(TempoEvent.EMPTIED));
				networkState = NetworkState.NETWORK_EMPTY;
				readyState = ReadyState.HAVE_NOTHING;
				_paused = true;
				playTimer.stop();
				_seeking = false;
				dispatchEvent(new TempoEvent(TempoEvent.TIME_UPDATE));
				initialPlaybackPosition = 0;
			}
			
			_error = null;
			autoPlaying = true;
			
			resourceSelectionAlgorithm();
		}
		
		protected function resourceSelectionAlgorithm():void {
			networkState = NetworkState.NETWORK_NO_SOURCE;
			if (src == '') return;
			
			loadFlag = true;
			networkState = NetworkState.NETWORK_LOADING;
			dispatchEvent(new TempoEvent(TempoEvent.LOAD_START));
			
			resourceFetchAlgorithm();
		}
		
		protected function resourceFetchAlgorithm():void {
			snd = new Sound();
			snd.addEventListener(Event.COMPLETE, soundHandler, false, 0, true);
			snd.addEventListener(ProgressEvent.PROGRESS, progressHandler, false, 0, true);
			snd.addEventListener(Event.ID3, soundHandler, false, 0, true);
			snd.addEventListener(IOErrorEvent.IO_ERROR, errorHandler, false, 0, true);
			snd.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler, false, 0, true);
			
			try {
				snd.load(new URLRequest(src), new SoundLoaderContext(_buffer * 1000, true));
			} catch (e:Error) {
				trace2("SoundPlayer - load : " + e.message);
				unload();
				return;
			}
			
			// Play start
			jumped = false;
			if (defaultPlaybackPosition > 0) {
				jumped = true;
				createSoundChannel(defaultPlaybackPosition);
			}
			
			if (!jumped && initialPlaybackPosition > 0) {
				jumped = true;
				createSoundChannel(initialPlaybackPosition);
			}
			
			play();
		}
		
		protected function createSoundChannel(pos:uint):void {
			if (sc) sc.removeEventListener(Event.SOUND_COMPLETE, soundHandler);
			sc = snd.play(pos, 0, getSoundTransform());
			if (sc) {
				sc.addEventListener(Event.SOUND_COMPLETE, soundHandler, false, 0, true);
			} else {
				trace2("SoundPlayer - play : No SoundChannel available");
			}
		}
		
		/**
		 * Validates if the given filetype is compatible to be played with NetStreamPlayer. 
		 * The acceptable file types are :
		 * <ul>
		 * <li>mp3</li>
		 * </ul>
		 * 
		 * @param type A file extension or MIME type
		 * 
		 * @return Boolean of whether the type is playable or not.
		 */
		public function canPlayType(type:String):Boolean {
			var i:uint = arrFileTypes.length;
			while (i--) {
				if (arrFileTypes[i] == type) return true;
			}
			
			i = arrMIMETypes.length;
			while (i--) {
				if (arrMIMETypes[i] == type) return true;
			}
			
			return false;
		}
		
		/**
		 * Causes the element to reset and start selecting and loading a new media resource from scratch.
		 */
		public function load():void {
			mediaElementLoadAlgorithm();
		}
		
		/**
		 * Controls the pause of the media
		 */
		public function pause():void {
			if (networkState == NetworkState.NETWORK_EMPTY) resourceSelectionAlgorithm();
			
			autoPlaying = false;
			if (!paused) {
				_paused = true;
				defaultPlaybackPosition = sc ? sc.position : 0;
				if (sc) sc.stop();
				playTimer.stop();
				dispatchEvent(new TempoEvent(TempoEvent.TIME_UPDATE));
				dispatchEvent(new TempoEvent(TempoEvent.PAUSE));
			}
		}
		
		/**
		 * Plays the media, starting at the given position.
		 */
		public function play():void {
			if (networkState == NetworkState.NETWORK_EMPTY) resourceSelectionAlgorithm();
			
			if (ended) {
				defaultPlaybackPosition = 0;
				if (sc) sc.stop();
				dispatchEvent(new TempoEvent(TempoEvent.TIME_UPDATE));
			}
			
			if (paused) {
				_paused = false;
				createSoundChannel(defaultPlaybackPosition);
				defaultPlaybackPosition = 0;
				playTimer.start();
				dispatchEvent(new TempoEvent(TempoEvent.PLAY));
				if (readyState == ReadyState.HAVE_NOTHING || readyState == ReadyState.HAVE_METADATA || readyState == ReadyState.HAVE_CURRENT_DATA) {
					dispatchEvent(new TempoEvent(TempoEvent.WAITING));
				} else if (readyState == ReadyState.HAVE_FUTURE_DATA || readyState == ReadyState.HAVE_ENOUGH_DATA) {
					dispatchEvent(new TempoEvent(TempoEvent.PLAYING));
				}
				autoPlaying = false;
			}
		}
		
		/**
		 * Stops the media, closes the NetConnection or NetStream, and resets the metadata.
		 * 
		 * @see cv.events.PlayProgressEvent.STATUS
		 */
		public function unload():void {
			try {
				if (snd) snd.close();
			} catch (error:IOError) {
				// Isn't streaming/loading any longer
				//trace2("SoundPlayer - unload : " + error.message);
			}
			defaultPlaybackPosition = 0;
			if (sc) sc.stop();
			playTimer.stop();
			_metaData = null;
			_ended = false;
		}
		
		//--------------------------------------
		//  Private
		//--------------------------------------
		
		protected function errorHandler(e:ErrorEvent):void {
			trace2("SoundPlayer - " + e.type + " : " + e.text);
			pause();
			_error = new MediaError(MediaError.MEDIA_ERR_NETWORK);
			dispatchEvent(new TempoEvent(TempoEvent.ERROR));
			if (readyState == ReadyState.HAVE_NOTHING) {
				networkState = NetworkState.NETWORK_EMPTY;
				dispatchEvent(new TempoEvent(TempoEvent.EMPTIED));
			} else {
				networkState = NetworkState.NETWORK_IDLE;
			}
			
			//dispatchEvent(e.clone());
		}
		
		protected function progressHandler(e:ProgressEvent):void {
			_loadCurrent = e.bytesLoaded;
			_loadTotal = e.bytesTotal;
			dispatchEvent(new TempoEvent(TempoEvent.PROGRESS));
		}
		
		protected function soundHandler(e:Event):void {
			switch (e.type) {
				case Event.COMPLETE :
					_loadCurrent = snd.bytesLoaded;
					_loadTotal = snd.bytesTotal;
					
					dispatchEvent(new TempoEvent(TempoEvent.PROGRESS));
					networkState = NetworkState.NETWORK_IDLE;
					dispatchEvent(new TempoEvent(TempoEvent.SUSPEND));
					break;
				case Event.ID3 :
					_metaData = e.target.id3;
					readyState = ReadyState.HAVE_METADATA;
					dispatchEvent(new MetaDataEvent(MetaDataEvent.METADATA, _metaData));
					break;
				case Event.SOUND_COMPLETE :
					if (loop) {
						currentTime = 0;
					} else {
						_ended = true;
						pause();
						dispatchEvent(new TempoEvent(TempoEvent.ENDED));
					}
					break;
				case TimerEvent.TIMER :
					dispatchEvent(new TempoEvent(TempoEvent.TIME_UPDATE));
					break;
			}
		}
		
		protected function trace2(...arguements):void {
			if (debug) trace(arguements);
		}
		
		protected function getSoundTransform():SoundTransform {
			var transform:SoundTransform = new SoundTransform(_muted ? 0 : _volume);
			dispatchEvent(new TempoEvent(TempoEvent.VOLUME_CHANGE));
			return transform;
		}
	}
}