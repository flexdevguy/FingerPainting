package com.shaunhusain.fingerPainting.managers
{
	import com.eclecticdesignstudio.motion.Actuate;
	import com.eclecticdesignstudio.motion.actuators.GenericActuator;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;

	public class SecondaryPanelManager extends Sprite
	{
		private static var instance:SecondaryPanelManager;
		public static function getIntance():SecondaryPanelManager
		{
			if( instance == null ) instance = new SecondaryPanelManager( new SingletonEnforcer() );
			return instance;
		}
		private var _isShowingPanel:Boolean;
		public function get isShowingPanel():Boolean
		{
			return _isShowingPanel;
		}
		public function set isShowingPanel(value:Boolean):void
		{
			_isShowingPanel = value;
		}
		
		private var _lastShown:DisplayObject;
		
		private var _currentlyShowing:DisplayObject;
		public function get currentlyShowing():DisplayObject
		{
			return _currentlyShowing;
		}
		
		
		public function SecondaryPanelManager(se:SingletonEnforcer)
		{
		}
		
		public function showPanel(displayObject:DisplayObject):void
		{
			if(_currentlyShowing)
				hidePanel();
			
			displayObject.alpha = 0;
			addChild(displayObject);
			displayObject.x = stage.fullScreenWidth/2-displayObject.width/2;
			displayObject.y = stage.fullScreenHeight/2-displayObject.height/2 - 400;
			_currentlyShowing = displayObject;
			isShowingPanel = true;
			
			Actuate.tween(displayObject, .5, {alpha:1, y:stage.fullScreenHeight/2-displayObject.height/2});
		}
		public function hidePanel():void
		{
			if(!currentlyShowing || !isShowingPanel)
				return;
			
			_lastShown = currentlyShowing;
			
			isShowingPanel = false;
			_currentlyShowing = null;
			
			var ge:GenericActuator = Actuate.tween(_lastShown, .5, {alpha:0, y:stage.fullScreenHeight/2-_lastShown.height/2+400});
			ge.onComplete(function():void
			{
				removeChild(_lastShown);
			});
		}
		
	}
}

internal class SingletonEnforcer {public function SingletonEnforcer(){}}