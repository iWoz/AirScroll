package
{
	import com.greensock.plugins.ThrowPropsPlugin;
	import com.greensock.plugins.TweenPlugin;
	import com.wuzhiwei.scroll.ScrollCtrl;
	import com.wuzhiwei.scroll.ScrollDirection;
	import com.wuzhiwei.scroll.VPageScrollCtrl;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.geom.Rectangle;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	
	public class AirScroll extends Sprite
	{
		private var appWidth:Number;
		private var appHeight:Number;
		
		private static var cons:console;
		
		private static const DEF_WIDTH:uint = 640;
		private static const DEF_HEIGHT:uint = 960;
		
		public function AirScroll()
		{
			super();
			
			this.stage.align = StageAlign.TOP_LEFT;
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			
			//addChild( new Stats );
			
			TweenPlugin.activate( [ThrowPropsPlugin] );
			
			appWidth = this.stage.fullScreenWidth;
			appHeight = this.stage.fullScreenHeight;
			var flashVars:Object = this.root.loaderInfo.parameters;
			if( flashVars["webWidth"] )
			{
				appWidth = Number(flashVars["webWidth"]);
			}
			if( flashVars["webHeight"] )
			{
				appHeight = Number(flashVars["webHeight"]);
			}
			
			fitScale();
			
			cons = new console;
			cons.text.editable = false;
			cons.width = 500;
			cons.height = 150;
			cons.y = DEF_HEIGHT - cons.height - 80;
			addChild( cons );
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			cons.text.appendText( Multitouch.supportsTouchEvents+" "+MultitouchInputMode.TOUCH_POINT+"\n" );
				
			var i:int;
			
			var vectBg:Sprite = new Sprite;
			vectBg.x = 20;
			vectBg.y = 20;
			vectBg.graphics.beginFill( 0x123456 );
			vectBg.graphics.drawRect( 0, 0, 610, 700 );
			vectBg.graphics.endFill();
			addChild( vectBg );
			var vectCt:Sprite = new Sprite;
			vectBg.addChild( vectCt );
			/*
			var vbar:vectBar;
			for(i = 0; i < 50; i++)
			{
				vbar = new vectBar;
				vbar.gotoAndStop( 1 );
				vbar.num_tf.text = i + "";
				vbar.num_tf.selectable = false;
				vbar.x = 30;
				vbar.y = 20 + i * (vbar.height + 10);
				vectCt.addChild( vbar );
			}
			
			var vScrollCtrl:ScrollCtrl = new ScrollCtrl(
				vectBg, vectCt, new Rectangle( 0, 0, 610, 680 ),
				ScrollDirection.VECTORIAL, false, true, 0xffffff, -10, 0, 1.5,
				30, 2.0, 0.2, 0, 0, 30, 0 );
			*/
			var vPageScroll:VPageScrollCtrl = new VPageScrollCtrl(
				vectBg, vectCt, new Rectangle( 0, 0, 610, 680 ),
				vectBar, 30, 20, 10, 20, setData, null );
			vPageScroll.dataList = getRange();
			
		}
		
		public static function log( msg:* ):void
		{
			cons.text.appendText( String(msg)+"\n" );
			cons.text.textField.scrollV = cons.text.textField.maxScrollV;
		}
		
		private function setData( unit:vectBar, data:* ):void
		{
			unit.num_tf.text = String( data );
		}
		
		private function getRange( start:int = 0, end:int = 50 ):Array
		{
			var list:Array = [];
			var i:int;
			for( i = start; i < end; i++ )
			{
				list.push( i );
			}
			return list;
		}
		
		/**分辨率自适应*/
		private function fitScale():void
		{
			var oriScaleX:Number = appWidth / DEF_WIDTH;
			var oriScaleY:Number = appHeight / DEF_HEIGHT;
			
			var minScale:Number = ( oriScaleX > oriScaleY ? oriScaleY : oriScaleX );
			
			this.scaleX = this.scaleY = minScale;
			if( minScale < oriScaleX )
			{
				this.x = ( appWidth - DEF_WIDTH * minScale ) * 0.5;
			}
			else if( minScale < oriScaleY )
			{
				this.y = ( appHeight - DEF_HEIGHT * minScale ) * 0.5;
			}
		}
	}
}