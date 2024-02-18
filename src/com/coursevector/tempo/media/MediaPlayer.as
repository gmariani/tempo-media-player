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

package com.coursevector.tempo.media {
	
	import com.coursevector.tempo.events.MediaEvent;
	import com.coursevector.tempo.interfaces.IMediaPlayer;
	import com.coursevector.tempo.model.MediaItem;
	import com.coursevector.tempo.model.PlayerState;
	import flash.events.ErrorEvent;
	import flash.events.EventDispatcher;
	
	//--------------------------------------
    //  Events
    //--------------------------------------
	/**
	 * Dispatched when a cue point is reached.
	 *
	 * @eventType com.coursevector.events.MetadataEvent.CUE_POINT
	 */
	[Event(name = "tempoCuePoint", type = "com.coursevector.events.MetadataEvent")]
	
	/**
	 * Dispatches the current load progress.
	 *
	 * @eventType com.coursevector.events.MediaEvent.LOAD_PROGRESS
	 */
	[Event(name = "tempoLoadProgress", type = "flash.events.MediaEvent")]
	
	/**
	 * Dispatches when the file has finished loading
	 *
	 * @eventType com.coursevector.events.MediaEvent.LOAD_COMPLETE
	 */
	[Event(name = "tempoLoadComplete", type = "flash.events.MediaEvent")]
	
	/**
	 * Dispatched when metadata for media has been loaded.
	 *
	 * @eventType com.coursevector.events.MetaDataEvent.METADATA
	 */
	[Event(name = "tempoMetadata", type = "com.coursevector.events.MetaDataEvent")]
	
	/**
	 * An error occurs while fetching the media data.
	 *
	 * @eventType com.coursevector.events.MediaEvent.ERROR
	 */
	[Event(name = "tempoError", type = "com.coursevector.events.MediaEvent")]
	
	/**
	 * Dispatched when a portion of the current media has been loaded into the buffer.
	 *
	 * @eventType com.coursevector.events.MediaEvent.BUFFER
	 */
	[Event(name = "tempoBuffer", type = "com.coursevector.events.MediaEvent")]
	
	/**
	 * Dispatched when the buffer is full.
	 *
	 * @eventType com.coursevector.events.MediaEvent.BUFFER_FULL
	 */
	[Event(name = "tempoBufferFull", type = "com.coursevector.events.MediaEvent")]
	
	/**
	 * Dispatched after the MediaPlayer has successfully set up a connection to the media.
	 *
	 * @eventType com.coursevector.events.MediaEvent.LOADED
	 */
	[Event(name = "tempoLoaded", type = "com.coursevector.events.MediaEvent")]
	
	/**
	 * Dispatches the position and duration of the currently playing media.
	 *
	 * @eventType com.coursevector.events.MediaEvent.PLAT_PROGRESS
	 */
	[Event(name = "tempoPlayProgress", type = "com.coursevector.events.MediaEvent")]
	
	/**
	 * The seeking attribute changed to true.
	 *
	 * @eventType com.coursevector.events.MediaEvent.SEEKING
	 */
	[Event(name = "tempoSeeking", type = "com.coursevector.events.MediaEvent")]
	
	/**
	 * The seeking attribute changed to false.
	 *
	 * @eventType com.coursevector.events.MediaEvent.SEEKED
	 */
	[Event(name = "tempoSeeked", type = "com.coursevector.events.MediaEvent")]
	
	/**
	 * Playback has stopped because the end of the media resource was reached.
	 *
	 * @eventType com.coursevector.events.MediaEvent.PLAY_COMPLETE
	 */
	[Event(name = "tempoPlayComplete", type = "com.coursevector.events.MediaEvent")]
	
	/**
	 * Sent when the playback state has changed.
	 *
	 * @eventType com.coursevector.events.MediaEvent.STATE
	 */
	[Event(name = "tempoState", type = "com.coursevector.events.MediaEvent")]
	
	/**
	 * Either the volume attribute or the muted attribute has changed. Fired after the 
	 * relevant attribute's setter has returned.
	 *
	 * @eventType com.coursevector.events.MediaEvent.VOLUME
	 */
	[Event(name = "tempoVolume", type = "com.coursevector.events.MediaEvent")]
	
	/**
	 * Dispatched when the currently playing media exposes different quality levels
	 *
	 * @eventType com.coursevector.events.MediaEvent.QUALITY_LEVELS
	 */
	[Event(name = "tempoQualityLevels", type = "com.coursevector.events.MediaEvent")]
	
	/**
	 * Dispatched when the currently quality level has changed
	 *
	 * @eventType com.coursevector.events.MediaEvent.QUALITY_CHANGE
	 */
	[Event(name = "tempoQualityChange", type = "com.coursevector.events.MediaEvent")]
	
	//--------------------------------------
    //  Class description
    //--------------------------------------	
    /**
	 * <h3>Version:</h3> 4.0.0<br>
	 * <h3>Date:</h3> 9/26/2012<br>
	 * <h3>Updates At:</h3> http://blog.coursevector.com/tempolite<br>
	 * <br>
	 * The MediaPlayer class is foundation class for all media related
	 * classes to have a common core of functions to work from.
	 * 
	 * <hr>
	 * <ul>
	 * <li>4.0.0
	 * <ul>
	 * 		<li>Refactore release<li>
	 * </ul>
     */
	public class MediaPlayer extends EventDispatcher implements IMediaPlayer {
		
		public var debug:Boolean = false;
		
		/** Reference to the player configuration. **/
		protected var _config:PlayerConfig;
		/** Current quality level **/
		protected var _currentQuality:Number = -1;
		protected var _height:Number;
		protected var _item:MediaItem;
		protected var _muted:Boolean = false;
		/** The current position inside the file. **/
		protected var _offset:Number = 0;
		protected var _position:Number = 0;
		/** Queue buffer full event if it occurs while the player is paused. **/
		protected var _queuedBufferFull:Boolean;
		protected var _state:String;
		protected var _volume:Number = 0.9;
		protected var _width:Number;
		
		public function get duration():Number {
			return item ? item.duration : -1;
		}
		
		/** Currently playing PlaylistItem **/
		public function get item():MediaItem {
			return _item;
		}
		
		public function get muted():Boolean { return _muted; }
		/** @private **/
		public function set muted(b:Boolean):void {
			_muted = b;
			dispatchEvent(new MediaEvent(MediaEvent.VOLUME));
		}
		
		/** Current position, in seconds **/
		public function get position():Number {
			return _position;
		}
		
		public function get state():String {
			return _state;
		}
		
		public function set state(newState:String):void {
			if (state != newState) {
				//var evt:PlayerStateEvent = new PlayerStateEvent(PlayerStateEvent.JWPLAYER_PLAYER_STATE, newState, state);
				_state = newState;
				dispatchEvent(new MediaEvent(MediaEvent.STATE));
			}
		}
		
		/**
		 * The current volume of the playing media
		 * <p>Range: 0-1</p>
		 */
		public function get volume():Number { return _mute ? 0 : _volume }
		
		public function set volume(n:Number):void {
			_volume = Math.max(0, Math.min(1, n));
			dispatchEvent(new MediaEvent(MediaEvent.VOLUME));
		}
		
		/**
		 * The current config
		 */
		protected function get config():Config {
			return _config;
		}
		
		//--------------------------------------
		//  Methods
		//--------------------------------------
		
		public function MediaPlayer(config:Config) {
			_config = cfg;
			_state = PlayerState.IDLE;
		}
		
		/**
		 * Load a new playlist item
		 * @param itm The playlistItem to load
		 **/
		public function load(newItem:*):void {
			_item = newItem;
			dispatchEvent(new MediaEvent(MediaEvent.LOADED));
		}
		
		/** Pause playback of the item. **/
		public function pause():void {
			state = PlayerState.PAUSED;
		}
		
		/** Resume playback of the item. **/
		public function play():void {
			if (_queuedBufferFull) {
				_queuedBufferFull = false;
				state = PlayerState.BUFFERING;
				dispatchEvent(MediaEvent.BUFFER_FULL);
				// TODO: Have TempoLite call play (InstreamPlayer) when buffer is full
			} else {
				state = PlayerState.PLAYING;
			}
		}
		
		/**
		 * Resizes the display.
		 *
		 * @param width		The new width of the display.
		 * @param height	The new height of the display.
		 * @param stretch	Whether or not to stretch the media 
		 **/
		public function resize(width:Number, height:Number):void {
			/*if (_stretch) {
				_width = width;
				_height = height;
				
				if (_media) {
					// Fix some rounding errors by resetting the media container size before stretching
					if (_media.numChildren > 0) {
						_media.width = _media.getChildAt(0).width;
						_media.height = _media.getChildAt(0).height;
					}
					Stretcher.stretch(_media, width, height, _config.stretching);
				}
			}*/
		}
		
		/**
		 * Seek to a certain position in the item.
		 *
		 * @param pos	The position in seconds.
		 **/
		public function seek(pos:Number):void {
			_position = pos;
		}
		
		/** Stop playing and loading the item. **/
		public function stop():void {
			state = PlayerState.IDLE;
			_position = 0;
		}
		
		/** Completes video playback **/
		protected function complete():void {
			if (state != PlayerState.IDLE) {
				stop();
				dispatchEvent(new MediaEvent(MediaEvent.PLAY_COMPLETE));
			}
		}
		
		/** Dispatches error notifications **/
		protected function error(e:*):void {
			if (e is String) e = new ErrorEvent(ErrorEvent.ERROR, false, false, e);
			trace2("MediaPlayer - " + e.type + " : " + e.text);
			stop();
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.text));
		}
		
		protected function trace2(...arguements):void {
			if (debug) trace(arguements);
		}
	}
}