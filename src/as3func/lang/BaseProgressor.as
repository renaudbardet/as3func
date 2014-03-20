
package as3func.lang
{

	public class BaseProgressor extends BaseFuture implements IProgressor
	{
		
		private var progress_:Number; // a Number between .0 and 1.0
		public function get progress():Number { return progress_; }
		
		private var paused_:Boolean;
		public function isPaused():Boolean { return !_isComplete && paused_; }
		
		protected var _onPause:Signal; // dispatched on pause
		public function get onPause():ISignal { return _onPause; }
		protected var _onResume:Signal; // dispatched on resume
		public function get onResume():ISignal { return _onResume; }
		protected var _onProgress:Signal; // dispatched every time we have data on the progress
		public function get onProgress():ISignal { return _onProgress; }
		
		// if true, complete will be triggered automatically when progress reaches 1.0
		// when subclassing, you should either set this to true or fire the _complete function by hand when apropriate
		protected var autoComplete:Boolean = false;
		
		public function BaseProgressor( typeConstraint:Class = null )
		{
			
			super( typeConstraint );
			
			progress_ = .0;
			
			_onResume = new Signal();
			_onPause = new Signal();
			_onProgress = new Signal( Number );
			
		}
		
		protected function _pause():void
		{
			
			if( !_isComplete )
				_onPause.dispatch();
			
		}
		
		protected function _resume():void
		{
			
			if( !_isComplete )
				_onResume.dispatch();
			
		}
		
		protected function _updateProgress( progress:Number ):void
		{
			
			/* if ( progress < progress_ || progress > 1 )
				throw new ArgumentError("progress should be a Number between .0 and 1.0 and greater than the current progress");
			*/
			if( isComplete ) return;
			if( progress < progress_ ) progress = progress_;
			if( progress > 1 ) progress = 1.0;
			
			progress_ = progress;
			
			_onProgress.dispatch(progress_);
			
			if ( autoComplete && progress == 1.0 )
				_complete(null);
			
		}
		
		override protected function _completeEither( res:Either ):void
		{
			if ( _isComplete ) return;
			progress_=1;
			super._completeEither(res);
			onProgress.removeAll();
			onPause.removeAll();
			onResume.removeAll();
			_onProgress = null;
			_onPause = null;
			_onResume = null;
		}
		
		public function chainProgress( func:Function ):IProgressor
		{
			
			var proxy:BaseProgressor = new BaseProgressor();
			
			function firstHalfProgress( p:Number):void { proxy._updateProgress( p/2 ); }
			this.onProgress.add( firstHalfProgress );
			this.onResult( function( res:Either ):void
				{
					if( res.isLeft() )
						proxy._fail(res.getLeft());
					else
					{
						firstHalfProgress( 1 );
						
						var f2:BaseProgressor;
						if( func.length >0 )
							f2 = func( res.getRight() );
						else
							f2 = func();
						
						function secondHalfProgress(p:Number):void{ proxy._updateProgress( (1 + p)/2 ); }
						if( !f2.isComplete )
							f2.onProgress.add( secondHalfProgress );
						else
							secondHalfProgress( 1 );
						proxy._bind( f2 );
					}
				});
			return proxy;
			
		}
		
	}
}
