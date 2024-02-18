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
	 * The NetStreamPlayer class is a foundation class for RTMPPlayer and
	 * NetStreamPlayer to have a common set of code to work from.
	 * 
	 * <hr>
	 * <ul>
	 * <li>4.0.0
	 * <ul>
	 * 		<li>Refactored release</li>
	 * </ul>
	 * </li>
	 * </ul>
     */
	public class NetStreamPlayer extends MediaPlayer implements IMediaPlayer {
		
		protected var arrMIMETypes:Array = ["video/x-flv","video/mp4","audio/mp4","video/3gpp","audio/3gpp","video/quicktime","audio/mp4","video/x-m4v"];
		protected var arrFileTypes:Array = ["flv","f4v","f4p","f4b","f4a","3gp","3g2","mov","mp4","m4v","m4a","p4v"];
		
		protected var _stream:NetStream;
		protected var _timer:Timer = new Timer(100);
		protected var _video:Video = new Video(320, 240);
		protected var _conn:NetConnection;
		protected var _transform:SoundTransform;
		
		public function NetStreamPlayer(config:Config) {
			super(config);
		}
		
		//--------------------------------------
		//  Properties
		//--------------------------------------
		
		/** 
		 * Gets the current load progress in terms of bytes
		 */
		public function get loadCurrent():uint { return _stream ? _stream.bytesLoaded : 0 }
		
		/** 
		 * Gets the total size to be loaded in terms of bytes
		 */
		public function get loadTotal():uint { return _stream ? _stream.bytesTotal : 0 }
		
		/** 
		 * Gets or sets the reference to the display video object.
		 */
		public function get video():Video {	return _video }
		/** @private **/
		public function set video(v:Video):void {
			if (_video != v) {
				_video = v;
				_video.smoothing = config.smoothing;
				
				/*if (autoScale && item) {
					_video.width = item.width;
					_video.height = item.height;
				}*/
				if (_stream) _video.attachNetStream(_stream);
			}
		}
		
		/** 
		 * Gets or sets the current volume, from 0 - 1
		 */
		//public function get volume():Number { return _muted ? 0 : _volume }
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
		 * Validates if the given filetype is compatible to be played with NetStreamPlayer. 
		 * The acceptable file types are :
		 * <ul>
		 * <li>flv : video/x-flv Flash Video</li>
		 * <li>f4v : video/mp4 	Flash Video</li>
		 * <li>f4p : video/mp4 	Protected Flash Video</li>
		 * <li>f4b : audio/mp4 	Flash Audio Book</li>
		 * <li>f4a : audio/mp4 	Flash Audio</li>
		 * <li>3gp : video/3gpp  audio/3gpp	3GPP for GSM-based Phones</li>
		 * <li>3g2 : video/3gpp  audio/3gpp	3GPP2 for CDMA-based Phones</li>
		 * <li>mov : video/quicktime	QuickTime Movie</li>
		 * <li>mp4 : video/mp4 	H.264 MPEG-4 Video</li>
		 * <li>m4v : video/mp4 	H.264 MPEG-4 Video</li>
		 * <li>m4a : audio/mp4 	Audio-only MPEG-4</li>
		 * <li>p4v : audio/mp4 	Protected H.264 MPEG-4 Video</li>
		 * </ul>
		 * 
		 * @param ext The file extension to be validated
		 * @param url The full file url if the extension is not enough
		 * 
		 * @return Boolean of whether the extension was valid or not.
		 */
		public function isValid(ext:String, url:String):Boolean {
			var i:uint = arrFileTypes.length;
			while (i--) {
				if (arrFileTypes[i] == ext) {
					return true;
				}
			}
			
			return false;
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
		
		//--------------------------------------
		//  Private
		//--------------------------------------
		
		protected function errorHandler(e:ErrorEvent):void {
			error(e);
		};
		
		protected function updateSound():void {
			_transform.volume = _muted ? 0 : _volume;
			if (_stream) _stream.soundTransform = _transform;
		}
	}
}