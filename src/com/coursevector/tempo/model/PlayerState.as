package com.coursevector.tempo.model {
	
	/**
	 * Static typed list of all possible Model states
	 */
	public class PlayerState {
		/** Nothing happening. No playback and no file in memory. **/
		public static var IDLE:String = "IDLE";
		/** Buffering; will start to play when the buffer is full. **/
		public static var BUFFERING:String = "BUFFERING";
		/** The file is being played back. **/
		public static var PLAYING:String = "PLAYING";
		/** Playback is paused. **/
		public static var PAUSED:String = "PAUSED";
	}
}