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
	import cv.events.TempoEvent;
	import cv.interfaces.IMediaPlayer;
	import cv.events.MetaDataEvent;
	import cv.util.MathUtil;
	import flash.errors.IOError;
	import flash.events.AsyncErrorEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	//--------------------------------------
    //  Events
    //--------------------------------------
	/**
	 * Dispatched when a cue point is reached.
	 *
	 * @eventType cv.events.MetadataEvent.CUE_POINT
	 */
	[Event(name = "cuePoint", type = "cv.events.MetadataEvent")]
	
	/**
	 * The user agent begins looking for media data, as part of the resource selection algorithm.
	 *
	 * @eventType cv.events.TempoEvent.LOAD_START
	 */
	[Event(name = "loadstart", type = "cv.events.TempoEvent")]
	
	/**
	 * The user agent is fetching media data.
	 *
	 * @eventType cv.events.TempoEvent.PROGRESS
	 */
	[Event(name = "progress", type = "flash.events.TempoEvent")]
	
	/**
	 * The user agent is intentionally not currently fetching media data.
	 *
	 * @eventType cv.events.TempoEvent.SUSPEND
	 */
	[Event(name = "suspend", type = "cv.events.TempoEvent")]
	
	/**
	 * Dispatched as metadata is receieved from the media playing
	 *
	 * @eventType cv.events.MetaDataEvent.METADATA
	 */
	[Event(name = "metadata", type = "cv.events.MetaDataEvent")]
	
	/**
	 * The user agent stops fetching the media data before it is completely downloaded, but not due to an error.
	 *
	 * @eventType cv.events.TempoEvent.ABORT
	 */
	[Event(name = "abort", type = "cv.events.TempoEvent")]
	
	/**
	 * An error occurs while fetching the media data.
	 *
	 * @eventType cv.events.TempoEvent.ERROR
	 */
	[Event(name = "error", type = "cv.events.TempoEvent")]
	
	/**
	 * A media element whose networkState was previously not in the NETWORK_EMPTY state has 
	 * just switched to that state (either because of a fatal error during load that's about 
	 * to be reported, or because the load() method was invoked while the resource selection 
	 * algorithm was already running).
	 *
	 * @eventType cv.events.TempoEvent.EMPTIED
	 */
	[Event(name = "emptied", type = "cv.events.TempoEvent")]
	
	/**
	 * The user agent is trying to fetch media data, but data is unexpectedly not forthcoming.
	 *
	 * @eventType cv.events.TempoEvent.STALLED
	 */
	[Event(name = "stalled", type = "cv.events.TempoEvent")]
	
	/**
	 * The user agent has just determined the duration and dimensions of the media resource 
	 * and the text tracks are ready.
	 *
	 * @eventType cv.events.TempoEvent.LOADED_METADATA
	 */
	[Event(name = "loadedmetadata", type = "cv.events.TempoEvent")]
	
	/**
	 * The user agent can render the media data at the current playback position for the first time.
	 *
	 * @eventType cv.events.TempoEvent.LOADED_DATA
	 */
	[Event(name = "loadeddata", type = "cv.events.TempoEvent")]
	
	/**
	 * The user agent can resume playback of the media data, but estimates that if playback 
	 * were to be started now, the media resource could not be rendered at the current playback 
	 * rate up to its end without having to stop for further buffering of content.
	 *
	 * @eventType cv.events.TempoEvent.CAN_PLAY
	 */
	[Event(name = "canplay", type = "cv.events.TempoEvent")]
	
	/**
	 * The user agent estimates that if playback were to be started now, the media resource 
	 * could be rendered at the current playback rate all the way to its end without having 
	 * to stop for further buffering.
	 *
	 * @eventType cv.events.TempoEvent.CAN_PLAY_THROUGH
	 */
	[Event(name = "canplaythrough", type = "cv.events.TempoEvent")]
	
	/**
	 * Playback is ready to start after having been paused or delayed due to lack of media data.
	 *
	 * @eventType cv.events.TempoEvent.PLAYING
	 */
	[Event(name = "playing", type = "cv.events.TempoEvent")]
	
	/**
	 * Playback has stopped because the next frame is not available, but the user agent expects 
	 * that frame to become available in due course.
	 *
	 * @eventType cv.events.TempoEvent.WAITING
	 */
	[Event(name = "waiting", type = "cv.events.TempoEvent")]
	
	/**
	 * The seeking IDL attribute changed to true.
	 *
	 * @eventType cv.events.TempoEvent.SEEKING
	 */
	[Event(name = "seeking", type = "cv.events.TempoEvent")]
	
	/**
	 * The seeking IDL attribute changed to false.
	 *
	 * @eventType cv.events.TempoEvent.SEEKED
	 */
	[Event(name = "seeked", type = "cv.events.TempoEvent")]
	
	/**
	 * Playback has stopped because the end of the media resource was reached.
	 *
	 * @eventType cv.events.TempoEvent.ENDED
	 */
	[Event(name = "ended", type = "cv.events.TempoEvent")]
	
	/**
	 * The duration attribute has just been updated.
	 *
	 * @eventType cv.events.TempoEvent.DURATION_CHANGE
	 */
	[Event(name = "durationchange", type = "cv.events.TempoEvent")]
	
	/**
	 * The current playback position changed as part of normal playback or in 
	 * an especially interesting way, for example discontinuously.
	 *
	 * @eventType cv.events.TempoEvent.TIME_UPDATE
	 */
	[Event(name = "timeupdate", type = "cv.events.TempoEvent")]
	
	/**
	 * The element is no longer paused. Fired after the play() method has returned, 
	 * or when the autoplay attribute has caused playback to begin.
	 *
	 * @eventType cv.events.TempoEvent.PLAY
	 */
	[Event(name = "play", type = "cv.events.TempoEvent")]
	
	/**
	 * The element has been paused. Fired after the pause() method has returned.
	 *
	 * @eventType cv.events.TempoEvent.PAUSE
	 */
	[Event(name = "pause", type = "cv.events.TempoEvent")]
	
	/**
	 * Either the defaultPlaybackRate or the playbackRate attribute has just been updated.
	 *
	 * @eventType cv.events.TempoEvent.RATE_CHANGE
	 */
	[Event(name = "ratechange", type = "cv.events.TempoEvent")]
	
	/**
	 * Either the volume attribute or the muted attribute has changed. Fired after the 
	 * relevant attribute's setter has returned.
	 *
	 * @eventType cv.events.TempoEvent.VOLUME_CHANGE
	 */
	[Event(name = "volumechange", type = "cv.events.TempoEvent")]
	
	//--------------------------------------
    //  Class description
    //--------------------------------------	
    /**
	 * <h3>Version:</h3> 4.0.0<br>
	 * <h3>Date:</h3> 9/26/2012<br>
	 * <h3>Updates At:</h3> http://blog.coursevector.com/tempolite<br>
	 * <br>
	 * The NetStreamPlayer class is a facade for controlling loading, and playing
	 * of video, streaming video and M4A files within Flash. It intelligently handles pausing, and
	 * loading.
	 * 
	 * Note: Sometimes playhead won't move on videos, this is because there is no 
	 * metadata describing it's duration. If this occurs, there is no way to
	 * calculate how long a video is, so it stops the playhead from moving.
	 * <hr>
	 * <ul>
	 * <li>4.0.0
	 * <ul>
	 * 		<li>Adapted to HTML5 API<li>
	 * </ul>
     */
	public class NetStreamPlayer extends EventDispatcher implements IMediaPlayer {
		
		public static const VERSION:String = "4.0.0";
		
		public var debug:Boolean = false;
		
		// HTML
		protected var _autoPlay:Boolean = false;
		protected var _bytesLoaded:uint;
		protected var _bytesTotal:uint;
		protected var _ended:Boolean = false;
		protected var _error:MediaError;
		protected var _loop:Boolean = false;
		protected var _muted:Boolean = false;
		protected var _networkState:uint = NetworkState.NETWORK_EMPTY;
		protected var _paused:Boolean = true;
		protected var _readyState:uint = ReadyState.HAVE_NOTHING;
		protected var _seeking:Boolean = false;
		protected var _src:String = '';
		protected var _volume:Number = 1;
		
		protected var autoPlaying:Boolean = true;
		protected var defaultPlaybackPosition:uint = 0;
		protected var initialPlaybackPosition:uint = 0;
		protected var loadFlag:Boolean = false;
		
		// Flash
		protected var _buffer:Number = 0.1;
		protected var _metaData:Object;
		protected var arrMIMETypes:Array = ["video/x-flv","video/mp4","audio/mp4","video/3gpp","audio/3gpp","video/quicktime","audio/mp4","video/x-m4v"];
		protected var arrFileTypes:Array = ["flv","f4v","f4p","f4b","f4a","3gp","3g2","mov","mp4","m4v","m4a","p4v"];
		protected var client:Object;
		protected var encoding:uint = 0;
		protected var loadTimer:Timer = new Timer(10);
		protected var playTimer:Timer = new Timer(10);
		protected var nc:NetConnection;
		protected var ns:NetStream;
		protected var vid:Video;
		
		public function NetStreamPlayer() {
			playTimer.addEventListener(TimerEvent.TIMER, playTimerHandler, false, 0, true);
			loadTimer.addEventListener(TimerEvent.TIMER, loadTimerHandler, false, 0, true);
			client = { onCuePoint:onCuePoint, onMetaData:onMetaData };
		}
		
		//--------------------------------------
		//  HTML Properties
		//--------------------------------------
		
		public function get autoPlay():Boolean { return _autoPlay; }
		/** @private **/
		public function set autoPlay(b:Boolean):void { _autoPlay = b; }
		
		/**
		 * Returns a TimeRanges object that represents the ranges of the media resource that the user agent has buffered.
		 */
		// buffered
		
		/**
		 * Returns the address of the current media resource.
		 * 
		 * Returns the empty string when there is no media resource.
		 */
		public function get currentSrc():String { return _src; }
		
		/** 
		 * Returns the official playback position, in seconds.
		 * 
		 * Can be set, to seek to the given time.
		 */
		public function get currentTime():Number { return ns ? ns.time : 0 }
		/** @private **/
		public function set currentTime(n:Number):void {
			n = MathUtil.clamp(0, duration, n);
			if (readyState == ReadyState.HAVE_NOTHING) {
				defaultPlaybackPosition = n;
			} else {
				_seeking = true;
				dispatchEvent(new TempoEvent(TempoEvent.SEEKING));
				if (ns) ns.seek(n);
				if (paused && ns) ns.pause();
			}
		}
		
		/** 
		 * Returns the length of the media resource, in seconds, assuming that the start of the media 
		 * resource is at time zero.
		 * 
		 * Returns NaN if the duration isn't available.
		 * 
		 * Returns Infinity for unbounded streams.
		 */
		public function get duration():Number { return _metaData ? _metaData.duration : NaN; }
		
		/**
		 * Returns true if playback has reached the end of the media resource.
		 */
		public function get ended():Boolean { return _ended; }
		
		/**
		 * Returns a MediaError object representing the current error state of the element.
		 * 
		 * Returns null if there is no error.
		 */
		public function get error():MediaError { return _error; }
		
		/**
		 *  Indicates that the media element is to seek back to the start of the media resource upon reaching the end.
		 */
		public function get loop():Boolean { return _loop; }
		/** @private **/
		public function set loop(b:Boolean):void { _loop = b; }
		
		/** 
		 * Returns true if audio is muted, overriding the volume attribute, and false if the 
		 * volume attribute is being honored.
		 * 
		 * Can be set, to change whether the audio is muted or not.
		 */
		public function get muted():Boolean { return _muted; }
		/** @private **/
		public function set muted(b:Boolean):void {
			_muted = b;
			updateSoundTransform();
		}
		
		/**
		 * Returns the current state of network activity for the element, from the codes in the list below.
		 * 
		 * @see cv.data.NetworkState
		 */
		public function get networkState():uint { return _networkState;	}
		/** @private **/
		public function set networkState(n:uint):void {	_networkState = n; }
		
		/**
		 * Returns true if playback is paused; false otherwise.
		 */
		public function get paused():Boolean { return _paused; }
		
		/**
		 * Returns a TimeRanges object that represents the ranges of the media resource that the user agent has played.
		 */
		// played
		
		/**
		 *  Provides a hint to the user agent about what the author thinks will lead to the 
		 * best user experience. The attribute may be ignored altogether, for example based 
		 * on explicit user preferences or based on the available connectivity.
		 */
		// preload
		
		/**
		 * Returns a value that expresses the current state of the element with respect to rendering the 
		 * current playback position, from the codes in the list below.
		 * 
		 * @see cv.data.ReadyState
		 */
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
		
		/**
		 * Returns true if the user agent is currently seeking.
		 */
		public function get seeking():Boolean {	return _seeking; }
		
		/**
		 * Returns a TimeRanges object that represents the ranges of the media resource to which it is 
		 * possible for the user agent to seek.
		 */
		// seekable
		
		public function get src():String {	return _src; }
		/** @private **/
		public function set src(str:String):void {
			_src = unescape(str);
			mediaElementLoadAlgorithm();
		}
		
		/**
		 * Returns the intrinsic dimensions of the video, or zero if the dimensions are not known.
		 */
		public function get videoWidth():Number { return _metaData ? _metaData.width : 0; }
		
		/**
		 * Returns the intrinsic dimensions of the video, or zero if the dimensions are not known.
		 */
		public function get videoHeight():Number {	return _metaData ? _metaData.height : 0; }
		
		/** 
		 * Returns the current playback volume, as a number in the range 0.0 to 1.0, where 0.0 is the 
		 * quietest and 1.0 the loudest.
		 * 
		 * Can be set, to change the volume.
		 * 
		 * Throws an IndexSizeError if the new value is not in the range 0.0 .. 1.0.
		 */
		public function get volume():Number { return _muted ? 0 : _volume }
		/** @private **/
		public function set volume(n:Number):void {
			_volume = MathUtil.clamp(0, 1, n);
			updateSoundTransform();
		}
		
		//--------------------------------------
		//  Flash Properties
		//--------------------------------------
		
		/** 
		 * Gets or sets how long the NetStreamPlayer should buffer the video before playing, in seconds.
		 */
		public function get buffer():int { return _buffer }
		/** @private **/
		public function set buffer(n:int):void {
			if(n <= 0) n = 0.1;
			_buffer = n;
		}
		
		/** 
		 * Gets the current load progress in terms of bytes
		 */
		public function get bytesLoaded():uint { return _bytesLoaded ? _bytesLoaded : 0 }
		
		/** 
		 * Gets the total size to be loaded in terms of bytes
		 */
		public function get bytesTotal():uint { return _bytesTotal ? _bytesTotal : 0 }
		
		/** 
		 * Gets the metadata if available for the currently playing audio file
		 */
		public function get metaData():Object { return _metaData }
		
		/** 
		 * Gets or sets the reference to the display video object.
		 */
		public function get video():Video {	return vid }
		/** @private **/
		public function set video(v:Video):void {
			vid = v;
			if (ns) vid.attachNetStream(ns);
		}
		
		//--------------------------------------
		//  Methods
		//--------------------------------------
		
		/**
		 * Returns true or false based on if the user agent is that it can play media resources of the given type.
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
		 * Sets the paused attribute to true, loading the media resource if necessary.
		 */
		public function pause():void {
			if (networkState == NetworkState.NETWORK_EMPTY) resourceSelectionAlgorithm();
			
			autoPlaying = false;
			if (!paused) {
				_paused = true;
				if (ns) ns.pause();
				playTimer.stop();
				dispatchEvent(new TempoEvent(TempoEvent.TIME_UPDATE));
				dispatchEvent(new TempoEvent(TempoEvent.PAUSE));
			}
		}
		
		/**
		 * Sets the paused attribute to false, loading the media resource and beginning playback if necessary. 
		 * If the playback had ended, will restart it from the start.
		 */
		public function play():void {
			if (networkState == NetworkState.NETWORK_EMPTY) resourceSelectionAlgorithm();
			
			if (ended) {
				if (ns) ns.seek(0);
				dispatchEvent(new TempoEvent(TempoEvent.TIME_UPDATE));
			}
			
			if (paused) {
				_paused = false;
				if (ns) ns.resume();
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
		
		public function unload():void {
			try {
				if (vid) vid.clear();
				if (ns) ns.close();
			} catch (error:IOError) {
				// Isn't streaming/loading any longer
			}
			playTimer.stop();
			loadTimer.stop();
			_metaData = null;
			ns = null;
			nc = null;
			_ended = false;
		}
		
		//--------------------------------------
		//  Private
		//--------------------------------------
		
		protected function createConnection(command:String = null, ...rest):void {
			nc = new NetConnection();
			nc.client = client;
			nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);
			nc.addEventListener(IOErrorEvent.IO_ERROR, errorHandler, false, 0, true);
			nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler, false, 0, true);
			nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, errorHandler, false, 0, true);
			nc.objectEncoding = encoding;
			nc.connect(command, rest);
		}
		
		protected function createStream(netstream:NetStream = null):void {
			ns = netstream || new NetStream(nc);
			ns.client = client;
			ns.bufferTime = _buffer;
			ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);
			ns.addEventListener(IOErrorEvent.IO_ERROR, errorHandler, false, 0, true);
			ns.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler, false, 0, true);
			ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, errorHandler, false, 0, true);
			if (vid) vid.attachNetStream(ns);
			
			loadTimer.start();
			ns.play(src);
			updateSoundTransform();
		}
		
		protected function errorHandler(e:ErrorEvent):void {
			trace2("NetStreamPlayer - " + e.type + " : " + e.text);
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
		
		protected function loadTimerHandler(event:TimerEvent):void {
			try {
				_bytesLoaded = ns.bytesLoaded;
				_bytesTotal = ns.bytesTotal;
				
				if(ns.bytesLoaded == ns.bytesTotal) {
					loadTimer.stop();
					dispatchEvent(new TempoEvent(TempoEvent.PROGRESS));
					networkState = NetworkState.NETWORK_IDLE;
					dispatchEvent(new TempoEvent(TempoEvent.SUSPEND));
				} else {
					dispatchEvent(new TempoEvent(TempoEvent.PROGRESS));
				}
			} catch (error:Error) {
				// Ignore this error
			}
		}
		
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
		
		protected function netStatusHandler(e:NetStatusEvent):void {
			trace2("NetStreamPlayer - netStatusHandler : Code:" + e.info.code);
			try {
				switch (e.info.code) {
					/* Errors */
					case "NetStream.Play.Failed":
					case "NetStream.FileStructureInvalid":
					case "NetStream.NoSupportedTrackFound":
						pause();
						_error = new MediaError(MediaError.MEDIA_ERR_DECODE);
						dispatchEvent(new TempoEvent(TempoEvent.ERROR));
						if (readyState == ReadyState.HAVE_NOTHING) {
							networkState = NetworkState.NETWORK_EMPTY;
							dispatchEvent(new TempoEvent(TempoEvent.EMPTIED));
						} else {
							networkState = NetworkState.NETWORK_IDLE;
						}
						
						if (e.info.code == "NetStream.Play.Failed") {
							trace("NetStreamPlayer - netStatusHandler - Error : An error has occurred in playback. (" + e.info.code + ")");
						} else if (e.info.code == "NetStream.FileStructureInvalid") {
							trace("NetStreamPlayer - netStatusHandler - Error : The MP4's file structure is invalid. (" + e.info.code + ")");
						} else if (e.info.code == "NetStream.NoSupportedTrackFound") {
							trace("NetStreamPlayer - netStatusHandler - Error : The MP4 doesn't contain any supported tracks. (" + e.info.code + ")");
						}
						break;
					case "NetStream.Play.StreamNotFound":
					case "NetConnection.Connect.Rejected":
					case "NetConnection.Connect.Failed":
						unload();
						_error = new MediaError(MediaError.MEDIA_ERR_NETWORK);
						dispatchEvent(new TempoEvent(TempoEvent.ERROR));
						networkState = NetworkState.NETWORK_IDLE;
						trace("NetStreamPlayer - netStatusHandler - Error : File/Stream not found. (" + e.info.code + ")");
						break;
					case "NetStream.Seek.InvalidTime":
						// Seek to last available time
						currentTime = Number(e.info.message.details);
						break;
					
					/* Status */
					case "NetStream.Buffer.Empty":
						readyState = ReadyState.HAVE_CURRENT_DATA;
						break;
					case "NetStream.Buffer.Full":
						readyState = ReadyState.HAVE_FUTURE_DATA;
						break;
					case "NetStream.Buffer.Flush":
						readyState = ReadyState.HAVE_ENOUGH_DATA;
						break;
					case "NetStream.Play.Start":
						// Video started
						var jumped:Boolean = false;
						if (defaultPlaybackPosition > 0) {
							jumped = true;
							ns.seek(defaultPlaybackPosition);
						}
						defaultPlaybackPosition = 0;
						
						if (!jumped && initialPlaybackPosition > 0) {
							jumped = true;
							ns.seek(initialPlaybackPosition);
						}
						
						break;
					case "NetStream.Play.Stop":
						// Video finished
						if (loop) {
							currentTime = 0;
						} else {
							_ended = true;
							pause();
							dispatchEvent(new TempoEvent(TempoEvent.ENDED));
						}
						break;
					/*case "NetStream.Play.Reset":
						//Caused by a play list reset.
						break;
					case "NetStream.Pause.Notify":
						// Paused
						break;
					case "NetStream.Unpause.Notify":
						// Resumed
						break;*/
					case "NetStream.Seek.Notify":
						// Seek was successful, delay it a bit so it's called after this event has completed becuase the actual
						// progress information hasnt updated yet.
						_seeking = false;
						dispatchEvent(new TempoEvent(TempoEvent.SEEKED));
						setTimeout(dispatchEvent, 50, new TempoEvent(TempoEvent.TIME_UPDATE));
						break;
					/*case "NetConnection.Connect.Closed":
						//The connection was closed successfully.*/
					case "NetConnection.Connect.Success":
						//The connection attempt succeeded.
						createStream();
						break;
				}
			} catch (error:Error) {
				// Ignore this error
				trace2("NetStreamPlayer - netStatusHandler - Error : " + error.message);
			}
		}
		
		/*
		{name, parameters, time, type}
		name - The name given to the cue point when it was embedded in the video file. 
		parameters - A associative array of name/value pair strings specified for this cue point. Any valid string can be used for the parameter name or value. 
		time - The time in seconds at which the cue point occurred in the video file during playback. 
		type - The type of cue point that was reached, either navigation or event. 
		*/
		protected function onCuePoint(o:Object):void {
			dispatchEvent(new MetaDataEvent(MetaDataEvent.CUE_POINT, o));
		}
		
		/**
		 * Handles the metadata returned. Possible data sent:
		 * <li>canSeekToEnd</li>
		 * <li>cuePoints</li>
		 * <li>audiocodecid</li>
		 * <li>audiodelay</li>
		 * <li>audiodatarate</li>
		 * <li>videocodecid</li>
		 * <li>framerate</li>
		 * <li>videodatarate</li>
		 * <li>height - Older version of encode</li>
		 * <li>width - Older version of encode</li>
		 * <li>duration - Older version of encode</li>
		 * 
		 * tags
		 * avcprofile 66
		 * audiocodecid mp4a
		 * width 480
		 * videocodecid avc1
		 * audiosamplerate 44100
		 * aacaot 2
		 * audiochannels 2
		 * avclevel 21
		 * duration 684
		 * videoframerate 30
		 * height 320
		 * trackinfo [object Object],[object Object]
		 * moovPosition 33166610
		 * 
		 * @param	o
		 */
		protected function onMetaData(o:Object):void {
			_metaData = o;
			dispatchEvent(new TempoEvent(TempoEvent.DURATION_CHANGE));
			readyState = ReadyState.HAVE_METADATA;
			dispatchEvent(new MetaDataEvent(MetaDataEvent.METADATA, _metaData));
		}
		
		protected function playTimerHandler(event:TimerEvent):void {
			dispatchEvent(new TempoEvent(TempoEvent.TIME_UPDATE));
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
			createConnection();
		}
		
		protected function trace2(...arguements):void {
			if (debug) trace(arguements);
		}
		
		protected function updateSoundTransform():void {
			if (ns) {
				var transform:SoundTransform = ns.soundTransform;
				transform.volume = _muted ? 0 : _volume;
				ns.soundTransform = transform;
			}
			dispatchEvent(new TempoEvent(TempoEvent.VOLUME_CHANGE));
		}
	}
}