package com.shaunhusain.fingerPainting.view.optionPanels
{
	import com.shaunhusain.fingerPainting.model.PaintModel;
	import com.shaunhusain.fingerPainting.model.color.ARGB;
	import com.shaunhusain.fingerPainting.model.color.HSV;
	import com.shaunhusain.fingerPainting.view.mobileUIControls.ColorValueDisplay;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.events.TouchEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.Timer;

	public class ColorOptionsPanel extends PanelBase
	{
		//--------------------------------------------------------------------------------
		//				UI Components
		//--------------------------------------------------------------------------------
		/**
		 * Sprite for interaction on the hue bar
		 */
		private var hueBarSprite:Sprite;
		private var hueText:TextField;
		
		private var lightAndSatGradientSprite:Sprite;
		private var lightAndSatGradient:Bitmap;
		private var selectedHueBar:Bitmap;
		
		private var selectedColorHBar:Bitmap;
		private var selectedColorVBar:Bitmap;
		private var colorValueDisplay:ColorValueDisplay;
		//--------------------------------------------------------------------------------
		//				Variables
		//--------------------------------------------------------------------------------
		private var model:PaintModel = PaintModel.getInstance();
		private var eventHandlersRegistered:Boolean;
		private var currentHSV:HSV;
		
		private var colorSampleRequiresUpdate:Boolean;
		private var lightSatRequiresUpdate:Boolean;
		
		private var updateHSVTimer:Timer;
		
		
		//--------------------------------------------------------------------------------
		//				Constructor
		//--------------------------------------------------------------------------------
		public function ColorOptionsPanel()
		{
			super();
			titleBackground.text = "Color\nPicker";
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}
		
		//--------------------------------------------------------------------------------
		//				Handlers
		//--------------------------------------------------------------------------------
		private function addedToStageHandler(event:Event):void
		{
			if(!eventHandlersRegistered)
			{
				addEventListener(TouchEvent.TOUCH_MOVE, blockEvent);
				addEventListener(TouchEvent.TOUCH_END, blockEvent);
				addEventListener(TouchEvent.TOUCH_BEGIN, blockEvent);
				addEventListener(TouchEvent.TOUCH_TAP, blockEvent);
				addEventListener(TouchEvent.TOUCH_ROLL_OUT, blockEvent);
				eventHandlersRegistered=true;
			}
			
			if(!hueBarSprite)
			{ 
				hueBarSprite = new Sprite();
				hueBarSprite.graphics.clear();
				for(var hue:int = 0,xPos:int = 0; hue <= 360; hue++,xPos+=1)
				{
					hueBarSprite.graphics.beginFill(ColorConversionFunctions.AHSVtoARGB(1,hue,1,1));
					hueBarSprite.graphics.drawRect(xPos,0,1,100);
					hueBarSprite.graphics.endFill();
				}
				
				hueBarSprite.addEventListener(TouchEvent.TOUCH_MOVE, hueBarTouchMoveHandler);
				addChild(hueBarSprite);
				hueBarSprite.x = 100;
				hueBarSprite.y = 140;
				hueBarSprite.cacheAsBitmap = true;
				
				selectedHueBar = new Bitmap(new BitmapData(2,100,false,0xff000000));
				selectedHueBar.blendMode = BlendMode.INVERT;
				hueBarSprite.addChild(selectedHueBar);
			}
			
			if(!lightAndSatGradient)
			{
				lightAndSatGradient = new Bitmap(new BitmapData(90,90));
				//lightAndSatGradient.cacheAsBitmap = true;
				lightAndSatGradientSprite = new Sprite();
				lightAndSatGradientSprite.addChild(lightAndSatGradient);
				lightAndSatGradient.scaleX = lightAndSatGradient.scaleY = 4;
				lightAndSatGradientSprite.y = 300;
				lightAndSatGradientSprite.x = 100;
				addChild(lightAndSatGradientSprite);
				lightAndSatGradientSprite.addEventListener(TouchEvent.TOUCH_BEGIN, lightAndSatGradientTouchBeginHandler);
				lightAndSatGradientSprite.addEventListener(TouchEvent.TOUCH_END, lightAndSatGradientTouchEndHandler);
				
				selectedColorHBar = new Bitmap(new BitmapData(360,2,false,0xff000000));
				selectedColorHBar.blendMode = BlendMode.INVERT;
				lightAndSatGradientSprite.addChild(selectedColorHBar);
				
				selectedColorVBar = new Bitmap(new BitmapData(2,360,false,0xff000000));
				selectedColorVBar.x=359;
				selectedColorVBar.blendMode = BlendMode.INVERT;
				lightAndSatGradientSprite.addChild(selectedColorVBar);
			}
			
			if(!colorValueDisplay)
			{
				colorValueDisplay = new ColorValueDisplay();
				colorValueDisplay.x = 75;
				colorValueDisplay.y = 880;
				addChild(colorValueDisplay);
			}
			
			if(!updateHSVTimer)
			{
				updateHSVTimer = new Timer(100);
				updateHSVTimer.addEventListener(TimerEvent.TIMER, timerHandler);
				updateHSVTimer.start();
			}
			
			var curARGB:ARGB = ColorConversionFunctions.parseARGBuint(model.currentColor);
			currentHSV = ColorConversionFunctions.RGBtoHSV(curARGB);
			updateSelectionPositions();
			
			lightSatRequiresUpdate = colorSampleRequiresUpdate = true;
		}
		protected function lightAndSatGradientTouchEndHandler(event:TouchEvent):void
		{
			removeEventListener(TouchEvent.TOUCH_MOVE, lightAndSatGradientTouchMoveHandler);
		}
		
		protected function lightAndSatGradientTouchBeginHandler(event:TouchEvent):void
		{
			addEventListener(TouchEvent.TOUCH_MOVE, lightAndSatGradientTouchMoveHandler,false,int.MAX_VALUE);
		}
		
		private function timerHandler(event:Event):void
		{
			if(lightSatRequiresUpdate)
			{
				drawLightAndSatGradient();
				lightSatRequiresUpdate = false;
			}
			if(colorSampleRequiresUpdate)
			{
				updateColorSample();
				colorSampleRequiresUpdate = false;
			}
		}
		
		private function hueBarTouchMoveHandler(event:TouchEvent):void
		{
			//hueText.text = allPossibleColors.bitmapData.getPixel32(event.localX,event.localY).toString();
			selectedHueBar.x = event.localX;
			event.stopImmediatePropagation();
			lightSatRequiresUpdate = colorSampleRequiresUpdate = true;
		}
		private function lightAndSatGradientTouchMoveHandler(event:TouchEvent):void
		{
			//hueText.text = allPossibleColors.bitmapData.getPixel32(event.localX,event.localY).toString(); 
			//trace("got to move handler");
			var pointToUse:Point = new Point();
			if(event.target != lightAndSatGradientSprite)
			{
				pointToUse = lightAndSatGradientSprite.globalToLocal(new Point(event.stageX, event.stageY));
			}
			else
			{
				pointToUse.x = event.localX;
				pointToUse.y = event.localY;
			}
			
			if(pointToUse.x<0)
				pointToUse.x = 0;
			if(pointToUse.x>=360)
				pointToUse.x = 359;
			
			if(pointToUse.y<0)
				pointToUse.y = 0;
			if(pointToUse.y>=360)
				pointToUse.y = 359;
			
			selectedColorVBar.x = pointToUse.x;
			selectedColorHBar.y = pointToUse.y;
			
			event.stopImmediatePropagation();
			colorSampleRequiresUpdate=true;
		}
		private function blockEvent(event:TouchEvent):void
		{
			event.stopImmediatePropagation();
		}
		//--------------------------------------------------------------------------------
		//				Helper functions
		//--------------------------------------------------------------------------------
		private function drawLightAndSatGradient():void
		{
			//trace("drawingLightAndSatGradient");
			lightAndSatGradient.bitmapData.lock();
			for(var i:Number = 90; i >= 0; i--)
				for(var j:Number= 90; j >= 0; j--)
					lightAndSatGradient.bitmapData.setPixel32(i,90-j,ColorConversionFunctions.AHSVtoARGB(1,selectedHueBar.x,i/90,j/90));
			lightAndSatGradient.bitmapData.unlock();
		}
		
		private function updateColorSample():void
		{
			colorValueDisplay.color = model.currentColor = lightAndSatGradient.bitmapData.getPixel32(selectedColorVBar.x/4,selectedColorHBar.y/4);
		}
		
		private function updateSelectionPositions():void
		{
			selectedHueBar.x = currentHSV.hue;
			selectedColorHBar.y = (1-currentHSV.value) * 360-1;
			selectedColorVBar.x = currentHSV.saturation * 360-1;
		}
		
	}
}