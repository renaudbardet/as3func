package as3func.net
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import as3func.lang.BaseFuture;
	import as3func.lang.getCallerInfo;

	public class LoaderFuture extends BaseFuture
	{
		
		protected var request:URLRequest;
		private var loader:URLLoader;
		
		public function LoaderFuture( request:URLRequest, binary:Boolean = false )
		{
			super( binary ? ByteArray : String );
			this.request = request;
			this.loader = new URLLoader();
			if(binary) this.loader.dataFormat = URLLoaderDataFormat.BINARY;
			this.loader.addEventListener( Event.COMPLETE, onLoaderComplete );
			this.loader.addEventListener( ErrorEvent.ERROR, onError );
			this.loader.addEventListener( IOErrorEvent.IO_ERROR, onError );
			this.loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onError );
			
			FUTURE::debug {
				__debug_stack[0].pos = getCallerInfo();
			}
			
		}
		
		public function load():void {
			loader.load(request);
		}
		
		private function onLoaderComplete(e:Event):void
		{
			_complete(this.loader.data);
		}
		
		private function onError(e:Event):void
		{
			super._fail({type:e.type,error:this.loader.data});
		}
		
		override protected function _fail( value:* ):void {
			
			// relieve the network
			try{
				loader.close();
			} catch (e:*) {}
			
			super._fail(value);
			
		}
		
		public static function load( url:String, binary:Boolean = false ):LoaderFuture
		{
			
			var request:URLRequest = new URLRequest( url );
			
			var l:LoaderFuture = new LoaderFuture(request, binary);
			l.load();
			
			return l;
			
		}
		
		public static function post( url:String, data:Object ):LoaderFuture
		{
			
			var request:URLRequest = new URLRequest( url );
			var postData:URLVariables = new URLVariables();
			for(var key:String in data)
				postData[key] = data[key];
			request.data = postData;
			request.method = URLRequestMethod.POST;
			
			var l:LoaderFuture = new LoaderFuture( request );
			l.load();
			
			return l;
			
		}
		
	}
}