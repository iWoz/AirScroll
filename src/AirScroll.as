package
{
	import com.greensock.plugins.ThrowPropsPlugin;
	import com.greensock.plugins.TweenPlugin;
	import com.wuzhiwei.scroll.ScrollCtrl;
	import com.wuzhiwei.scroll.ScrollDirection;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.geom.Rectangle;
	
	public class AirScroll extends Sprite
	{
		private static const DEF_WIDTH:uint = 640;
		private static const DEF_HEIGHT:uint = 960;
		
		public function AirScroll()
		{
			super();
			
			this.stage.align = StageAlign.TOP_LEFT;
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			
			//addChild( new Stats );
			
			TweenPlugin.activate( [ThrowPropsPlugin] );
			
			fitScale();
			
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
				ScrollDirection.VECTORIAL, false, true, 0xffffff, -10, 0, 1.0,
				50, 1.2, 0.2, 0, 0, 30, 0 );
		}
		
		/**分辨率自适应*/
		private function fitScale():void
		{
			var oriScaleX:Number = stage.fullScreenWidth / DEF_WIDTH;
			var oriScaleY:Number = stage.fullScreenHeight / DEF_HEIGHT;
			
			var minScale:Number = ( oriScaleX > oriScaleY ? oriScaleY : oriScaleX );
			
			this.scaleX = this.scaleY = minScale;
			if( minScale < oriScaleX )
			{
				this.x = ( stage.fullScreenWidth - DEF_WIDTH * minScale ) * 0.5;
			}
			else if( minScale < oriScaleY )
			{
				this.y = ( stage.fullScreenHeight - DEF_HEIGHT * minScale ) * 0.5;
			}
		}
	}
}