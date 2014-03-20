package as3func.lang
{
	public class Progressor extends BaseProgressor
	{
		public function Progressor()
		{
		}
		
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
		
		public function updateProgress( p:Number ):void
		{
			_updateProgress(p) ;
		}
		
		public function resume():void
		{
			_resume() ;
		}
		
		public function pause():void
		{
			_pause() ;
		}
		
		public static function fromFuture(f:Future):Progressor
		{
			
			var tf:Progressor = new Progressor() ;
			tf._bind( f ) ;
			return tf ;
			
		}
		
		public static function fromProgressor(f:IProgressor):Progressor
		{
			
			var tf:Progressor = new Progressor() ;
			tf._bind( f ) ;
			f.onProgress.add( tf._updateProgress ) ;
			return tf ;
			
		}
		
	}
}