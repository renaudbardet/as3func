package as3func.lang
{
	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class Future extends BaseFuture
	{
		
		public function Future( typeConstraint:Class = null )
		{
			super( typeConstraint );
			
			FUTURE::debug {
				__debug_stack[0].pos = getCallerInfo();
			}
			
		}
		
		/**
		 * trigger the completion of the Future and the call to every referenced callback
		 * @param res	an optional data object
		 */
		public function complete( res:* = null ):void
		{
			
			this._completeEither( Either.Right( res ) );
			
		}
		
		/**
		 * trigger the failed completion of the Future and the call to every referenced error related callback
		 * @param error	an optional error
		 */
		public function fail( error:* = null ):void
		{
			
			this._completeEither( Either.Left( error ) );
			
		}
		
		/**
		 * trigger the completion of the Future with a result either right or erroneous
		 * @param res	an Either of type Left(error) or Right(data)
		 */
		public function completeEither( res:Either ):void
		{
			
			this._completeEither( res );
			
		}
		
		/**
		 * bind the completion or failure of this Future to the completion or failure of f2
		 * when f2 completes this Future will complete, and if f2 fails this Future will fail
		 * 
		 * @param f2	a Future
		 * @return 		this object
		 * 
		 */
		public function bind( f2:IFuture ) : IFuture
		{
			
			return _bind( f2 );
			
		}
		
		/**
		 * bind the completion or failure of this Future to the completion or failure of f2 and vice-versa
		 * either one of this or f2 completing or failing first will trigger the completion or failing of the other
		 * 
		 * @param f2	a Future
		 * @return 		this object
		 * 
		 */
		public function sync( f2:Future ):IFuture
		{
			
			f2.onResult( this._completeEither );
			this.onResult( f2._completeEither );
			return this;
			
		}
		
		/**
		 * fail this Future if f2 is complete first and vice-versa
		 * in both cases the failed Future will receive the data of the completed Future as an error
		 * 
		 * @see #unless()
		 * 
		 * @param f2	a Future
		 * @return 		this object
		 * 
		 */
		public function mutex( f2:Future ):void
		{
			
			this.onSuccess( f2.fail );
			f2.onSuccess( this.fail );
			
		}
		
		// ----------------------
		// secondary constructors
		
		/**
		 * create a Future as a copy of any IFuture
		 */
		public static function fromFuture(f:IFuture):Future
		{
			
			var proxy:Future = new Future();
			
			FUTURE::debug {
				proxy.__debug_stack[0].fct = "fromFuture (wrapper)";
				proxy.__debug_stack[0].pos = getCallerInfo();
				if( f is BaseFuture )
					proxy.__debug_stack = f["__debug_stack"].concat( proxy.__debug_stack );
			}
			
			proxy.bind( f );
			return proxy;
			
		}
		
		/**
		 * Create a Future from an EventDispatcher
		 * the event listener function will be removed once the event is triggered
		 *  
		 * @param dispatcher	the event dispatcher
		 * @param type			the event type as in addEventListener
		 * @param useCapture	same as addEvenListener
		 * @param priority		same as addEvenListener
		 * @return				a Future that will be completed on the next occurence of the event 
		 */		
		public static function nextEvent( dispatcher:EventDispatcher, type:String, useCapture:Boolean = false, priority:int = 0 ) : IFuture
		{
			
			var f:Future = new Future();
			FUTURE::debug {
				f.__debug_stack[0].fct = "nextEvent(" + type +")";
				f.__debug_stack[0].pos = getCallerInfo();
			}
			
			function onEvent(e:Event):void {
				f._complete( e );
			}
			
			f.onResult( callback( dispatcher.removeEventListener, type, onEvent ) );
			
			dispatcher.addEventListener( type, onEvent, useCapture, priority, false );
			
			return f;
			
		}
		
		/**
		 * Create a Future from an org.osflash.signal Signal
		 *  
		 * @param s		any instance of IOnceSignal
		 * @return		a Future that will be completed next time the signal dispatches
		 */		
		public static function nextSignal( s:ISignal ) : Future
		{
			var f:Future = new Future();
			
			FUTURE::debug {
				f.__debug_stack[0].fct = "nextSignal";
				f.__debug_stack[0].pos = getCallerInfo();
			}
			
			s.add( f._complete, true );
			return f;
		}
		
		/**
		 * pre-completed empty Future to use as dummy or synchronous to asynchronous utility
		 * Note: this instance is shared to avoid garbage collection
		 */
		public static const completedNull:Future = completed( null );
		
		/**
		 * return pre-completed Future to use as dummy or synchronous to asynchronous utility
		 */
		public static function completed( data : * ):Future
		{
			
			var f:Future = new Future();
			
			FUTURE::debug {
				f.__debug_stack[0].fct = "completed(" + data + ")";
				f.__debug_stack[0].pos = getCallerInfo();
			}
				
			f._completeEither( Either.Right(data) );
			return f;
			
		}
		
		/**
		 * pre-completed empty Future to use as dummy or synchronous to asynchronous utility
		 * Note: this instance is shared to avoid garbage collection
		 */
		public static const failedNull:Future = completed( null );
		
		/**
		 * return pre-completed Future to use as dummy or synchronous to asynchronous utility
		 */
		public static function failed( error : * ):Future
		{
			
			var f:Future = new Future();
			
			FUTURE::debug {
				f.__debug_stack[0].fct = "failed(" + error + ")";
				f.__debug_stack[0].pos = getCallerInfo();
			}
				
			f._completeEither( Either.Left(error) );
			return f;
			
		}
		
		/** 
		 * return pre-completed Future to use as dummy or synchronous to asynchronous utility
		 */
		public static function completedEither( res:Either ):Future
		{
			
			var f:Future = new Future();
			
			FUTURE::debug {
				f.__debug_stack[0].fct = "completedEither(" + res.toString() + ")";
				f.__debug_stack[0].pos = getCallerInfo();
			}
			
			f._completeEither( res );
			return f;
			
		}
		
		public static function joinAll( futures:Vector.<IFuture>, unfold:Boolean = true ):IFuture
		{
			if( !futures || futures.length == 0 ) return completedNull;
			var marker:Object = { __marks:"joinAll end" };
			var join:IFuture = completed(marker);
			for each( var f:IFuture in futures )
				join = join.join( f );
			if ( unfold )
				join = join.map( function(nested:Array):Array {
					while( nested && nested[0] != marker ) {
						var head:Array = nested.shift();
						nested = head.concat( nested );
					}
					nested.shift();
					return nested;
				});
			return join;
		}
		
	}
}