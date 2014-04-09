package as3func.lang
{
	public class DebugPosition
	{
		
		private var _className:String;
		private var _functionName:String;
		private var _line:int;
		
		public function DebugPosition( cl:String = '', fct:String = '', line:int = 0 )
		{
			
			_className = cl;
			_functionName = fct;
			_line = line;
			
		}

		public function get line():int
		{
			return _line;
		}

		public function get functionName():String
		{
			return _functionName;
		}

		public function get className():String
		{
			return _className;
		}

	}
}