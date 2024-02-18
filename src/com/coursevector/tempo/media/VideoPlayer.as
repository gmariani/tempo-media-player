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
	import com.coursevector.tempo.interfaces.IMediaPlayer;
	import com.coursevector.tempo.events.MediaEvent;
	import com.coursevector.tempo.model.MediaItem;
	import com.coursevector.tempo.model.NetClient;
	import com.coursevector.tempo.model.PlayerState;
	import flash.events.AsyncErrorEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.Timer;
	
	//--------------------------------------
    //  Class description
    //--------------------------------------	
    /**
	 * <h3>Version:</h3> 4.0.0<br>
	 * <h3>Date:</h3> 10/19/2012<br>
	 * <h3>Updates At:</h3> http://blog.coursevector.com/tempolite<br>
	 * <br>
	 * The VideoPlayer class is a facade for controlling loading, and playing
	 * of video files within Flash. It intelligently handles pausing, and
	 * loading.
	 * 
	 * <hr>
	 * <ul>
	 * <li>4.0.0
	 * <ul>
	 * 		<li>Refactored release</li>
	 * 		<li>TODO: StageVideo</li>
	 * 		<li>TODO: Variable Streaming</li>
	 * </ul>
	 * </li>
	 * </ul>
     */
	public class VideoPlayer extends NetStreamPlayer implements IMediaPlayer {
		
		protected var _bufferFull:Boolean;
		protected var _loadComplete:Boolean;
		
		public function VideoPlayer(config:Config) {
			_conn = new NetConnection();
			_conn.connect(null);
			
			_transform = new SoundTransform();
			
			_stream = new NetStream(_conn);
			_stream.checkPolicyFile = true;
			_stream.client = new NetClient(this);
			_stream.bufferTime = config.bufferlength;
			_stream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			_stream.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			_stream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			_stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, errorHandler);
			
			if (_video) _video.attachNetStream(_stream);
			
			_timer.addEventListener(TimerEvent.TIMER, timerHandler);
			super(config);
		}
		
		//--------------------------------------
		//  Methods
		//--------------------------------------
		
		/**
		 * Loads a new file to be played.
		 * 
		 * @fparam s	The url of the file to be loaded
		 */
		public function load(newItem:*):void {
			if (!newItem) {
				throw new Error("VideoPlayer - load : Must enter a valid url or MediaItem to load a file");
				return;
			}
			if (newItem is String) newItem = new MediaItem(newItem);
			
			_bufferFull = false;
			_loadComplete = false;
			/*if (newItem.levels.length > 0) {
				newItem.setLevel(itm.getLevel(config.bandwidth, config.width));
				_bandwidthChecked = false;
			} else {
				_bandwidthChecked = true;
			}*/
			
			/*if (!item 
				|| _currentFile != newItem.file 
				|| _stream.bytesLoaded == 0 
				|| (_stream.bytesLoaded < _stream.bytesTotal > 0)) 
			{*/
				_url = newItem.file;
				if (Strings.extension(_url) == "aac" || Strings.extension(_url) == "m4a") {
					media = null;
				} else {
					media = _video;
				}
				_stream.checkPolicyFile = true;
				//strURL = unescape(s);
				var filePath:String = Strings.getAbsolutePath(_url, config['netstreambasepath']);
				_stream.play(filePath);
				_stream.pause();
			/*} else {
				if (newItem.duration <= 0) newItem.duration = item.duration;
				seekStream(newItem.start, false);
			}*/
			
			super.load(newItem);
			
			state = PlayerState.BUFFERING;
			_muted = config.mute;
			volume = config.volume;
			
			_timer.start();
		}
		
		public function pause():void {
			if (_stream) _stream.pause();
			super.pause();
		}
		
		public function play():void {
			_timer.start();
			if (_bufferFull) {
				_stream.resume();
				super.play();
			} else {
				state = PlayerState.BUFFERING;
			}
		}
		
		public function seek(pos:Number, play:Boolean=true):void {
			var loaded:Number = loadTotal > 0 ? (loadCurrent / loadTotal * duration) : 0;
			if (pos <= loaded) {
				super.seek(pos);
				_timer.stop();
				_stream.seek(pos);
				dispatchEvent(new MediaEvent(MediaEvent.SEEKING));
				if (play) play();
			}
		}
		
		/**
		 * Stops the media at the specified position. Sets the position given as the pause position.
		 */
		public function stop():void {
			if (_stream) {
				if (loadCurrent < loadTotal) {
					_stream.close();
				} else {
					_stream.pause();
					_stream.seek(0);
				}
			}
			_timer.stop();
			
			super.stop();
		}
		
		public function onClientData(data:Object):void {
			if (!data) return;
			
			/*
			tags
			avcprofile 66
			audiocodecid mp4a
			width 480
			videocodecid avc1
			audiosamplerate 44100
			aacaot 2
			audiochannels 2
			avclevel 21
			duration 684
			videoframerate 30
			height 320
			trackinfo [object Object],[object Object]
			moovPosition 33166610
			*/
			
			//if (autoScale) {
			if (data.width) { // data.hasOwnProperty("width")
				_video.width = data.width;
				_video.height = data.height;
				//resize(_width, _height);
			}
			if (data.duration && item.duration < 0) item.duration = data.duration;
			dispatchEvent(new MediaEvent(MediaEvent.METADATA));
		}
		
		//--------------------------------------
		//  Private
		//--------------------------------------
		
		protected function netStatusHandler(e:NetStatusEvent):void {
			trace2("VideoPlayer - netStatusHandler : Code:" + e.info.code);
			try {
				switch (e.info.code) {
					/* Errors */
					case "NetStream.Play.Failed":
						error("VideoPlayer - netStatusHandler - Error : An error has occurred in playback. (" + e.info.code + ")");
						break;
					case "NetStream.Play.StreamNotFound":
					case "NetConnection.Connect.Rejected":
					case "NetConnection.Connect.Failed":
						error("VideoPlayer - netStatusHandler - Error : File/Stream not found. (" + e.info.code + ")");
						break;
					/*case "NetStream.Seek.InvalidTime":
						// Seek to last available time
						seek(e.info.message.details);
						break;*/
					case "NetStream.FileStructureInvalid":
						error("VideoPlayer - netStatusHandler - Error : The MP4's file structure is invalid. (" + e.info.code + ")");
						break;
					case "NetStream.NoSupportedTrackFound":
						error("VideoPlayer - netStatusHandler - Error : The MP4 doesn't contain any supported tracks. (" + e.info.code + ")");
						break;
					
					/* Status */
					case "NetStream.Play.Stop":
						complete();
						break;
					case "NetStream.Seek.Notify":
						dispatchEvent(new MediaEvent(MediaEvent.SEEKED));
						break;
				}
			} catch (error:Error) {
				// Ignore this error
				errpr("VideoPlayer - netStatusHandler - Error : " + error.message);
			}
		}
		
		protected function timerHandler(e:TimerEvent):void {
			// Update Buffer
			var pos:int = Math.round(Math.min(_stream.time, duration) * 100) / 100;
			var bufferMax:int;
			if (duration > 0 && loadTotal > 0) {
				var remaining:Number = duration > 0 ? (duration - position) : position;
				bufferMax = _stream.bufferTime < remaining ? _stream.bufferTime : remaining;
			} else {
				bufferMax = loadTotal > 0 ? 100 : 0;
			}
			
			var bufferPercent:int = _stream.bufferTime ? _stream.bufferLength / bufferMax * 100 : 0;
			if (bufferPercent <= 50 && state == PlayerState.PLAYING && duration - position > 5) {
				_bufferFull = false;
				_stream.pause();
				state = PlayerState.BUFFERING;
			} else if (bufferPercent > 95 && !_bufferFull && bufferMax > 0) {
				_bufferFull = true;
				if (state == PlayerState.PAUSED) {
					_queuedBufferFull = true;
				} else {
					dispatchEvent(new MediaEvent(MediaEvent.BUFFER_FULL));
				}
			}
			
			// Update Loading
			if (!_loadComplete) {
				var loadPercent:uint;
				if (loadTotal > 0) {
					loadPercent = 100 * (loadCurrent / loadTotal);
				} else {
					loadPercent = loadCurrent > 0 ? 100 : 0; 
				}
				dispatchEvent(new MediaEvent(MediaEvent.LOAD_PROGRESS));
				if (loadPercent == 100 && _loadComplete == false) {
					_loadComplete = true;
					dispatchEvent(new MediaEvent(MediaEvent.LOAD_COMPLETE));
				}
			}
			
			// Update Position
			if (state != PlayerState.PLAYING) return;
			
			_position = pos;
			if (position < duration) {
				if (position >= 0) dispatchEvent(new MediaEvent(MediaEvent.PLAY_PROGRESS));
			} else if (duration > 0) {
				complete();
			}
		}
	}
}