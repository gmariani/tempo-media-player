package com.coursevector.tempo.model {

    /**
    * Object that catches and forwards calls invoked by NetStream.
    **/
	public dynamic class NetClient {
		/** Function to callback all events to **/
		private var callback:Object;
		
		public static const BANDWIDTH:String = "bandwidth";
		public static const CAPTION:String = "caption";
		public static const CAPTION_INFO:String = "captionInfo";
		public static const CLOSE:String = 'close';
		public static const CUE_POINT:String = "cuePoint";
		public static const DRM_CONTENT_DATA:String = 'drmContentData';
		public static const DVR_SUBSCRIBE:String = 'dvrSubscribe';
		public static const DVR_UNSUBSCRIBE:String = 'dvrUnsubscribe';
		public static const FC_SUBSCRIBE:String = "fcSubscribe";
		public static const FC_UNSUBSCRIBE:String = "fcUnsubscribe";
		public static const FI:String = "fi";
		public static const IMAGE_DATA:String = "imageData";
		public static const LAST_SECOND:String = "lastSecond";
		public static const METADATA:String = "metadata";
		
		public static const PLAY_STATUS:String = "playStatus";
		public static const COMPLETE:String = 'complete';
		public static const TRANSITION:String = 'transition';
		
		public static const RTMP_SAMPLE_ACCESS:String = "RTMPSampleAccess";
		public static const SEEK_POINT:String = 'seekpoint';
		public static const TEXT_DATA:String = "textData";
		public static const XMP_DATA:String = 'xmpdata';
		
		/** Constructor. **/
		public function NetClient(cbk:Object):void {
			callback = cbk;
		}
		
		/** Forward calls to callback **/
		private function forward(data:Object, type:String):void {
			data['type'] = type;
			var o:Object = {};
			for (var i:Object in data) {
				o[i] = data[i];
			}
			callback.onClientData(o);
		}
		
		/**
		 * This is required by native bandwidth detection. It takes an argument,
		 * ...args. The function must return a value, even if the value is 0, to 
		 * indicate to the server that the client has received the data.
		 * 
		 * FMS 3.0
		 * 
		 * @param	...args
		 */
		public function onBWCheck(...args):Number {
			return 0;
		}
		
		/**
		 * The server calls the onBWDone() function when it finishes measuring 
		 * the bandwidth. It takes four arguments. The first argument it returns 
		 * is the bandwidth measured in Kbps. The second and third arguments are 
		 * not used. The fourth argument is the latency in milliseconds.
		 * 
		 * FMS 3.0
		 * 
		 * @param	...args
		 */
		public function onBWDone(...args):void {
			if (args.length > 0) {
				forward( { bandwidth:args[0], latency:args[3] }, BANDWIDTH);
			}
		}
		
		public function onCaption(cps:String, spk:Number):void {
            forward({captions:cps, speaker:spk}, CAPTION);
        }
		
		public function onCaptionInfo(obj:Object):void {
            forward(obj, CAPTION_INFO);
        }
		
		/** Get connection close from RTMP server. **/
		public function close(...args):void {
			forward({close: true}, COMPLETE);
		}
		
		/**
		 * Establishes a listener to respond when an embedded cue point is 
		 * reached while playing a video file. You can use the listener to 
		 * trigger actions in your code when the video reaches a specific cue 
		 * point, which lets you synchronize other actions in your application 
		 * with video playback events. For information about video file 
		 * formats supported by Flash Media Server, see the 
		 * www.adobe.com/go/learn_fms_fileformats_en.
		 * 
		 * The onCuePoint event object has the following properties:
		 * name	- The name given to the cue point when it was embedded in the 
		 * 		video file.
		 * parameters - An associative array of name and value pair strings 
		 * 		specified for this cue point. Any valid string can be used for 
		 * 		the parameter name or value.
		 * time	- The time in seconds at which the cue point occurred in the video 
		 * 		file during playback.
		 * type	- The type of cue point that was reached, either navigation or event.
		 * 
		 * You can define cue points in a video file when you first encode the 
		 * file, or when you import a video clip in the Flash authoring tool by 
		 * using the Video Import wizard.
		 * 
		 * The onMetaData event also retrieves information about the cue points 
		 * in a video file. However the onMetaData event gets information about 
		 * all of the cue points before the video begins playing. The onCuePoint 
		 * event receives information about a single cue point at the time 
		 * specified for that cue point during playback.
		 * 
		 * Generally, to have your code respond to a specific cue point at the 
		 * time it occurs, use the onCuePoint event to trigger some action in 
		 * your code.
		 * 
		 * You can use the list of cue points provided to the onMetaData event 
		 * to let the user start playing the video at predefined points along 
		 * the video stream. Pass the value of the cue point's time property to 
		 * the NetStream.seek() method to play the video from that cue point.
		 * 
		 * Flash 9
		 * 
		 * @param	obj
		 */
		public function onCuePoint(obj:Object):void {
			forward(obj, CUE_POINT);
		}
		
		/**
		 * Establishes a listener to respond when AIR extracts DRM content 
		 * metadata embedded in a media file.
		 * 
		 * A DRMContentData object contains the information needed to obtain 
		 * a voucher required to play a DRM-protected media file. Use the 
		 * DRMManager class to download the voucher with this information.
		 * 
		 * AIR 1.5
		 * 
		 * @param	obj
		 */
		public function onDRMContentData(obj:Object):void {
			forward(obj, DRM_CONTENT_DATA);
		}
		
		/**
		 * DVRCast
		 * 
		 * FMS 3.5
		 * 
		 * @param	obj
		 */
		public function onDVRSubscribe(obj:Object):void {
			forward(obj, DVR_SUBSCRIBE);
		}
		
		/**
		 * DVRCast
		 * 
		 * FMS 3.5
		 * 
		 * @param	obj
		 */
		public function onDVRUnsubscribe(obj:Object):void {
			forward(obj, DVR_UNSUBSCRIBE);
		}
		
		/**
		 * This functionality is used by CDN's such as Akamai, Edgecast 
		 * and Limelight for live streaming. It is also used by Wowza 
		 * Media Server for configuring multiple servers in a liveedge 
		 * / liverepeater setup.
		 * 
		 * @param	obj
		 */
		public function onFCSubscribe(obj:Object):void {
			forward(obj, FC_SUBSCRIBE);
		}
		
		public function onFCUnsubscribe(obj:Object):void {
			forward(obj, FC_UNSUBSCRIBE);
		}
		
		/**
		 * Flash Media Live Encoder contains a special built-in handler, 
		 * onFI, that subscribing clients can use in their ActionScript 
		 * code to access timecode information. The following client-side 
		 * ActionScript code shows how to get timecode information using 
		 * the onFI handler. The object ns is the NetStream object. You 
		 * can get timecode and system date and time information, if 
		 * timecode and system date and time were embedded in the stream, 
		 * by accessing the tc, sd, and st properties of the info object 
		 * that is passed as an argument to onFI().
		 * 
		 * tc - string formatted hh:mm:ss:ff
		 * sd - string formatted as dd-mm-yy
		 * st - string formatted as hh:mm:ss.ms
		 * 
		 * @param	obj
		 */
		public function onFI(obj:Object):void {
			forward(obj, FI);
		}
		
		/**
		 * Establishes a listener to respond when Flash Player receives image 
		 * data as a byte array embedded in a media file that is playing. The 
		 * image data can produce either JPEG, PNG, or GIF content. Use the 
		 * flash.display.Loader.loadBytes() method to load the byte array into 
		 * a display object.
		 * 
		 * The onImageData event object contains the image data as a byte array 
		 * sent through an AMF0 data channel.
		 * 
		 * Flash 9.0.115.0
		 * 
		 * @param	obj
		 */
		public function onImageData(obj:Object):void {
			forward(obj, IMAGE_DATA);
		}
		
		public function onLastSecond(obj:Object):void {
			forward(Object, LAST_SECOND));
		}
		
		/** 
		 * Establishes a listener to respond when Flash Player receives 
		 * descriptive information embedded in the video being played. 
		 * For information about video file formats supported by Flash 
		 * Media Server, see the www.adobe.com/go/learn_fms_fileformats_en.
		 *
		 * Handles the metadata returned. Possible data sent:
		 * <li>canSeekToEnd</li>
		 * <li>cuePoints</li>
		 * <li>audiocodecid</li>
		 * <li>audiodelay</li>
		 * <li>audiodatarate</li>
		 * <li>videocodecid</li>
		 * <li>framerate</li>
		 * <li>videodatarate</li>
		 * <li>height - Older version of encode</li>
		 * <li>width - Older version of encode</li>
		 * <li>duration - Older version of encode</li>
		 * 
		 * In many cases, the duration value embedded in stream metadata 
		 * approximates the actual duration but is not exact. In other 
		 * words, it does not always match the value of the NetStream.time 
		 * property when the playhead is at the end of the video stream.
		 * 
		 * The event object passed to the onMetaData event handler contains 
		 * one property for each piece of data.
		 * 
		 * Flash 9
		 * 
		 * @param	obj
		 */
		public function onMetaData(obj:Object, ...rest):void {
			if (rest && rest.length > 0) {
				rest.splice(0, 0, obj);
				forward({ arguments: rest }, METADATA);
			} else {
				forward(obj, METADATA);
			}
		}
		
		/**
		 * Establishes a listener to respond when a NetStream object has 
		 * completely played a stream. The associated event object provides 
		 * information in addition to what's returned by the netStatus event. 
		 * You can use this property to trigger actions in your code when a 
		 * NetStream object has switched from one stream to another stream in 
		 * a playlist (as indicated by the information object 
		 * NetStream.Play.Switch) or when a NetStream object has played to the 
		 * end (as indicated by the information object NetStream.Play.Complete).
		 * 
		 * NetStream.Play.Switch	"status"	Switching from one stream to another in a playlist.
		 * NetStream.Play.Complete	"status"	Playback has completed.
		 * NetStream.Play.TransitionComplete	"status"	Switching to a new stream as a result of stream bit-rate switching
		 * 
		 * Flash 9
		 * 
		 * @param	... rest
		 */
		public function onPlayStatus(...args):void {
			for each (var o:Object in args) {
				if (o && o.hasOwnProperty('code')) {
					if (o.code == "NetStream.Play.Complete") {
						forward(o, COMPLETE);
					} else if (o.code == "NetStream.Play.TransitionComplete") {
						forward(o, TRANSITION);
					}
				} 
			}
		}
		
		public function RtmpSampleAccess(obj:Object):void {
            forward(obj, RTMP_SAMPLE_ACCESS);
        }
		
		/**
		 * Called synchronously from appendBytes() when the append bytes parser
		 * encounters a point that it believes is a seekable point (for example, 
		 * a video key frame). Use this event to construct a seek point table. 
		 * The byteCount corresponds to the byteCount at the first byte of the 
		 * parseable message for that seek point, and is reset to zero as 
		 * described above. To seek, at the event NetStream.Seek.Notify, find the 
		 * bytes that start at a seekable point and call appendBytes(bytes). If 
		 * the bytes argument is a ByteArray consisting of bytes starting at the 
		 * seekable point, the video plays at that seek point.
		 * 
		 * Flash 10.1
		 * 
		 * @param	obj
		 */
		public function onSeekPoint(obj:Object):void {
			forward(obj, SEEK_POINT);
		}
		
		/**
		 * Gets cues from MP4 text tracks.
		 * 
		 * Text data embedded in a media file that is playing. The text data 
		 * is in UTF-8 format and can contain information about formatting 
		 * based on the 3GP timed text specification.
		 * 
		 * The onTextData event object contains one property for each piece 
		 * of text data.
		 * 
		 * Flash 9.0.115.0
		 * 
		 * @param	obj
		 */
		public function onTextData(obj:Object):void {
			forward(obj, TEXT_DATA);
		}
		
		/**
		 * Establishes a listener to respond when Flash Player receives 
		 * information specific to Adobe Extensible Metadata Platform (XMP) 
		 * embedded in the video being played. For information about video 
		 * file formats supported by Flash Media Server, see the 
		 * www.adobe.com/go/learn_fms_fileformats_en.
		 * 
		 * The object passed to the onXMPData() event handling function has 
		 * one data property, which is a string. The string is generated from 
		 * a top-level UUID box. (The 128-bit UUID of the top level box is 
		 * BE7ACFCB-97A9-42E8-9C71-999491E3AFAC.) This top-level UUID box 
		 * contains exactly one XML document represented as a null-terminated 
		 * UTF-8 string.
		 * 
		 * Flash 10
		 * 
		 * @param	obj
		 */
		public function onXMPData(obj:Object):void {
			forward(obj, XMP_DATA);
		}
	}
}