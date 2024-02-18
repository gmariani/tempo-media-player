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
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.errors.IOError;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.media.ID3Info;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.media.SoundLoaderContext;
	import flash.net.URLRequest;
	import flash.utils.Timer;

	//--------------------------------------
    //  Class description
    //--------------------------------------	
    /**
	 * <h3>Version:</h3> 4.0.0<br>
	 * <h3>Date:</h3> 10/19/2012<br>
	 * <h3>Updates At:</h3> http://blog.coursevector.com/tempolite<br>
	 * <br>
	 * The SoundPlayer class is a facade for controlling loading, and playing
	 * of MP3 files within Flash. It intelligently handles pausing, and
	 * loading.
	 * <hr>
	 * <ul>
	 * <li>4.0.0
	 * <ul>
	 * 		<li>Refactored release</li>
	 * 		<li>StageVideo</li>
	 * 		<li>Variable Streaming</li>
	 * 		<li>Improved API</li>
	 * </ul>
	 * </li>
	 * </ul>
     */
    public class SoundPlayer extends MediaPlayer implements IMediaPlayer {
		
		protected var arrMIMETypes:Array = ["audio/mpeg3", "audio/x-mpeg-3", "audio/mpeg"];
		protected var arrFileTypes:Array = ["mp3"];
		
		protected var _bufferFull:Boolean;
		protected var _channel:SoundChannel;
		protected var _context:SoundLoaderContext;
		protected var _loadComplete:Boolean;
		protected var _loadCurrent:uint;
		protected var _loadTotal:uint;
		protected var _sound:Sound = new Sound();
		protected var _timer:Timer = new Timer(100);
		protected var _transform:SoundTransform;
		protected var _userDuration:Number = -1;
		protected var _metaDuration:Number = 0;
		
		public function SoundPlayer() {
			_transform = new SoundTransform();
			_context = new SoundLoaderContext(0, true);
			_timer.addEventListener(TimerEvent.TIMER, timerHandler);
        }
		
		//--------------------------------------
		//  Properties
		//--------------------------------------
		
		/** 
		 * Gets the current load progress in terms of bytes
		 */
		public function get loadCurrent():uint { return _sound ? _sound.bytesLoaded : 0 }
		
		/** 
		 * Gets the total size to be loaded in terms of bytes
		 */
		public function get loadTotal():uint { return _sound ? _sound.bytesTotal : 0 }
		
		/** 
		 * Gets or sets the current volume, from 0 - 1
		 */
		//public function get volume():Number { return _volume }
		/** @private **/
		override public function set volume(n:Number):void {
			super.volume = n;
			updateSound();
		}
		
		/** 
		 * Gets or sets the muted state
		 */
		//public function get muted():Boolean { return _muted }
		/** @private **/
		override public function set muted(b:Boolean):void {
			super.muted = b;
			updateSound();
		}
		
		//--------------------------------------
		//  Methods
		//--------------------------------------
		
		/**
		 * Validates if the given filetype is compatible to be played with SoundPlayer.
		 * The acceptable file types are :
		 * <ul>
		 * <li>mp3</li>
		 * </ul>
		 * 
		 * @param ext The file extension to be validated
		 * @param url The full file url if the extension is not enough
		 * 
		 * @return Boolean of whether the extension was valid or not.
		 */
		public function isValid(ext:String, url:String):Boolean {
			return (arrFileTypes[0] == ext);
		}
		
		public function isValidMIME(type:String):Boolean {
			var i:uint = arrMIMETypes.length;
			while (i--) {
				if (arrMIMETypes[i] == type) {
					return true;
				}
			}
			
			return false;
		}
		
		override public function load(newItem:*):void {
			if (!newItem) {
				throw new Error("SoundPlayer - load : Must enter a valid url or MediaItem to load a file");
				return;
			}
			if (newItem is String) newItem = new MediaItem(newItem);
			
			_position = 0;
			_bufferFull = false;
			_userDuration = newItem.duration;
			if (!_item || _item.file != newItem.file || !_bufferingComplete) {
				_bufferingComplete = false;
				_sound = new Sound();
				_sound.addEventListener(ProgressEvent.PROGRESS, positionHandler);
				_sound.addEventListener(Event.ID3, id3Handler);
				_sound.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
				_sound.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
				try {
					//_url = unescape(newItem.file);
					_sound.load(new URLRequest(newItem.file), _context);
				} catch (e:Error) {
					trace2("SoundPlayer - load : " + e.message);
				}
			}
			
			super.load(newItem);
			
			state = PlayerState.BUFFERING;
			_muted = config.mute;
			volume = config.volume;
			
			_timer.start();
		}
		
		/**
		 * Loads a sound from the library to be played. This cannot be used in 
		 * conjunction with TempoLite since the location is not a url.
		 * 
		 * @param	sound	The sound object from the library
		 * 
		 * @see cv.events.PlayProgressEvent.STATUS
		 */
		public function loadAsset(sound:Sound):void {
			if (!sound) {
				trace2("SoundPlayer - loadAsset : Must enter a sound to load");
				return;
			}
			
			_position = 0;
			_bufferFull = false;
			_userDuration = newItem.duration;
			if (!_item || !_bufferingComplete) {
				_item = new MediaItem();
				_bufferingComplete = false;
				_sound = sound;
				_sound.addEventListener(ProgressEvent.PROGRESS, positionHandler);
				_sound.addEventListener(Event.ID3, id3Handler);
				_sound.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
				_sound.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			}
			
			super.load(newItem);
			
			state = PlayerState.BUFFERING;
			_muted = config.mute;
			volume = config.volume;
			
			_timer.start();
		}
		
		override public function pause():void {
			if (_channel) _channel.stop();
			_position = _channel ? _channel.position : 0;
			super.pause();
		}
		
		override public function play():void {
			_timer.start();
			
			if (_channel) {
				_channel.removeEventListener(Event.SOUND_COMPLETE, timerHandler);
				_channel.stop();
				_channel = null;
			}
			_channel = _sound.play(_position, 0, _transform);
			_channel.addEventListener(Event.SOUND_COMPLETE, timerHandler);
			super.play();
		}
		
		override public function seek(pos:Number, play:Boolean = true):void {
			if ((_userDuration >= 0 && pos < _userDuration) || (_userDuration < 0 && _sound && pos < _sound.length) || item.start) {
				pos = Math.max(0, Math.min(_sound.length, pos * 1000));
				_timer.stop();
				if (_channel) _channel.stop();
				_position = pos;
				play();
			}
		}
		
		public function stop():void {
			_timer.stop();
			if (item) item.duration = _userDuration;
			super.stop();
			if (_channel) {
				_channel.stop();
				_channel = null;
			}
			try {
				_sound.close()
			} catch (err:IOError) { }
		}
		
		//--------------------------------------
		//  Private
		//--------------------------------------
		
		protected function timerHandler(e:Event = null):void {
			// onMetadata
			if (e.type == Event.ID3) {
				try {
					var id3:ID3Info = _sound.id3;
					var obj:Object = {type: 'id3', album: id3.album,
							artist: id3.artist, comment: id3.comment,
							genre: id3.genre, name: id3.songName, track: id3.track,
							year: id3.year };
					if (id3['TLEN']) _metaDuration = id3.TLEN;
					// TODO: Merge into item
					dispatchEvent(new MediaEvent(MediaEvent.METADATA));
				} catch (err:Error) { }
				return;
			}
			
			// onComplete
			if (e.type == Event.SOUND_COMPLETE) {
				complete();
				return;
			}
			
			var loadPercent:uint = 0;
			var bufferPercent:int = 0;
			var bufferMax:int = config.bufferlength;
			
			
			
			// Get/Update Duration
			if (_userDuration < 0) {
				if (_metaDuration) {
					_item.duration = _metaDuration;
				} else if (loadTotal > 0 && loadCurrent / loadTotal > 0.1) {
					_item.duration = _sound.length / 1000 / loadCurrent * loadTotal;
				} else if (_sound.length > 0) {
					_item.duration = Math.floor(_sound.length / 100) / 10;
				}
			}
			
			// Update Position
			if (_channel) _position = Math.floor(_channel.position / 100) / 10;
			
			// Get Buffer state
			if (_item.duration != 0 || _userDuration == 0) {
				if (loadTotal > 0) {
					loadPercent = Math.floor(loadCurrent / loadTotal * 100);
					bufferPercent = Math.max(0, (loadCurrent / loadTotal) * _item.duration - _position);
					bufferMax = Math.min(bufferMax, _item.duration - _position);
				} else {
					loadPercent = 0;
					bufferPercent = 1;
					bufferMax = 0;
				}
			}
				
			if (state == PlayerState.BUFFERING && !_bufferFull && bufferPercent >= bufferMax && loadCurrent > 0) {
				_bufferFull = true;
				dispatchEvent(new MediaEvent(MediaEvent.BUFFER_FULL));
			} else if (state == PlayerState.PLAYING && bufferPercent < (bufferMax / 3)) {
				// Buffer underrun condition
				_bufferFull = false;
				if (_channel) _channel.stop();
				state = PlayerState.BUFFERING;
				return;
			}
			
			// Update Loading
			if (_sound && !isNaN(loadPercent) && loadPercent > 0 && !_loadComplete) {
				dispatchEvent(new MediaEvent(MediaEvent.LOAD_PROGRESS));
				if (loadPercent == 100 && _loadComplete == false) {
					_loadComplete = true;
					dispatchEvent(new MediaEvent(MediaEvent.LOAD_COMPLETE));
				}
			}
			
			// Update Position
			if (state != PlayerState.PLAYING) return;
			
			if (_position < _item.duration) {
				dispatchEvent(new MediaEvent(MediaEvent.PLAY_PROGRESS));
			} else if (_item.duration > 0 && loadTotal > 0) {
				complete();
			}
		}
		
		protected function updateSound():void {
			_transform.volume = _muted ? 0 : _volume;
			if (_channel) _channel.soundTransform = _transform;
		}
	}
}