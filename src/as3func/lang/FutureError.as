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
				// cut stack trace
				var stack:Array = (error as Error).getStackTrace().split('\n');
				var newlinesInMessage:Array = message.match( /\n/ );
				var numlinesInMessage:int = newlinesInMessage ? newlinesInMessage.length : 0;
				for ( var i:int = numlinesInMessage + 1; i < stack.length; ++i ) {
					var stackLine:String = stack[i];
					if( stackLine.match( /src\/as3func\/lang\/BaseFuture.as:/ ) )
						break;
					else
						message += '\n' + stackLine;
				}
			} else
				message = String(error); 
			
			// print async trace
			message += "\nfrom async stack:\n";
			var reverseStack:Array = futureStack.reverse();
			for each( var line:Object in futureStack )
				message += '\t' + line.fct + "\t" + line.pos.className + " line " + line.pos.line + '\n';
			
			message += "\n== internal callback tracks =========";
			
			super( message, id );
			
		}
		
	}
}