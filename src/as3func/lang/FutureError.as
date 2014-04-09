package as3func.lang
{
	public class FutureError extends Error
	{
		
		public function FutureError( error:*, futureStack:Array )
		{
			
			var message:String = '';
			var id:int = 0;
			
			if( error is Error ){
				message = (error as Error).message;
				id = (error as Error).errorID;
			} else
				message = String(error);
			
			message += "\nfrom :\n";
			
			var reverseStack:Array = futureStack.reverse();
			
			for each( var line:Object in futureStack ) {
				message += '\t' + line.fct + "\t" + line.pos.className + " line " + line.pos.line + '\n';
			}
			
			super( message, id );
			
		}
		
	}
}