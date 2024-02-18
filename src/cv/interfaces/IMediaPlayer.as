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

package cv.interfaces {
	
	import cv.data.MediaError;
	import flash.events.IEventDispatcher;
	
	/**
	 *  Implement the IMediaPlayer interface to create a custom media player. 
	 *  A media player handles audio or video playback.
	 */
	public interface IMediaPlayer extends IEventDispatcher {
		//--------------------------------------
		//  HTML Properties
		//--------------------------------------
		
		/** 
		 * Whether media will play automatically once loaded.
		 * 
		 * @default true
		 */
		function get autoPlay():Boolean;
		/** @private **/
		function set autoPlay(b:Boolean):void;
		
		function get buffer():int;
		/** @private **/
		function set buffer(n:int):void;
		
		function get currentSrc():String;
		
		/** 
		 * Returns the official playback position, in seconds.
		 * 
		 * Can be set, to seek to the given time.
		 */
		function get currentTime():Number;
		/** @private **/
		function set currentTime(n:Number):void;
		
		/** 
		 * Gets the total play time in seconds
		 */
		function get duration():Number;
		
		function get ended():Boolean;
		
		function get error():MediaError;
		
		function get loop():Boolean;
		/** @private **/
		function set loop(b:Boolean):void;
		
		/** 
		 * Gets or sets the muted state
		 */
		function get muted():Boolean;
		/** @private **/
		function set muted(b:Boolean):void;
		
		function get networkState():uint;
		
		/**
		 * Returns the pause status of the player.
		 */
		function get paused():Boolean;
		
		function get readyState():uint;
		
		function get seeking():Boolean
		
		function get src():String;
		/** @private **/
		function set src(str:String):void;
		
		/** 
		 * Gets or sets the current volume, from 0 - 1
		 */
		function get volume():Number;
		/** @private **/
		function set volume(n:Number):void;
		
		//--------------------------------------
		//  Flash Properties
		//--------------------------------------
		
		/** 
		 * Gets the current load progress in terms of bytes
		 */
		function get bytesLoaded():uint;
		
		/** 
		 * Gets the total size to be loaded in terms of bytes
		 */
		function get bytesTotal():uint;
		
		/** 
		 * Gets the metadata if available for the currently playing audio file
		 */
		function get metaData():Object;
		
		//--------------------------------------
		//  Methods
		//--------------------------------------
		
		function canPlayType(type:String):Boolean
		
		function load():void;
		
		function pause():void;
		
		function play():void;
		
		function unload():void;
	}
}