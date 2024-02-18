package com.coursevector.tempo {
	
	import com.coursevector.media.RTMPPlayer;
	import com.greensock.*;
	import com.greensock.easing.*;
	import flash.display.LoaderInfo;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	
	/*
	 * Single player - no playlist
	 * Flash with HTML5 fallback
	 * Audio player
	 * Video Player
	 * RTMP/Amazon S3
	 * Variable bitrate
	 * Built-in UI
	 * Skinnable
	 * XML Configurable
	 * Analytics
	 * Small
	 * Wordpress
	 * 
	 */
	
	public class Tempo extends Sprite {
		
		// http://docs.sublimevideo.net/playlists
		// http://www.longtailvideo.com/support/jw-player/jw-player-for-flash-v5/12540/javascript-api-reference#Events
		protected const VERSION:String = "2.0.0";
		
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
		}
		
		private function initFlashVars():void {
			var fv:Object = LoaderInfo(this.loaderInfo).parameters;
			
			var config:Object = { };
			
			// Load config XML first if it exists
			if (fv.hasOwnProperty('config') && fv.config) {
				var xmlURL:String = fv.config;
			}
			
			// Overwrite any settings with other flashvars
			for (var key:String in fv) {
				if (key != 'config') config[key] = fv[key];
			}
			
			// Init Config
			for (var key:String in config) {
				switch (key) {
					case 'playlistfile': break; // undefined
					case 'duration': break;// 0
					case 'file': break;// undefined
					case 'image': break;// undefined
					case 'mediaid': break;// undefined
					case 'provider': break;// undefined
					case 'start': break;// 0
					case 'streamer': break;// undefined
					
					case 'controlbar.position': break;// over
					case 'controlbar.idlehide': break;// false
					case 'display.showmute': break;// false
					case 'dock': break;// true
					case 'icons': break;// true
					case 'skin': break;// undefined
					
					case 'autostart': break;// false
					case 'bufferlength': break;// 1
					case 'item': break;// 0
					case 'mute': break;// false
					case 'netstreambasepath': break;// undefined
					case 'playerready': break;// undefined
					case 'plugins': break;// undefined
					case 'repeat': break;// none
					case 'shuffle': break;// false
					case 'smoothing': break;// true
					case 'stretching': break;// uniform
					case 'volume': break;// 90
					
					case 'logo.file': break;// undefined
					case 'logo.link': break;// undefined
					case 'logo.linktarget': break;// _blank
					case 'logo.hide': break;// true
					case 'logo.margin': break;// 8
					case 'logo.position': break;// bottom-left
					case 'logo.timeout': break;// 3
					case 'logo.over': break;// 1
					case 'logo.out': break;// 0.5
					
					//'config' // undefined
				}
			}
		}
		
		private function initAPI():void {
			if (isEI) {
                try {
					// Methods
					aCb("load", 				function(playlist:*):void { } );
					aCb("pause", 				function(state:Boolean):void { } );
					aCb("play", 				function(state:Boolean):void { } );
					aCb("playlistItem", 		function(index:int):void { } );
					aCb("playlistNext", 		function():void { } );
					aCb("playlistPrev", 		function():void { } );
					aCb("seek", 				function(position:Number):void { } );
					aCb("stop", 				function():void { } );
					
					// Properties
					aCb("setBuffer", 			function(n:int):void { } );
					aCb("getBuffer", 			function():int { return } );
					
					aCb("setControls", 			function(b:Boolean):void { } );
					aCb("getControls", 			function():Boolean { return } );
					
					aCb("setFullscreen", 		function(b:Boolean):void { } );
					aCb("getFullscreen", 		function():Boolean { return } );
					
					aCb("setHeight", 			function(n:Number):void { } );
					aCb("getHeight", 			function():Number { return } );
					
					aCb("setMute", 				function(b:Boolean):void { } );
					aCb("getMute", 				function():Boolean { return } );
					
					aCb("setWidth", 			function(n:Number):void { } );
					aCb("getWidth", 			function():Number { return } );
					
					aCb("setVolume", 			function(n:Number):void { } );
					aCb("getVolume", 			function():Number { return } );
					
					// Variables
					aCb("getDuration", 			function():Number { } );
					aCb("getError", 			function():Object { } );
					aCb("getMetadata", 			function():Object { } );
					aCb("getPaused", 			function():Boolean { } );
					aCb("getPlaylist", 			function():Object { } );
					aCb("getPlaylistItem", 		function():Object { } );
					aCb("getPosition", 			function():Number { } );
					aCb("getSeeking", 			function():Boolean { } );
					aCb("getState", 			function():String { } );
					
					// Events
					// onEnd - end playing
					// onStart - start playing
					// onError - on error
					// onMeta - display meta in plugins?
					// onReady - api init
					// onResize - redraw plugins
                } catch (error:SecurityError) {
					trace("Tempo::constructor - " + error.message);
                } catch (error:Error) {
					trace("Tempo::constructor - " + error.message);
                }
            } else {
                trace("Tempo::constructor - External interface is not available.");
            }
		}
	}
}