package as3func.lang
{
	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class Future extends BaseFuture
	{
		
		/**
		 * trigger the completion of the Future and the call to every referenced callback
		 * @param res	an optional data object
		 */
		public function complete( res:* = null ):void
		{
			
			this._completeEither( Either.Right( res ) ) ;
			
		}
		
		/**
		 * trigger the failed completion of the Future and the call to every referenced error related callback
		 * @param error	an optional error
		 */
		public function fail( error:* = null ):void
		{
			
			this._completeEither( Either.Left( error ) ) ;
			
		}
		
		/**
		 * trigger the completion of the Future with a result either right or erroneous
		 * @param res	an Either of type Left(error) or Right(data)
		 */
		public function completeEither( res:Either ):void
		{
			
			this._completeEither( res ) ;
			
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
			
			return _bind( f2 ) ;
			
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
			
			f2.onResult( this._completeEither ) ;
			this.onResult( f2._completeEither ) ;
			return this ;
			
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
			
			this.onSuccess( f2.fail ) ;
			f2.onSuccess( this.fail ) ;
			
		}
		
		// ----------------------
		// secondary constructors
		
		/**
		 * create a Future as a copy of any IFuture
		 */
		public static function fromFuture(f:IFuture):Future
		{
			
			var tf:Future = new Future() ;
			tf.bind( f ) ;
			return tf ;
			
		}
		
		/**
		 * Create a Future from an Event Dispatcher
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
			
			var f:Future = new Future() ;
			
			function onEvent(e:Event):void
			{
				f._complete( e ) ;
			}
			
			f.onResult( callback( dispatcher.removeEventListener, type, onEvent ) );
			
			dispatcher.addEventListener( type, onEvent, useCapture, priority, false ) ;
			
			return f ;
			
		}
		
		/**
		 * Create a Future from an org.osflash.signal Signal
		 *  
		 * @param s		any instance of IOnceSignal
		 * @return		a Future that will be completed next time the signal dispatches
		 */		
		public static function nextSignal( s:Signal ) : Future
		{
			var f:Future = new Future() ;
			s.add( f._complete, true ) ;
			return f ;
		}
		
		/** 
		 * return pre-completed Future to use as dummy or synchronous to asynchronous utility
		 */
		public static function completed( data : * = null ):Future
		{
			
			return completedEither( Either.Right( data ) ) ;
			
		}
		
		/** 
		 * return pre-completed Future to use as dummy or synchronous to asynchronous utility
		 */
		public static function failed( error : * = null ):Future
		{
			
			return completedEither( Either.Left( error ) ) ;
			
		}
		
		/** 
		 * return pre-completed Future to use as dummy or synchronous to asynchronous utility
		 */
		public static function completedEither( res:Either ):Future
		{
			
			var f:Future = new Future() ;
			f._completeEither( res ) ;
			return f ;
			
		}
		
	}
}