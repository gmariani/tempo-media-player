package cv {
	
	import cv.controls.Slider;
	import cv.data.MediaError;
	import cv.data.NetworkState;
	import cv.data.Preload;
	import cv.data.ReadyState;
	import cv.events.TempoEvent;
	import cv.interfaces.IMediaPlayer;
	import fl.events.SliderEvent;
	import flash.display.BlendMode;
	import flash.events.ContextMenuEvent;
	import flash.text.TextFormat;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	//import cv.media.ImagePlayer;
	import cv.media.RTMPPlayer;
	//import cv.media.SoundPlayer;
	import cv.TempoLite;
	import flash.display.DisplayObject;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.ErrorEvent;
	import flash.events.FullScreenEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Rectangle;
	import flash.media.Video;
	import flash.utils.setInterval;
	
	import flash.display.MovieClip;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.display.Loader;
	import flash.events.IOErrorEvent;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.system.Security;
	
	import com.greensock.*;
	import com.greensock.easing.*;
	
	public class Tempo extends Sprite {
		
		protected var cmiMute:ContextMenuItem;
		protected var cmiLoop:ContextMenuItem;
		protected var cmiControls:ContextMenuItem;
		protected var cmiPlay:ContextMenuItem;
		
		protected var c:Function; // call
		protected var isEI:Boolean; // ExternalInterface.available
		protected var aCb:Function; // addCallback
		protected var tempo:TempoLite;
		//protected var sndP:SoundPlayer;
		protected var rtP:RTMPPlayer;
		protected var vidFullScreen:Video;
		protected var _preload:String = Preload.NONE;
		protected var _startDate:Date; // TODO: set when starts playing
		protected var _controls:Boolean = false;
		protected var _defaultMuted:Boolean = false; // TODO
		
		// Poster
		protected var ldr:Loader;
		protected var _poster:String;
		
		protected const VERSION:String = "1.0.2";
		
		public function Tempo() {
			c = ExternalInterface.call;
			aCb = ExternalInterface.addCallback;
			isEI = ExternalInterface.available;
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, resizeHandler);
			stage.addEventListener(Event.MOUSE_LEAVE, mouseHandler);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseHandler);
			
			// Tempo
			//sndP = new SoundPlayer();
			//sndP.debug = true;
			
			rtP = new RTMPPlayer();
			rtP.video = vidScreen;
			Video(vidScreen).smoothing = true;
			//rtP.debug = true;
			
			tempo = new TempoLite([rtP]);
			//tempo.addEventListener(MetaDataEvent.METADATA, tempoHandler); //MetaDataEvent
			//tempo.addEventListener(MetaDataEvent.CUE_POINT, tempoHandler);
			tempo.addEventListener(TempoEvent.ABORT, tempoHandler);
			tempo.addEventListener(TempoEvent.CAN_PLAY, tempoHandler);
			tempo.addEventListener(TempoEvent.CAN_PLAY_THROUGH, tempoHandler);
			tempo.addEventListener(TempoEvent.DURATION_CHANGE, tempoHandler);
			tempo.addEventListener(TempoEvent.EMPTIED, tempoHandler);
			tempo.addEventListener(TempoEvent.ENDED, tempoHandler);
			tempo.addEventListener(TempoEvent.ERROR, tempoHandler);
			tempo.addEventListener(TempoEvent.LOAD_START, tempoHandler);
			tempo.addEventListener(TempoEvent.LOADED_DATA, tempoHandler);
			tempo.addEventListener(TempoEvent.LOADED_METADATA, tempoHandler);
			tempo.addEventListener(TempoEvent.PAUSE, tempoHandler);
			tempo.addEventListener(TempoEvent.PLAY, tempoHandler);
			tempo.addEventListener(TempoEvent.PLAYING, tempoHandler);
			tempo.addEventListener(TempoEvent.PROGRESS, tempoHandler);
			tempo.addEventListener(TempoEvent.RATE_CHANGE, tempoHandler);
			tempo.addEventListener(TempoEvent.SEEKED, tempoHandler);
			tempo.addEventListener(TempoEvent.SEEKING, tempoHandler);
			tempo.addEventListener(TempoEvent.STALLED, tempoHandler);
			tempo.addEventListener(TempoEvent.SUSPEND, tempoHandler);
			tempo.addEventListener(TempoEvent.TIME_UPDATE, tempoHandler);
			tempo.addEventListener(TempoEvent.VOLUME_CHANGE, tempoHandler);
			tempo.addEventListener(TempoEvent.WAITING, tempoHandler);
			
			// Context Menu
			var menu:ContextMenu = new ContextMenu();
			menu.hideBuiltInItems();
			
			var cmiVersion:ContextMenuItem = new ContextMenuItem("Tempo Media Player " + VERSION);
			cmiVersion.enabled = false;
			
			cmiPlay = new ContextMenuItem("-Play");
			cmiPlay.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, contextMenuHandler);
			cmiPlay.separatorBefore = true;
			
			cmiMute = new ContextMenuItem("-Mute");
			cmiMute.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, contextMenuHandler);
			cmiMute.enabled = false;
			
			cmiLoop = new ContextMenuItem("-Loop");
			cmiLoop.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, contextMenuHandler);
			
			cmiControls = new ContextMenuItem("-Show controls");
			cmiControls.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, contextMenuHandler);
			cmiControls.enabled = false;
			
			menu.customItems.push(cmiVersion, cmiPlay, cmiMute, cmiLoop, cmiControls);
			this.contextMenu = menu;
			
			// Controls
			mcControls.visible = false;
			mcControls.mcPausePlay.stop();
			mcControls.mcPausePlay.addEventListener(MouseEvent.CLICK, controlsHandler);
			Slider(mcControls.mcPlayhead).enabled = false;
			Slider(mcControls.mcPlayhead).addEventListener(SliderEvent.CHANGE, controlsHandler);
			mcControls.mcMute.stop();
			mcControls.mcMute.addEventListener(MouseEvent.CLICK, controlsHandler);
			Slider(mcControls.mcVolume).liveDragging = true;
			Slider(mcControls.mcVolume).addEventListener(SliderEvent.CHANGE, controlsHandler);
			mcControls.mcFullScreen.addEventListener(MouseEvent.CLICK, controlsHandler);
			mcControls.txtTime.blendMode = BlendMode.LAYER;
			mcControls.txtTime.defaultTextFormat = new TextFormat(null, null, null, true)
			mcControls.txtTime.setTextFormat(new TextFormat(null, null, null, true));
			
			// FlashVar Support
			var fv:Object = LoaderInfo(this.loaderInfo).parameters;
			
			/**
			 * Move this FlashVar to the end so it's consistant when read in
			 */
			var src:String; 
			for (var key:String in fv) {
				var val:String = fv[key];
				if (key == "enableJS") {
					if (!isEmpty(val)) {
						if (!isEI) continue;
						if ((Security.sandboxType == "localWithFile" || Security.sandboxType == "localTrusted") && val != "true") {
							isEI = false;
						} else {
							isEI = Boolean(val);
						}
					}
				} else {
					if (key.toLowerCase() == 'streamHost') key = 'streamhost';
					if (key.toLowerCase() == 'autoplay') key = 'autoPlay';
					if (this.hasOwnProperty(key)) {
						if (!isEmpty(val)) {
							this[key] = val;
						}
					} else if (tempo.hasOwnProperty(key)) {
						if (!isEmpty(val)) {
							if (key.toLowerCase() == 'src') {
								src = val;
							} else {
								tempo[key] = val;
							}
						}
					} 
				}
			}
			
			// JavaScript Support
			if (isEI) {
                try {
					// Flash
					aCb("setStreamHost", 			function(str:String):void { streamhost = str; } );
					aCb("getStreamHost", 			function():String { return streamhost; } );
					
					// Fullscreen API
					aCb("requestFullscreen", 		toggleFullscreen ); // Method
					aCb("exitFullscreen", 			exitFullscreen ); // Method
					aCb("fullscreenEnabled", 		function():Boolean { return fullscreenEnabled; } );
					
					// HTMLVideoElement
					// preload [none, metadata, auto]
					aCb("setWidth", 				function(n:Number):void { vidScreen.width = n; } );
					aCb("getWidth", 				function():Number { return vidScreen.width; } );
					aCb("setHeight", 				function(n:Number):void { vidScreen.height = n; } );
					aCb("getHeight", 				function():Number { return vidScreen.height; } );
					aCb("videoWidth", 				function():Number { return vidScreen.width; } ); // ReadOnly
					aCb("videoHeight", 				function():Number { return vidScreen.height; } ); // ReadOnly
					aCb("setPoster", 				function(str:String):void { poster = str; } );
					aCb("getPoster", 				function():String { return poster; } );
					
					// HTMLMediaElement
					// error state
					aCb("error", 					function():MediaError { return tempo.error;  } ); // ReadOnly MediaError

					// network state
					aCb("setSrc", 					function(str:String):void { tempo.src = str; } );
					aCb("getSrc", 					function():String { return tempo.src; } );
					aCb("currentSrc", 				function():String { return tempo.currentSrc; } ); // ReadOnly
					//aCb("setCrossOrigin", 			function(str:String):void { crossOrigin = str; } ); // Doesn't apply to flash
					//aCb("getCrossOrigin", 			function():String { return crossOrigin;  } );
					aCb("networkState", 			function():uint { return tempo.networkState; } ); // ReadOnly
					aCb("setPreload", 				function(str:String):void { preload = str; } );
					aCb("getPreload", 				function():String { return preload;  } );
					aCb("buffered", 				function():Array { return buffered; } ); // ReadOnly TimeRanges
					aCb("load", 					tempo.load ); // Method
					aCb("canPlayType", 				canPlayType );
					
					// ready state
					aCb("readyState", 				function():uint { return tempo.readyState; } ); // ReadOnly
					aCb("seeking", 					function():Boolean { return tempo.seeking; } ); // ReadOnly
					
					// playback state
					aCb("setCurrentTime", 			function(n:Number):void { tempo.currentTime = n; } );
					aCb("getCurrentTime", 			function():Number { return tempo.currentTime; } );
					aCb("duration", 				function():Number { return tempo.duration;  } ); // ReadOnly
					aCb("startDate", 				function():Date { return startDate;  } ); // ReadOnly
					aCb("paused", 					function():Boolean { return tempo.paused;  } ); // ReadOnly
					aCb("setDefaultPlaybackRate", 	function(n:Number):void { } ); // Can't change play speed in Flash
					aCb("getDefaultPlaybackRate", 	function():Number { return 1; } );
					aCb("setPlaybackRate", 			function(n:Number):void { } ); // Can't change play speed in Flash
					aCb("getPlaybackRate", 			function():Number { return 1; } );
					aCb("played", 					function():Array { return []; } ); // ReadOnly TimeRanges
					aCb("seekable", 				function():Array { return []; } ); // ReadOnly TimeRanges
					aCb("ended", 					function():Boolean { return tempo.ended; } ); // ReadOnly
					aCb("setAutoplay", 				function(b:Boolean):void { tempo.autoPlay = b; } );
					aCb("getAutoplay", 				function():Boolean { return tempo.autoPlay; } );
					aCb("setLoop", 					function(b:Boolean):void { loop = b; } );
					aCb("getLoop", 					function():Boolean { return loop; } );
					aCb("play", 					tempo.play ); // Method
					aCb("pause", 					tempo.pause ); // Method
					
					// media controller - Not supported by majorbrowsers
					//aCb("setMediaGroup", 			function(str:String):void { } );
					//aCb("getMediaGroup", 			function():String { } );
					//aCb("setController", 			function(o:Object):void { } ); // MediaController
					//aCb("getController", 			function():Object { } ); // MediaController
					
					// controls
					aCb("setControls", 				function(b:Boolean):void { controls = b; } );
					aCb("getControls", 				function():Boolean { return controls;  } );
					aCb("setVolume", 				function(n:Number):void { tempo.volume = n } );
					aCb("getVolume", 				function():Number { return tempo.volume } );
					aCb("setMuted", 				function(b:Boolean):void { tempo.muted = b; } );
					aCb("getMuted", 				function():Boolean { return tempo.muted; } );
					aCb("setDefaultMuted", 			function(b:Boolean):void { defaultMuted = b; } );
					aCb("getDefaultMuted", 			function():Boolean { return defaultMuted; } );
					
					// tracks - Not supported by majorbrowsers
					//aCb("audioTracks", 			function():Object { } ); // ReadOnly AudioTrackList
					//aCb("videoTracks", 			function():Object { } ); // ReadOnly VideoTrackList
					//aCb("textTracks", 			function():Object { } ); // ReadOnly TextTrackList
					//aCb("addTextTrack", 			function(kind:String, label:String = '', language:String = ''):Object { } ); // TextTrack
                } catch (error:SecurityError) {
					trace("Tempo::constructor - " + error.message);
                } catch (error:Error) {
					trace("Tempo::constructor - " + error.message);
                }
            } else {
                trace("Tempo::constructor - External interface is not available.");
            }
			
			if (src) tempo.src = src;
		}
		
		protected function unlockUI():void {
			Slider(mcControls.mcPlayhead).enabled = true;
			cmiControls.enabled = true;
			cmiMute.enabled = true;
		}
		
		protected function lockUI():void {
			Slider(mcControls.mcPlayhead).enabled = false;
			cmiControls.enabled = false;
			cmiMute.enabled = false;
		}
		
		protected function mouseHandler(e:Event):void {
			if (e.type == Event.MOUSE_LEAVE) {
				if (!tempo.paused) TweenNano.to(mcControls, 0.5, {alpha:0});
			} else {
				if (stage.displayState == StageDisplayState.FULL_SCREEN) {
					if(mcControls.hitTestPoint(e.currentTarget.mouseX, e.currentTarget.mouseY)) {
						TweenNano.to(mcControls, 0.5, { alpha:1 } );
					} else {
						if (!tempo.paused) TweenNano.to(mcControls, 0.5, {alpha:0});
					}
				} else {
					TweenNano.to(mcControls, 0.5, { alpha:1 } );
				}
			}
		}
		
		protected function contextMenuHandler(e:ContextMenuEvent):void {
			var item:ContextMenuItem = e.target as ContextMenuItem;
			switch(item.caption) {
				case '-Play' :
				case '-Pause' :
					if (tempo.paused) {
						tempo.play();
					} else {
						tempo.pause();
					}
					break;
				case '-Mute' :
				case '-Unmute' :
					tempo.muted = !tempo.muted;
					break;
				case '-Loop' :
				case '-Looped' :
					loop = !loop;
					break;
				case '-Show controls' :
				case '-Hide controls' :
					controls = !controls;
					break;
			}
		}
		
		protected function controlsHandler(e:Event):void {
			switch(e.currentTarget) {
				case mcControls.mcPausePlay :
					unlockUI();
					if (tempo.paused) {
						tempo.play();
					} else {
						tempo.pause();
					}
					break;
				case mcControls.mcFullScreen :
					toggleFullscreen();
					break;
				case mcControls.mcMute :
					tempo.muted = !tempo.muted;
					Slider(mcControls.mcVolume).value = tempo.volume;
					break;
				case mcControls.mcVolume :
					tempo.volume = Slider(mcControls.mcVolume).value;
					if (tempo.muted) tempo.muted = false;
					break;
				case mcControls.mcPlayhead :
					tempo.currentTime = Slider(mcControls.mcPlayhead).value * tempo.duration;
					break;
			}
		}
		
		protected function autoSize(t:DisplayObject):void {
			if (!t) return;
			var newWidth:Number = (t.width * stage.stageHeight / t.height);
			var newHeight:Number = (t.height * stage.stageWidth / t.width);
			if (newHeight < stage.stageHeight) {
				t.width = stage.stageWidth;
				t.height = newHeight;
			} else if (newWidth < stage.stageWidth) {
				t.width = newWidth;
				t.height = stage.stageHeight;
			} else {
				t.width = stage.stageWidth;
				t.height = stage.stageHeight;
			}
			
			t.x = (stage.stageWidth - t.width) / 2;
			t.y = (stage.stageHeight - t.height) / 2;
		}
		
		protected function resizeHandler(e:Event = null):void {
			autoSize(ldr);
			autoSize(vidScreen);
			mcCatcher.width = stage.stageWidth;
			mcCatcher.height = stage.stageHeight;
			mcControls.y = stage.stageHeight - 35;
			
			/**
			 * At 400px wide, chrome starts to shrink volume and playhead at the same time
			 * There is a minimum width for sliders
			 * At 310px width the volume disappears
			 * At 240px wide the timer disappears
			 * At 160px width the playhead disappears
			 */
			var sWidth:Number = stage.stageWidth;
			var leftPadding:int = mcControls.mcPlayhead.x;
			var playHeadPadding:int = 3;
			var timePadding:int = 1;
			var mutePadding:int = 12;
			var volumePadding:int = 17;
			var fullScreenPadding:int = 18;
			
			mcControls.txtTime.visible = (sWidth > 240);
			mcControls.mcPlayhead.visible = (sWidth > 160);
			mcControls.mcVolume.visible = (sWidth > 310);
			var spaceAvailable:Number = sWidth - (leftPadding + playHeadPadding + (mcControls.txtTime.visible ? (mcControls.txtTime.width + timePadding) : 0) + mcControls.mcMute.width + mutePadding + (mcControls.mcVolume.visible ? (Slider(mcControls.mcVolume).width + volumePadding) : 10) + mcControls.mcFullScreen.width + fullScreenPadding);
			if (sWidth > 400) {
				// Scale playhead
				Slider(mcControls.mcPlayhead).width = spaceAvailable;
				mcControls.txtTime.x = mcControls.mcPlayhead.x + mcControls.mcPlayhead.width + playHeadPadding;
				mcControls.mcMute.x = mcControls.txtTime.x + mcControls.txtTime.width + timePadding;
				Slider(mcControls.mcVolume).width = 70;
				mcControls.mcVolume.x = mcControls.mcMute.x + mcControls.mcMute.width + mutePadding;
				mcControls.mcFullScreen.x = mcControls.mcVolume.x + mcControls.mcVolume.width + volumePadding;
			} else {
				if (sWidth > 310) {
					// Scale both volume and playhead
					var leftSpaceAvailable:Number = (sWidth / 2) - (leftPadding + playHeadPadding);
					Slider(mcControls.mcPlayhead).width = leftSpaceAvailable;
					mcControls.txtTime.x = mcControls.mcPlayhead.x + mcControls.mcPlayhead.width + playHeadPadding;
					mcControls.mcMute.x = mcControls.txtTime.x + mcControls.txtTime.width + timePadding;
					
					var rightSpaceAvailable:Number = (sWidth / 2) - (mcControls.txtTime.width + timePadding + mcControls.mcMute.width + mutePadding + mcControls.mcFullScreen.width + volumePadding + fullScreenPadding);
					Slider(mcControls.mcVolume).width = rightSpaceAvailable;
					mcControls.mcVolume.x = mcControls.mcMute.x + mcControls.mcMute.width + mutePadding;
					mcControls.mcFullScreen.x = mcControls.mcVolume.x + mcControls.mcVolume.width + volumePadding;
				} else {
					if (sWidth > 160) {
						// Scale playhead, lose time and volume
						Slider(mcControls.mcPlayhead).width = spaceAvailable;
						mcControls.txtTime.x = mcControls.mcPlayhead.x + mcControls.mcPlayhead.width + playHeadPadding;
						if (sWidth <= 240) {
							mcControls.mcMute.x = mcControls.mcPlayhead.x + mcControls.mcPlayhead.width + 12;
						} else {
							mcControls.mcMute.x = mcControls.txtTime.x + mcControls.txtTime.width + timePadding;
						}
						Slider(mcControls.mcVolume).width = 15;
						mcControls.mcVolume.x = mcControls.mcMute.x + mcControls.mcMute.width + mutePadding;
						if (sWidth <= 310) {
							mcControls.mcFullScreen.x = mcControls.mcMute.x + mcControls.mcMute.width + 12;
						} else {
							mcControls.mcFullScreen.x = mcControls.mcVolume.x + mcControls.mcVolume.width + volumePadding;
						}
					} else {
						// Lose Playhead
						//spaceAvailable = sWidth - (leftPadding + mcControls.mcMute.width + mutePadding + mcControls.mcFullScreen.width + fullScreenPadding);
						mcControls.mcMute.x = mcControls.mcPausePlay.x + mcControls.mcPausePlay.width + 12;
						mcControls.mcFullScreen.x = mcControls.mcMute.x + mcControls.mcMute.width + 12;
					}
				}
			}
			
			mcControls.mcBG.width = sWidth - 10;
		}
		
		protected function tempoHandler(e:TempoEvent):void {
			//trace('TempoEvent ' + e.type);
			switch (e.type) {
				case TempoEvent.PLAY :
					unlockUI();
					cmiPlay.caption = '-Pause';
					mcControls.mcPausePlay.gotoAndStop(2);
					TweenNano.to(mcControls, 0.5, {alpha:0});
					break;
				case TempoEvent.PAUSE :
					cmiPlay.caption = '-Play';
					mcControls.mcPausePlay.gotoAndStop(1);
					TweenNano.to(mcControls, 0.5, {alpha:1});
					break;
				case TempoEvent.VOLUME_CHANGE :
					if (tempo.muted) {
						mcControls.mcMute.gotoAndStop(2);
					} else {
						mcControls.mcMute.gotoAndStop(1);
					}
					cmiMute.caption = tempo.muted ? '-Unmute' : '-Mute';
					Slider(mcControls.mcVolume).value = tempo.volume;
					break;
				case TempoEvent.TIME_UPDATE :
					mcControls.txtTime.text = timeToString(tempo.currentTime);
					Slider(mcControls.mcPlayhead).value = tempo.currentTime / tempo.duration;
					break;
			}
			if (isEI) c('flashEvent', e.type);
		}
		
		protected function timeToString(n:int):String {
			var s:int = n;
			var m:int = int(s / 60);
			var h:int = int(m / 60);
			s = int(s % 60);
			return ((h) ? zero(h) + ':' : '') + zero(m) + ":" + zero(s);
		}
		
		protected function zero(n:int, isMS:Boolean = false):String {
			if(isMS) {
				if(n < 10) return "00" + n;
				if(n < 100) return "0" + n;
			}
			if (n < 10) return "0" + n;
			return "" + n;
		}
		
		protected function errorHandler(e:ErrorEvent):void {
			trace("Poster - Error : " + e.text);
		}
		
		protected function posterHandler(e:Event):void {
			autoSize(ldr);
		}
		
		public function get poster():String {
			return _poster;
		}
		
		public function set poster(str:String):void {
			_poster = str;
			
			// Cancel loading poster if one is in progress
			if (ldr && ldr.contentLoaderInfo) {
				if(ldr.contentLoaderInfo.bytesLoaded != ldr.contentLoaderInfo.bytesTotal) {
					ldr.close();
				} else {
					ldr.unload();
				}
				ldr.contentLoaderInfo.removeEventListener(Event.COMPLETE, posterHandler);
				this.removeChild(ldr);
				ldr = null;
			}
			
			if (!str) return;
			
			ldr = new Loader();
			ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, posterHandler, false, 0, true);
			ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHandler, false, 0, true);
			ldr.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler, false, 0, true);
			ldr.load(new URLRequest(_poster));
			this.addChildAt(ldr, 0);
		}
		
		public function get preload():String {
			return _preload;
		}
		
		public function set preload(str:String):void {
			switch (str) {
				case 'auto' :
				case 'metadata' :
				case 'none' :
				case '' :
					_preload = str;
					break;
				default : return;
			}
		}
		
		// In bytes not seconds like in html
		public function get buffered():Array {
			// Return all buffered segments
			var arr:Array = [];
			// start, end
			arr[0] = [0, tempo.bytesLoaded];
			
			return arr;
		}
		
		public function get startDate():Date {
			return _startDate;
		}
		
		public function get controls():Boolean {
			return _controls;
		}
		
		public function set controls(b:Boolean):void {
			_controls = b;
			cmiControls.caption = controls ? '-Hide controls' : '-Show controls';
			//cmiControls.checked = controls;
			mcControls.visible = b;
		}
		
		public function get loop():Boolean {
			return tempo.loop;
		}
		
		public function set loop(b:Boolean):void {
			tempo.loop = b;
			cmiLoop.caption = tempo.loop ? '-Looped' : '-Loop';
			//cmiLoop.checked = tempo.loop;
		}
		
		public function get defaultMuted():Boolean {
			return _defaultMuted;
		}
		
		public function set defaultMuted(b:Boolean):void {
			_defaultMuted = b;
		}
		
		public function get streamhost():String {
			return rtP.streamHost;
		}
		
		public function set streamhost(str:String):void {
			rtP.streamHost = str;
		}
		
		public function get fullscreenEnabled():Boolean {
			return (stage.displayState == StageDisplayState.FULL_SCREEN);
		}
		
		public function canPlayType(type:String):String {
			if (tempo.canPlayType(type)) return 'maybe';
			if (type == 'application/octet-stream') return 'probably';
			// if type is sketchy return 'maybe' otherwise blank
			return '';
		}
		
		public function toggleFullscreen():void {
			if (stage.displayState == StageDisplayState.FULL_SCREEN) {
				stage.displayState = StageDisplayState.NORMAL;
			} else {
				if (!vidFullScreen) vidFullScreen = new Video();
				vidFullScreen.width = vidScreen.videoWidth;
				vidFullScreen.height = vidScreen.videoHeight;
				vidFullScreen.x = 10000;
				vidFullScreen.y = 10000;
				stage.addChild(vidFullScreen);
				
				//rtP.video = vidFullScreen;
				
				/*var fullScreenRect:Rectangle = new Rectangle(vidFullScreen.x, vidFullScreen.y, vidFullScreen.width, vidFullScreen.height);
				var rectAspectRatio:Number = fullScreenRect.width / fullScreenRect.height;
				var screenAspectRatio:Number = stage.fullScreenWidth / stage.fullScreenHeight;
				
				if (rectAspectRatio > screenAspectRatio) {
					var newHeight:Number = fullScreenRect.width / screenAspectRatio;
					fullScreenRect.y -= ((newHeight - fullScreenRect.height) / 2);
					fullScreenRect.height = newHeight;
				} else if (rectAspectRatio < screenAspectRatio) {
					var newWidth:Number = fullScreenRect.height * screenAspectRatio;
					fullScreenRect.x -= ((newWidth - fullScreenRect.width) / 2);
					fullScreenRect.width = newWidth;
				}*/
				
				stage.addEventListener(FullScreenEvent.FULL_SCREEN, fullScreenHandler);
				stage.displayState = StageDisplayState.FULL_SCREEN;
			}
		}
		
		public function exitFullscreen():void {
			stage.displayState = StageDisplayState.NORMAL;
		}
		
		protected function fullScreenHandler(e:FullScreenEvent):void {
			mcControls.y = stage.stageHeight - 35;
			
			if (!e.fullScreen) {
				// On return from full screen
				if (vidFullScreen) {
					rtP.video = vidScreen;
					
					stage.removeChild(vidFullScreen);
					stage.removeEventListener(FullScreenEvent.FULL_SCREEN, fullScreenHandler);
				}
			} else {
				// On full screen
			}
		};
		
		protected function isEmpty(str:String):Boolean {
			if (!str) return true;
			return !str.length;
		}
	}
}