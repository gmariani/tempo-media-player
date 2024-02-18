package cv.data {
	
	public class MediaError {
		
		/**
		 * The fetching process for the media resource was aborted by the user agent at the user's request.
		 */
		public static const MEDIA_ERR_ABORTED:uint = 1;
		
		/**
		 * A network error of some description caused the user agent to stop fetching the media resource, 
		 * after the resource was established to be usable.
		 */
		public static const MEDIA_ERR_NETWORK:uint = 2;
		
		/**
		 * An error of some description occurred while decoding the media resource, after the resource was 
		 * established to be usable.
		 */
		public static const MEDIA_ERR_DECODE:uint = 3;
		
		/**
		 * The media resource indicated by the src attribute was not suitable.
		 */
		public static const MEDIA_ERR_SRC_NOT_SUPPORTED:uint = 4;
		
		private var _code:uint;
		
		public function MediaError(code:uint) {
			_code = code;
		}
		
		public function get code():uint { return _code; }
	}
}