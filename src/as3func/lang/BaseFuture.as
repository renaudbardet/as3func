package as3func.lang
{
	import flash.utils.getQualifiedClassName;
	
	/** 
	 * @author renaudbardet
	 * 
	 * BaseFuture implements all and only the methods exposed by IFuture
	 * it is ment as a base for Future-based objects that will keep there
	 * completion mechanisms internal
	 * 
	 * for a fully manipuable future see Future
	 * 
	 */
	public class BaseFuture implements IFuture
	{
		
		protected var _isComplete : Boolean;
		
		protected var result : Either;
		
		private var callbacks:Vector.<Function>;
		private var errorCallbacks:Vector.<Function>;
		private var resultCallbacks:Vector.<Function>;
		
		private var typeConstraint:Class;
		
		public function BaseFuture( typeConstraint:Class = null )
		{
			
			_isComplete = false;
			
			callbacks = new Vector.<Function>();
			errorCallbacks = new Vector.<Function>();
			resultCallbacks = new Vector.<Function>();
			
			this.typeConstraint = typeConstraint;
			
		}
		
		/**
		 * @return	true if data or error has been received, false otherwise
		 */
		public function get isComplete() : Boolean
		{
			return _isComplete;
		}
		
		/**
		 * @param f		a function to be called when the future is reached
		 * 				can be of type function(data):void or function():void
		 * @return 		this instance (builder pattern)
		 */
		public function onSuccess( f:Function ):IFuture
		{
			
			if ( _isComplete )
			{
				
				if ( result.isRight() )
				{
					if ( f.length == 0 )
						f();
					else
						f(result.getRight());
				}
				
			}
			else
			{
				callbacks.push( f );
			}
			
			return this;
			
		}
		
		/**
		 * @param f		a function to be called when the future fails
		 * 				can be of type function(error):void or function():void
		 * @return 		this instance (builder pattern)
		 */
		public function onError( f:Function ):IFuture
		{
			
			if ( _isComplete )
			{
				
				if ( result.isLeft() )
				{
					if ( f.length == 0 )
						f();
					else
						f(result.getLeft());
				}
				
			}
			else
			{
				errorCallbacks.push( f );
			}
			
			return this;
			
		}
		
		/**
		 * @param f		a function to be called when data or error is received
		 * 				can be of type function(Either):void or function():void
		 * @return 		this instance (builder pattern)
		 */
		public function onResult( f:Function ):IFuture
		{
			
			if ( _isComplete )
			{
				
				if ( f.length == 0 )
					f();
				else
					f(result);
				
			}
			else
			{
				resultCallbacks.push( f );
			}
			
			return this;
			
		}
		
		/**
		 * trigger the completion of the Future and the call to every referenced callback
		 * @param res	an optional data object
		 */
		protected function _complete( res:* ):void
		{
			
			_completeEither( Either.Right( res ) );
			
		}
		
		/**
		 * trigger the failed completion of the Future and the call to every referenced error related callback
		 * @param error	an optional error
		 */
		protected function _fail( error:* ):void
		{
			
			_completeEither( Either.Left( error ) );
			
		}
		
		/**
		 * trigger the completion of the Future with a result either right or erroneous
		 * @param res	an Either of type Left(error) or Right(data)
		 */
		protected function _completeEither( res:Either ):void
		{
			
			if ( _isComplete ) return;
			
			result = res;
			
			if ( typeConstraint != null && result.isRight() )
			{
				if ( !(result.getRight() is typeConstraint) )
					result = Either.Left("Type constraint failed on Future completion, result should be of type "
						+ flash.utils.getQualifiedClassName(typeConstraint)
						+ " but is "
						+ flash.utils.getQualifiedClassName(result.getRight()) );
			}
			
			_isComplete = true;
			
			if ( res.isRight() )
			{
				for each ( var fct:Function in callbacks )
				{
					
					if ( fct.length == 0 )
						fct();
					else
						fct(res.getRight());
					
				}
			}
			else
			{
				for each ( fct in errorCallbacks )
				{
					
					if ( fct.length == 0 )
						fct();
					else
						fct(res.getLeft());
					
				}
			}
			
			for each ( fct in resultCallbacks )
			{
				
				if ( fct.length == 0 )
					fct();
				else
					fct(result);
				
			}
			
			callbacks = null;
			errorCallbacks = null;
			resultCallbacks = null;
			
		}
		
		/**
		 * converts the resulting data of a Future throught a mapping function following the pattern
		 * 
		 * this					X - - - - -> A
		 * this.map(mapper)		X - - - - -> B
		 * 
		 * @param mapper	a function of type function( data:A ):B or function():B
		 * 					where A is the type returned by this Future and B the type you want to get
		 * @return 			a new Future that will be completed when this Future is completed but with the return of mapper(data) rather than data itself
		 * 
		 */
		public function map( mapper:Function ):IFuture
		{
			
			return mapResult(
				function mapCompleter( res:Either ) : Either
				{
					if ( res.isRight() )
					{
						if ( mapper.length > 0 )
							return Either.Right( mapper( res.getRight() ) );
						else
							return Either.Right( mapper() );
					}
					else
						return res;
				} );
			
		}
		
		/**
		 * idem map but surrounded with try catch and if an error occurs we fail with the Error as content
		 */
		public function mapTry( mapper:Function ):IFuture
		{
			
			return mapResult(
				function mapCompleter( res:Either ) : Either
				{
					if ( res.isRight() )
					{
						try{
							if ( mapper.length > 0 )
								return Either.Right( mapper( res.getRight() ) );
							else
								return Either.Right( mapper() );
						} catch(e:*) {
							return Either.Left(e);
						}
					}
					else
						return res;
				} );
			
		}
		
		/**
		 * 
		 * same as map but expects the mapper function to take the Either result rather than the data ( sim. to onResult comp. to onSuccess )
		 *  
		 * @param mapper	a function of type function( res:Either<A,error> ):Either<B,error> or function():Either<B,error>
		 * 					where A is the data expected in this Future and B the data you want, error is of any kind
		 * @return 			a new Future that will be completed when this Future is completed but with the return of mapper(result)
		 * 
		 */
		public function mapResult( mapper:Function ) : IFuture
		{
			
			var proxy:BaseFuture = new BaseFuture();
			this.onResult(
				function mapResultCompleter( res:Either ):void
				{
					if ( mapper.length > 0 )
						proxy._completeEither( mapper( res ) );
					else
						proxy._completeEither( mapper() );
				} );
			return proxy;
			
		}
		
		/**
		 * onSucess we process the data throught a mapper function that converts the result to an Either
		 * this is the same as using mapResult althought you don't need to care about the case were the result is already faulty
		 *  
		 * @param mapper	a function of type function( data:A ):Either<B,error> or function():Either<B,error>
		 * 					where A is the data expected in this Future and B the data you want, error is of any kind
		 * 
		 * @return 			a new Future that will be completed when this Future is completed but with the return of mapper(result)
		 * 
		 */
		public function refine( mapper:Function ) : IFuture
		{
			
			var proxy:BaseFuture = new BaseFuture();
			this.onResult(
				function refineCompleter( res:Either ):void
				{
					if ( mapper.length > 0 )
					{
						if ( res.isRight() )
							proxy._completeEither( mapper( res.getRight() ) );
						else
							proxy._completeEither( res );
					}
					else
						proxy._completeEither( mapper() );
				} );
			return proxy;
			
		}
		
		/** 
		 * allows for joint asynchronous call patterns like
		 * 
		 * 	this			X - - - - -> A
		 * 	f2				X - - - - - - -> B
		 * 	f1.`(f2)		X - - - - - - -> (A,B)
		 * 
		 * @param f2	another Future completed or not
		 * @return 		a Future that will be completed on
		 * 
		 */
		public function join( f2 : IFuture ) : IFuture
		{
			
			var proxy:BaseFuture = new BaseFuture();
			
			var data:Array = [];
			
			function joinCheck( i:int, d:* ):void {
				data[i]= d;
				if ( _isComplete && f2.isComplete )
					proxy._complete( data );
			}
			
			onSuccess( callback(joinCheck, 0) );
			onError( proxy._fail );
			f2.onSuccess( callback(joinCheck, 1) );
			f2.onError( proxy._fail );
			
			return proxy;
			
		}
		
		/**
		 * return a Future that will be completed by either this Future or f2, depending on wich is completed first
		 * and that will fail only if both fail
		 * 
		 * @param f2	a Future
		 * @return 		a new Future
		 * 
		 */
		public function or( f2:IFuture ):IFuture
		{
			
			var proxy:BaseFuture = new BaseFuture();
			
			var result1:Either = null;
			var result2:Either = null;
			
			this.onResult( function orCompleter1(e:Either):void {
				result1 = e;
				if ( e.isRight() ) proxy._complete( e.getRight() );
				else if ( result2 && result2.isLeft() )
					proxy._fail( [result1.getLeft(), result2.getLeft()] ); // tuple of errors
			} );
			f2.onResult( function orCompleter2(e:Either):void {
				result2 = e;
				if ( e.isRight() ) proxy._complete( e.getRight() );
				else if ( result1 && result1.isLeft() )
					proxy._fail( [result1.getLeft(), result2.getLeft()] );
			} );
			return proxy;
			
		}
		
		/**
		 * fail this Future if f2 is complete first
		 * the error result will be the data result of f2
		 * 
		 * this produces the two following scenarios :
		 * 
		 * this					X - - - -> A
		 * f2					X - - -> B
		 * this.unless( f2 )	X - - -> Error(B)
		 * 
		 * or
		 * 
		 * this					X - - -> A
		 * f2					X - - - - -> B
		 * this.unless( f2 )	X - - -> A
		 * 
		 * @param f2	a Future
		 * @return 		this object
		 * 
		 */
		public function unless( f2:IFuture ) : IFuture
		{
			
			var proxy:BaseFuture = new BaseFuture();
			proxy._bind(this);
			f2.onSuccess( proxy._fail );
			return proxy;
			
		}
		
		/**
		 * bind the completion or failure of this Future to the completion or failure of f2
		 * when f2 completes this Future will complete, and if f2 fails this Future will fail
		 * 
		 * @param f2	a Future
		 * @return 		this object
		 * 
		 */
		protected function _bind( f2:IFuture ) : IFuture
		{
			
			f2.onResult( this._completeEither );
			return this;
			
		}
		
		/**
		 * creates a copy of this Future that will be triggered at the same time with the same result (data or error)
		 * @return 	a new Future
		 * 
		 */
		public function copy() : IFuture
		{
			
			var f:BaseFuture = new BaseFuture();
			f._bind( this );
			return f;
			
		}
		
		/**
		 * 
		 * this chaining function allows for patterns like
		 * 
		 * 		X - - - - -> A -> X - - - - -> B
		 * 		X - - - - - - - - - - - - - -> B
		 * 
		 * for example play( "anim1" ).chain( F.callback( play, "anim2" ) )
		 * will wait for anim1 to complete then play anim2
		 * the Future returned by this expression will be completed once anim2 is done
		 * 
		 * @param func	a function of type function( data:* ):Future or function():Future
		 * 				where result is the data resulting of this Future's completion
		 * 				func will be called once this future is completed
		 * @return 		a Future that will be completed once both this Future and the Future returned by func are completed
		 * 
		 */
		public function chain( func:Function ):IFuture
		{
			
			return chainResult(
					function chainCompleter( res:Either ):IFuture {
						if ( res.isRight() )
						{
							if ( func.length > 0 )
								return func( res.getRight() );
							else
								return func();
						}
						else
							return Future.failed( res.getLeft() );
					} );
			
		}
		
		/**
		 * This is the same as chain but the passed function should use the Either result rather than the data ( sim. to onResult comp. to onSuccess )
		 * @param func	a function of type function( result:Either ):Future or function():Future
		 * 				where result is result in this Future upon result completion
		 * @return 		a Future that will be completed this Future then func's returned Future are completed
		 */
		public function chainResult( func:Function ):IFuture
		{
			
			var proxy:BaseFuture = new BaseFuture();
			
			function chainFunc( res:Either ):void
			{
				if ( func.length > 0 )
					func( res ).onResult( proxy._completeEither );
				else
					func().onResult( proxy._completeEither );
			}
			
			onResult( chainFunc );
			
			return proxy;
			
		}
		
		public function traceResult(flag:String):IFuture {
			this.onResult( function(res:Either):void { trace( flag + "\t" + res ); } );
			return this;
		}
		
	}
	
}
