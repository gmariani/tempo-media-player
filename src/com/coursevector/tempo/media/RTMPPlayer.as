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
	import com.coursevector.tempo.model.NetClient;
	import com.coursevector.tempo.model.PlayerState;
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.ObjectEncoding;
	import flash.net.Responder;
	import flash.system.Capabilities;
	import flash.utils.Timer;
	
	//--------------------------------------
    //  Class description
    //--------------------------------------	
    /**
	 * <h3>Version:</h3> 4.0.0<br>
	 * <h3>Date:</h3> 10/19/2012<br>
	 * <h3>Updates At:</h3> http://blog.coursevector.com/tempolite<br>
	 * <br>
	 * The RTMPPlayer class is a facade for controlling loading, and playing
	 * of streaming video within Flash. It intelligently handles pausing, and
	 * loading.
	 * 
	 * <h3>Flash Media Server Feature List</h3><br>
	 * Closed Captioning - Adobe Media Server 5.0.1
	 * Alternate Audio - Adobe Media Server 5.0.1
	 * 
	 * HTTP Streaming Failover - Flash Media Server 4.5.2
	 * 24/7 Live Streaming - Flash Media Server 4.5.1
	 * Protected RTMP - Flash Media Server 4.5.1
	 * Distribute RTMFP Peer Introductions - Flash Media Server 4.5
	 * Set-level F4M/M3U8 files - Flash Media Server 4.5
	 * Audio-Only HTTP streaming - Flash Media Server 4.5
	 * Protected HTTP Dynamic Streaming - Flash Media Server 4.5
	 * Protected HTTP Live Streaming - Flash Media Server 4.5
	 * HTTP Dynamic Streaming packaging of on-demand content - Flash Media Server 4.5
	 * 
	 * RTMFP - Flash Media Server 4.0
	 * HTTP Dynamic Streaming - Flash Media Server 4.0
	 * Fast Dynamic Stream Switching - Flash Media Server 4.0
	 * 
	 * - Amazon CloudFront -
	 * Stream Reconnect - Flash Media Server 3.5.3
	 * Smart Seek - Flash Media Server 3.5.3
	 * Record and Watch (RAW) - Flash Media Server 3.5.3
	 * Dynamic Streaming - Flash Media Server 3.5
	 * 
	 * RTMPE (Encrypted) - Flash Media Server 3.0
	 * RTMPTE (Tunneled) - Flash Media Server 3.0
	 * 
	 * AS2
	 * RTMPS (SSL) - Flash Media Server 2.0
	 * HTTP Tunneling - Flash Communication Server MX 1.5
	 * ? - Flash Communication Server MX 1.0
	 * 
	 * NetConnection.call('DVRGetStreamInfo') - DVRCast
	 * NetConnection.call('secureTokenResponse') - Wowza
	 * 
	 * <h3>Flash Media Server Ports List</h3><br>
	 * Port 		/ Protocol 				/ Transport
	 * ------------------------------------------------
	 * 1935 		/ RTMP/E 				/ TCP
	 * 1935 		/ RTMFP 				/ UDP
	 * 80 			/ RTMP/E, RTMTP, HTTP 	/ TCP
	 * 19350-65535 	/ RTMFP 				/ UDP
	 * 8134 		/ HTTP 					/ TCP
	 * 1111 		/ HTTP, RTMP 			/ TCP
	 * 443 			/ RTMPS 				/ TCP
	 * 
	 * <hr>
	 * <ul>
	 * <li>4.0.0
	 * <ul>
	 * 		<li>Refactored release</li>
	 * 		<li>TODO: StageVideo</li>
	 * 		<li>TODO: Dynamic Streaming</li>
	 * 		<li>TODO: Tunneling</li>
	 * 		<li>TODO: SSL/Encrypted</li>
	 * </ul>
	 * </li>
	 * </ul>
     */
	public class RTMPPlayer extends NetStreamPlayer implements IMediaPlayer {
		
		protected var _bandwidthChecked:Boolean;
		protected var _bandwidthSwitch:Boolean;
		protected var _bufferFull:Boolean;
		private var _currentFile:String;
		protected var _dynamicAvailable:Boolean = false;
		protected var _isStreaming:Boolean;
		protected var _maxRetry:int = 5;
		private var	_lockOnStream:Boolean = false;
		private var _responded:Boolean;
		// Used to monitor when to switch streams
		protected var _streamHistory:Array;
		protected var _streamTimer:Timer = new Timer(1000);
		// Used to connect to a live stream
		protected var _subscribeCount:int;
		protected var _subscribeTimer:Timer;
		private var _timeOffset:Number = -1;
		private var _transitionLevel:Number = -1;
		// Set if the duration comes from the configuration
		protected var _userDuration:Boolean;
		
		public function RTMPPlayer(config:Config) {
			super(config);
			
			_conn = new NetConnection();
            _conn.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
            _conn.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
            _conn.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
            _conn.addEventListener(AsyncErrorEvent.ASYNC_ERROR, errorHandler);
			// AMF3 for FMS3+, AMF0 for FMS2 and below
            _conn.objectEncoding = config.encoding; // Default to AMF0
            _conn.client = new NetClient(this);
			
			_transform = new SoundTransform();
			
			_timer.addEventListener(TimerEvent.TIMER, timerHandler);
			
			_subscribeTimer = new Timer(1000, _maxRetry);
			_subscribeTimer.addEventListener(TimerEvent.TIMER_COMPLETE, subscribeHandler);
			
			_streamTimer.addEventListener(TimerEvent.TIMER_COMPLETE, streamHandler);
		}
		
		//--------------------------------------
		//  Properties
		//--------------------------------------
		
		/** 
		 * Gets the object encodeing for use with streaming servers.
		 */
		public function get objectEncoding():uint { return _conn.objectEncoding }
		
		// We assume it's a livestream until we hear otherwise.
		protected function get isLiveStream():Boolean { return (!(duration > 0) && _stream) }
		
		//--------------------------------------
		//  Methods
		//--------------------------------------
		
		/**
		 * Adds a context header to the Action Message Format (AMF) packet structure. 
		 * This header is sent with every future AMF packet. If you call 
		 * NetConnection.addHeader() using the same name, the new header replaces the 
		 * existing header, and the new header persists for the duration of the 
		 * NetConnection object. You can remove a header by calling 
		 * NetConnection.addHeader() with the name of the header to remove an 
		 * undefined object.
		 * 
		 * @param	operation Identifies the header and the ActionScript object 
		 * data associated with it.
		 * @param	mustUnderstand A value of true indicates that the server must 
		 * understand and process this header before it handles any of the 
		 * following headers or messages. 
		 * @param	param Any ActionScript object. 
		 */
		public function addHeader(operation:String, mustUnderstand:Boolean = false, param:Object = null):void {
			if (_conn) _conn.addHeader(operation, mustUnderstand, param);
		}
		
		/**
		 * Invokes a command or method on Flash Media Server or on an 
		 * application server running Flash Remoting.
		 * 
		 * @param	command A method specified in the form [objectPath/]method. 
		 * For example, the someObject/doSomething command tells the remote 
		 * server to invoke the clientObject.someObject.doSomething() method, 
		 * with all the optional ... arguments parameters. If the object path 
		 * is missing, clientObject.doSomething() is invoked on the remote server.
		 * @param	responder	An optional object that is used to handle return 
		 * values from the server. The Responder object can have two defined 
		 * methods to handle the returned result: result and status. If an error 
		 * is returned as the result, status is invoked; otherwise, result is 
		 * invoked. The Responder object can process errors related to specific 
		 * operations, while the NetConnection object responds to errors related 
		 * to the connection status.
		 * @param	... rest Optional arguments that can be of any ActionScript 
		 * type, including a reference to another ActionScript object. These 
		 * arguments are passed to the method specified in the command parameter 
		 * when the method is executed on the remote application server. 
		 */
		public function call(command:String, responder:Responder, ... rest):void {
			if (_conn) _conn.call(command, responder, rest);
		}
		
		override public function isValid(ext:String, url:String):Boolean {
			var isValid:Boolean = super.isValid(ext, url);
			var isRTMPValid:Boolean = true;
			if (streamHost != null) isRTMPValid = (streamHost.toLowerCase().indexOf("rtmp://") != -1);
			return isValid && isRTMPValid;
		}
		
		override public function load(newItem:*):void {
			if (!newItem) {
				throw new Error("RTMPPlayer - load : Must enter a valid url or MediaItem to load a file");
				return;
			}
			if (newItem is String) newItem = new MediaItem(newItem);
			
			_position = 0;
			_bufferFull = false;
			_bandwidthSwitch = false;
			_userDuration = (newItem.duration > 0);
			
			// TODO: What is this for?
			if (_timeOffset < 0) _timeOffset = item.start;
			
			//if (item.levels.length > 0) { item.setLevel(item.getLevel(config.bandwidth, config.width)); }
			
			//var ext:String = Strings.extension(item.file);
			/*if (ext == 'mp3' || item.file.substr(0,4) == 'mp3:' || ext == 'aac' || ext == 'm4a') {
				media = null;
			} else if (!media) {
				media = _video;
			}*/
			
			super.load(newItem);
			
			_timer.stop();
			
			try {
			    _responded = false;
				//_conn.connect(item.streamer);
				
				var args:Array = item.connection ? item.connection.slice() : [];
				args.unshift(item.streamer);
				_conn.connect.apply(this, args);
			} catch(e:Error) {
				error("Could not connect to application: " + e.message);
			}
			
			state = PlayerState.BUFFERING;
			_muted = config.mute;
			volume = config.volume;
		}
		
		public function onClientData(data:Object):void {
			if (!data) return;
			
			//if (autoScale) {
			if (data.width) { // data.hasOwnProperty("width")
				_video.width = data.width;
				_video.height = data.height;
				//super.resize(_width, _height);
			}
			
			switch (data.type) {
				case NetClient.FC_SUBSCRIBE :
					if (data.code == "NetStream.Play.StreamNotFound") {
						error("Subscription failed: " + item.file);
					} else if (data.code == "NetStream.Play.Start" && !_stream) {
						_subscribeTimer.stop(); // moved here, shouldn't stop after the first failure..right?
						createStream();
					}
					// _subscribeTimer.stop();
					break;
				case NetClient.METADATA :
					if (data.code == 'NetStream.Play.TransitionComplete') {
						if (_transitionLevel >= 0) _transitionLevel = -1;
					} else {
						if (data.duration && !_userDuration) item.duration = data.duration;
					}
					break;
				case NetClient.COMPLETE' :
					clearInterval(_positionInterval);
					complete();
					break;
				case NetClient.CLOSE :
					stop();
					break;
				case NetClient.BANDWIDTH :
					config.bandwidth = data.bandwidth;
					if (_bandwidthSwitch) {
						_bandwidthSwitch = false;
						createStream();
					}
					break;
			}
			dispatchEvent(new MediaEvent(MediaEvent.METADATA));
		}
		
		override public function pause():void {
            if (_stream) {
                if (isLivestream) {
                    _stream.close();
                } else { 
                    _stream.pause();
                }
            }/* else {
                _lockOnStream = true;
            }*/
			super.pause();
        };
		
		override public function play():void {
			_timer.start();
			/*if (_lockOnStream) {
				_lockOnStream = false;
				if (_stream) {
					seek(_timeOffset);
				} else {
					setStream();
				}
			} else */
			// Only play if paused, maybe to not hassle the server as much?
			if (state == PlayerState.PAUSED) {
			    if (isLivestream) {
					// Play a live stream as denoted by the -1
					_stream.play(getID(item.file), -1);
		        } else { 
				    _stream.resume();
	            }
			}
			super.play();
        }
		
		override public function seek(pos:Number, play:Boolean=true):void {
			/*var loaded:Number = loadTotal > 0 ? (loadCurrent / loadTotal * duration) : 0;
			if (pos <= loaded) {
				super.seek(pos);
				_timer.stop();
				_stream.seek(pos);
				dispatchEvent(new MediaEvent(MediaEvent.SEEKING));
				if (play) play();
			}*/
			
			
			_transitionLevel = -1;
			
			// TODO: What is this for?
			_timeOffset = pos;
            _timer.stop();
			/*if (item.levels.length > 0 && item.getLevel(config.bandwidth, config.width) != item.currentLevel) {
                item.setLevel(item.getLevel(config.bandwidth, config.width));
            }*/
			
			// Why is this here?
			//if (state == PlayerState.PAUSED) play();
			
			// If file/stream has changed, play stream then seek
			if (_currentFile != item.file) {
				_currentFile = item.file;
				try {
					_stream.play(getStreamName(item));
					if (_dynamicAvailable) {
						_streamHistory = [];
						_streamTimer.start();
					}
				} catch(e:Error) {
					trace2("Error: " + e.message);
				}
			}
			
			if ((_timeOffset > 0 || _position > _timeOffset || state == PlayerState.IDLE)) {
				_bufferFull = false;
				state = PlayerState.BUFFERING;
				_stream.seek(pos);
			}
			
			_isStreaming = true;
			_timer.start();
		}
		
		override public function stop():void {
			// Ever start streaming?
			if (_stream && _stream.time) _stream.close();
			
			_stream = null;
			_isStreaming =  false;
			_currentFile = undefined;
			_video.clear();
			_connection.close();
			_timer.stop();
			_timeOffset = -1;
			_subscribeCount = 0;
			_streamInfo = [];
			_subscribeTimer.stop();
			super.stop();
		}
		
		//--------------------------------------
		//  Private
		//--------------------------------------
		
		// Disregard IDLE state
		override protected function complete():void {
			stop();
			dispatchEvent(new MediaEvent(MediaEvent.PLAY_COMPLETE));
		}
		
		protected function createStream():void {
			_stream = new NetStream(_conn);
			_stream.checkPolicyFile = true;
			_stream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			_stream.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			_stream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			_stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, errorHandler);
			_stream.bufferTime = (item.subscribe || _dynamicAvailable) ? 4 : config.bufferlength;
			_stream.client = new NetClient(this);
			
			if (_video) _video.attachNetStream(_stream);
			updateSound();
			//if (!_lockOnStream) seek(_timeOffset);
		}
		
		protected function getStreamName(obj:Object):String {
			if (!obj.stream) {
				var url:String = obj.file;
				var parts:Array = url.split("?");
				var ext:String = parts[0].substr(-4);
				parts[0] = parts[0].substr(0, parts[0].length-4);
				if (url.indexOf(':') > -1) {
					//
				} else if (ext == '.mp3') {
					url = 'mp3:' + parts.join("?");
				} else if (ext == '.mp4' || ext == '.mov' || ext == '.m4v' || ext == '.aac' || ext == '.m4a' || ext == '.f4v') {
					url = 'mp4:' + url;
				} else if (ext == '.flv') {
					url = parts.join("?");
				} else {
					//
				}
				obj.stream = url;
			}
			return obj.stream;
        }
		
		override protected function netStatusHandler(e:NetStatusEvent):void {
			_responded = true;
			switch (e.info.code) {
				case 'NetConnection.Connect.Success':
					// Verify that Dynamic Streaming is available
					if (e.info.data) {
						var flashVersion:Number = Number(Capabilities.version.split(' ')[1].split(',', 1));
						var fmsVersion:Number = Number(e.info.data.version.split(',', 2).join('.'));
						_dynamicAvailable = (flashVersion >= 10 && fmsVersion >= 3.5);
					}
					
					if (item['subscribe']) {
						// Attempt to connect to live stream...
						_subscribeTimer.start();
					} else {
						// Only check bandwidth if we'll be switching streams
						if (_dynamicAvailable) {
							if (_bandwidthChecked) {
								createStream();
							} else {
								_bandwidthChecked = true;
								_bandwidthSwitch = true;
								
								/**
								 * checkBandwidth FMS 3.0
								 * To use this method to detect client bandwidth, you must 
								 * also define onBWDone() and onBWCheck() methods
								 */
								call('checkBandwidth', null);
							}
						} else {
							createStream();
						}
						
						/**
						 * getStreamLength FMS 3.0
						 * Returns the length of a stream, in seconds.
						 */
						call("getStreamLength", new Responder(streamLengthHandler), getStreamName(item));
					}
                    break;
                case 'NetStream.Seek.Notify':
					_timer.start();
					dispatchEvent(new MediaEvent(MediaEvent.SEEKED));
                    break;
                case 'NetConnection.Connect.Rejected':
                    try {
                        if (e.info.ex.code == 302) {
                            item.streamer = e.info.ex.redirect;
                            setTimeout(load, 100, item);
                            return;
                        }
                    } catch (err:Error) {
						error(e.info['description'] ? e.info['description'] : e.info.code); 
                    }
                    break;
				case 'NetStream.Failed':
                case 'NetStream.Play.StreamNotFound':
                    if (!_isStreaming) {
                        onClientData({type: NetClient.COMPLETE});
                    } else {
						error("Stream not found: " + item.file);
                    }
                    break;
				case 'NetStream.Seek.Failed':
					if (!_isStreaming) {
						onClientData({type: NetClient.COMPLETE});
					} else {
						error("Could not seek: " + item.file);
					}
					break;
				case 'NetConnection.Connect.Closed':
					stop();
					break;
				case 'NetConnection.Connect.Failed':
					if(item.streamer.substr(0,5) == 'rtmpt') { 
						error("Server not found: " + item.streamer);
					} else { 
						_responded = false;
					}
					break;
                case 'NetStream.Play.UnpublishNotify':
                    stop();
                    break;
				case 'NetStream.Buffer.Full':
					if (!_bufferFull) {
						_bufferFull = true;
						dispatchEvent(new MediaEvent(MediaEvent.BUFFER_FULL));
					}
					break;
				case 'NetStream.Play.Transition':
					onClientData(e.info);
					break;
            }
			dispatchEvent(new MediaEvent(MediaEvent.METADATA));
        }
		
		protected function subscribeHandler(e:TimerEvent):void {
			_subscribeCount++;
			if (_subscribeCount != _maxRetry) {
				/*if(item.levels && item.levels.length > 1) { 
					for(var i:Number=0; i<item.levels.length; i++) { 
						_conn.call("FCSubscribe", null, getStreamName(item.levels[i]));
					}
				} else {*/
					_conn.call("FCSubscribe", null, getStreamName(item));
				//}
			} else {
				stop();
				error("Subscribing to the live stream timed out.");
				_subscribeTimer.stop();
			}
		}
		
		protected function streamHandler(e:TimerEvent):void {
			// No stream or different levels?
			if (!_stream || (item.levels.length == 0)) {
				_streamTimer.stop();
				return;
			}
			
			try {
				var bwd:Number = Math.round(_stream.info.maxBytesPerSecond * 8 / 1024);
				var drf:Number = _stream.info.droppedFrames;
				var stt:String = state;
				_streamHistory.push({bwd:bwd,drf:drf,stt:stt});
				
				// Wait 5+ seconds and state is playing
				var len:Number = _streamHistory.length;
				if (len > 5 && state == PlayerState.PLAYING) {
					// Average bandwidth for last 5 seconds
					bwd = Math.round((_streamHistory[len-1].bwd + _streamHistory[len-2].bwd + _streamHistory[len-3].bwd + _streamHistory[len-4].bwd + _streamHistory[len-5].bwd) / 5);
					
					config.bandwidth = bwd;
					
					// Don't trust framedrops when player buffered during last samplings.
					if(_streamHistory[len-2].stt == PlayerState.BUFFERING || _streamHistory[len-3].stt == PlayerState.BUFFERING) {
						drf = 0;
					} else {
						drf = Math.round((_streamHistory[len-1].drf - _streamHistory[len-3].drf) * 5) / 10;
					}
					
					// Get stream based on available bandwidth
					var lvl:Number = item.getLevel(bwd, config.width);
					
					// Is this a different level?
					if (lvl != item.currentLevel) {
						trace2("swapping to another level b/c of bandwidth", bwd);
						swap(lvl);
					}
					
					// Too many dropped frames and not at lowest level?
					if (drf > 10 && item.currentLevel < item.levels.length - 1) {
						/*var clvl:Number = item.currentLevel;
						item.blacklistLevel(clvl);
						setTimeout(unBlacklist, 30000, clvl);*/
						trace2("swapping to another level b/c of framedrops", drf);
						swap(lvl);
					}
					
					dispatchEvent(new MediaEvent(MediaEvent.METADATA));
				}
			} catch(e:Error) {
				trace2("There was an error attempting to get stream info: " + e.message);
			}
		}
		
		protected function streamLengthHandler(len:Number):void {
			if(len && !_userDuration) {
				item.duration = len; 
				dispatchEvent(new MediaEvent(MediaEvent.METADATA));
			}
		}
		
		/** Dynamically switch streams **/
		private function swap(newLevel:Number):void {
			if (_transitionLevel == -1 && (newLevel < item.currentLevel || 
				_stream.bufferLength < _stream.bufferTime * 1.5 || item.levels[item.currentLevel].blacklisted)) {
				_transitionLevel = newLevel;
				item.setLevel(newLevel);
				var nso:NetStreamPlayOptions = new NetStreamPlayOptions();
				nso.streamName = getID(item.file);
				nso.transition = NetStreamPlayTransitions.SWITCH;
				clearInterval(_streamInfoInterval);
				_streamInfo = new Array();
				_streamInfoInterval = setInterval(getStreamInfo, 1000);
				_stream.play2(nso);
			}
		}
		
		
		
		protected function timerHandler(e:TimerEvent):void {
			// Update Buffer
			var pos:int = Math.round(Math.min(_stream.time, duration) * 100) / 100;
			var bufferPercent:int = _stream.bufferLength / _stream.bufferTime * 100;
			if (bufferPercent <= 25 && state != PlayerState.BUFFERING && duration - position > 5) {
				_bufferFull = false;
				state = PlayerState.BUFFERING;
			} else if (bufferPercent > 100 && !_bufferFull && state != PlayerState.PLAYING) {
				_bufferFull = true;
				dispatchEvent(new MediaEvent(MediaEvent.BUFFER_FULL));
			}
			
			// Update Position
			if (state != PlayerState.PLAYING) return;
			
			if (position < duration) {
				_position = pos;
				dispatchEvent(new MediaEvent(MediaEvent.PLAY_PROGRESS));
			} else if (position > 0 && duration > 0) {
				_stream.pause();
				_timer.stop();
				complete();
			}
		}
	}
}