package as3func.lang
{
	public interface IProgressor extends IFuture
	{
		function get progress():Number;
		
		function get onPause():ISignal; // dispatched on pause
		function get onResume():ISignal; // dispatched on resume
		function get onProgress():ISignal; // dispatched every time we have data on the progress
		
		function isPaused():Boolean;
		
		function chainProgress( func:Function ):IProgressor;
		
	}
}