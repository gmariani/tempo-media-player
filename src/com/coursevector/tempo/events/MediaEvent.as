package com.coursevector.tempo.events {
	
	import flash.events.Event;
	
	public class MediaEvent extends Event {
		
		public static const CUE_POINT:String = "tempoCuePoint";
		public static const LOAD_PROGRESS:String = "tempoLoadProgress";
		public static const LOAD_COMPLETE:String = "tempoLoadComplete";
		public static const METADATA:String = "tempoMetadata";
		public static const ERROR:String = "tempoError";
		public static const BUFFER:String = "tempoBuffer";
		public static const BUFFER_FULL:String = "tempoBufferFull";
		public static const LOADED:String = "tempoLoaded";
		public static const PLAY_PROGRESS:String = "tempoPlayProgress";
		public static const PLAY_COMPLETE:String = "tempoPlayComplete";
		public static const SEEKING:String = "tempoSeeking";
		public static const SEEKED:String = "tempoSeeked";
		public static const STATE:String = "tempoState";
		public static const MUTE:String = "tempoMute";
		public static const VOLUME:String = "tempoVolume";
		public static const QUALITY_LEVELS:String = "tempoQualityLevels";
		public static const QUALITY_CHANGE:String = "tempoQualityChange";
		
		public var bufferPercent:Number 	= -1;
		public var duration:Number 			= -1;
		public var metadata:Object 			= null;
		public var position:Number 			= -1;
		public var offset:Number			= 0;
		public var volume:Number 			= -1;
		public var mute:Boolean				= false;
		public var levels:Array				= null;
		public var currentQuality:Number		= -1;
		
		public function MediaEvent(type:String) {
			super(type, false, false);
		}
		
		public override function clone():Event {
			var evt:MediaEvent = new MediaEvent(this.type);
			evt.bufferPercent = this.bufferPercent;
			evt.duration = this.duration;
			evt.metadata = this.metadata;
			evt.position = this.position;
			evt.offset = this.offset;
			evt.volume = this.volume;
			evt.mute = this.mute;
			evt.levels = this.levels;
			evt.currentQuality = this.currentQuality;
			return evt;
		}
		
		public override function toString():String {
			var retString:String = '[MediaEvent type="' + type + '"';
			var defaults:MediaEvent = new MediaEvent("");
			
			for (var s:String in metadata) {
				retString += ' ' + s + '="' + metadata[s] + '"';
			}
			
			if (bufferPercent != defaults.bufferPercent) retString += ' bufferPercent="' + bufferPercent + '"';
			if (duration != defaults.duration) retString += ' duration="' + duration + '"';
			if (position != defaults.position) retString += ' position="' + position + '"';
			if (offset != defaults.offset) retString += ' offset="' + offset + '"';
			if (volume != defaults.volume) retString += ' volume="' + volume + '"';
			if (mute != defaults.mute) retString += ' mute="' + mute + '"';
			if (levels != defaults.levels) retString += ' levels="' + levels + '"';
			if (currentQuality != defaults.currentQuality) retString += ' currentQuality="' + currentQuality + '"';
			if (message != defaults.message) retString += ' message="' + message + '"';
			
			//retString += ' id="' + id + '"'
			//retString += ' client="' + client + '"'
			//retString += ' version="' + version + '"'
			retString += "]";
			
			return retString;
		}
	}
}