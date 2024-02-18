package cv.events {
	
	import flash.events.Event;
	
	public class TempoEvent extends Event {
		
		public static const LOAD_START:String = "loadstart";
		public static const PROGRESS:String = "progress";
		public static const SUSPEND:String = "suspend";
		public static const ABORT:String = "abort";
		public static const ERROR:String = "error";
		public static const EMPTIED:String = "emptied";
		public static const STALLED:String = "stalled";
		public static const LOADED_METADATA:String = "loadedmetadata";
		public static const LOADED_DATA:String = "loadeddata";
		public static const CAN_PLAY:String = "canplay";
		public static const CAN_PLAY_THROUGH:String = "canplaythrough";
		public static const PLAYING:String = "playing";
		public static const WAITING:String = "waiting";
		public static const SEEKING:String = "seeking";
		public static const SEEKED:String = "seeked";
		public static const ENDED:String = "ended";
		public static const DURATION_CHANGE:String = "durationchange";
		public static const TIME_UPDATE:String = "timeupdate";
		public static const PLAY:String = "play";
		public static const PAUSE:String = "pause";
		public static const RATE_CHANGE:String = "ratechange";
		public static const VOLUME_CHANGE:String = "volumechange";
		
		public function TempoEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
		}
		
		/**
		 * Creates a copy of the TempoEvent object and sets the value of each parameter to match
		 * the original.
		 *
         * @return A new TempoEvent object with parameter values that match those of the original.
		 */
		override public function clone():Event {
			return new TempoEvent(type, bubbles, cancelable);
		}
		
		/**
		 * Returns a string that contains all the properties of the TempoEvent object. The string
		 * is in the following format:
		 * 
		 * <p>[<code>VolumeEvent type=<em>value</em> bubbles=<em>value</em>
		 * 	cancelable=<em>value</em> </code>]</p>
		 *
         * @return A string representation of the VolumeEvent object.
		 */
		override public function toString():String {
			return formatToString("TempoEvent", "type", "bubbles", "cancelable", "eventPhase");
		}
	}
}