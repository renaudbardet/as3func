package as3func.lang
{
	import as3func.lang.DebugPosition;
	
	public function getCallerInfo():DebugPosition
	{
		
		var stackLine:String = new Error().getStackTrace().split( "\n", 4 )[3];
		var functionName:String = stackLine.match( /\w+\(\)/ )[0];
		var classMatchs:Array = stackLine.match( /(?<=\/)\w+?(?=.as:)/ );
		var className:String = null;
		if( classMatchs ) {
			className = classMatchs[0];
		} else {
			className = functionName.replace("()", ".as");
		}
		var lineMatchs:Array = stackLine.match( /(?<=:)\d+/ );
		var lineNumber:int = lineMatchs ? parseInt(lineMatchs[0]) : 0;
		
		return new DebugPosition( className, functionName, lineNumber );
		
	}
	
}