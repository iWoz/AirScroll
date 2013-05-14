package com.wuzhiwei.scroll
{
	import com.greensock.BlitMask;
	import com.greensock.TimelineLite;
	import com.greensock.TweenLite;
	import com.greensock.easing.Strong;
	import com.greensock.plugins.ThrowPropsPlugin;
	
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.getTimer;
	
	public class ScrollCtrl
	{
		
		protected var _bg:Sprite;
		protected var _target:Sprite;
		protected var _blitMask:BlitMask;
		protected var _mask:Shape;
		protected var _bounds:Rectangle;
		
		protected var _isMouseDown:Boolean;
		protected var _isMouseMoved:Boolean;
		
		protected var _direct:uint;
		protected var _t1:uint;
		protected var _t2:uint;
		protected var _p1:Point;
		protected var _p2:Point;
		protected var _offsetPt:Point;
		
		protected var _minX:Number = 0;
		protected var _maxX:Number = 0;
		protected var _minY:Number = 0;
		protected var _maxY:Number = 0;
		
		protected var _tweenMaxDuration:Number;
		protected var _tweenMinDuration:Number;
		protected var _speedFactor:Number = 2.0;
		protected var _resistance:Number = 20;
		
		protected var _needSideBar:Boolean;
		protected var _sideBar:Shape;
		protected var _sideBarColor:uint = 0xffffff;
		protected var _sideBarWidth:Number;
		protected var _sideBarHeight:Number;
		protected var _sideBarMaxDist:Number;
		protected var _sideBarOffsetX:Number;
		protected var _sideBarOffsetY:Number;
		protected var _scrollEndX:Number;
		protected var _scrollEndY:Number;
		
		protected var _minXOffset:Number;
		protected var _maxXOffset:Number;
		protected var _minYOffset:Number;
		protected var _maxYOffset:Number;
		
		protected var _needUpdateWhenMove:Boolean = true;
		
		protected var _stageQuality:String = StageQuality.MEDIUM;
		
		/**
		 * ios设备对mouseEvent的MOUSE_UP和ROLL_OUT的触发会有不响应的情况
		 * 若此值为true，则使用touchEvent来代替mouseEvent 
		 */		
		protected var _useTouchEvent:Boolean = false;
		
		protected static const MAX_CLICK_MOVE_DIST:Number = 7.0;
		protected static const MAX_VISIBLE_DIST:Number = 80;
		
		
		/**
		 * 普通滑移类 
		 * @param scrollBg 滑移背景，侦听鼠标事件以更改滑移行为
		 * @param scrollObj 滑移内容，承载用于显示滑移的容器
		 * @param maskRect 遮罩矩形
		 * @param diretion 滑移方向
		 * @param useBlitMask 是否开启blitMask渲染，可以针对静态内容开启，动态内容需谨慎
		 * @param needSideBar 是否显示滑移块
		 * @param sideBarColor 滑移块的颜色
		 * @param sideBarOffsetX 滑移块距离最右的x距离
		 * @param sideBarOffsetY 滑移块距离最下的y距离
		 * @param speedFactor 鼠标释放后的缓动加速因子
		 * @param resistance 鼠标释放后的缓动的阻尼系数
		 * @param tweenMaxDuration 鼠标释放后的缓动的最大时间
		 * @param tweenMinDuration 鼠标释放后的缓动的最小时间
		 * @param minXOffset X轴的最小值的“偏移”量
		 * @param maxXOffset X轴的最大值的“偏移”量
		 * @param minYOffset Y轴的最小值的“偏移”量
		 * @param maxYOffset Y轴的最大值的“偏移”量
		 * 
		 */		
		public function ScrollCtrl( scrollBg:Sprite,
									scrollObj:Sprite,
									maskRect:Rectangle,
									diretion:uint,
									useBlitMask:Boolean = false,
									needSideBar:Boolean = true,
									sideBarColor:uint = 0xffffff,
									sideBarOffsetX:Number = -20,
									sideBarOffsetY:Number = -20,
									speedFactor:Number = 1.0, 
									resistance:Number = 20.0, 
									tweenMaxDuration:Number = 2.0, 
									tweenMinDuration:Number = 0.2,
									minXOffset:Number = 0,
									maxXOffset:Number = 0,
		                            minYOffset:Number = 0,
									maxYOffset:Number = 0)
		{
			
			super();
			
			_bg = scrollBg;
			_target = scrollObj;
			_bounds = maskRect;
			_direct = diretion;
			_needSideBar = needSideBar;
			_sideBarColor = sideBarColor;
			_speedFactor = speedFactor;
			_resistance = resistance;
			_sideBarOffsetX = sideBarOffsetX;
			_sideBarOffsetY = sideBarOffsetY;
			_tweenMaxDuration = tweenMaxDuration;
			_tweenMinDuration = tweenMinDuration;
			
			//仅针对windows模拟，启用鼠标事件侦听
			if( Capabilities.os.toLocaleLowerCase().indexOf( "windows" ) >= 0 )
			{
				_useTouchEvent = false;
			}
			else
			{
				_useTouchEvent = true;
			}
			AirScroll.log( "_useTouchEvent:"+_useTouchEvent );
			
			if( _bg.stage )
			{
				_stageQuality = _bg.stage.quality;
			}
			
			_minXOffset = minXOffset;
			_maxXOffset = maxXOffset;
			_minYOffset = minYOffset;
			_maxYOffset = maxYOffset;
			
			_p1 = new Point;
			_p2 = new Point;
			_offsetPt = new Point;
			
			if( useBlitMask )
			{
				_blitMask = new BlitMask( 
					_target, _bounds.x, _bounds.y, _bounds.width, _bounds.height, true );
				_blitMask.bitmapMode = false;
				_blitMask.mouseChildren = _blitMask.mouseEnabled = false;
			}
			else
			{
				_mask = new Shape;
				_mask.graphics.beginFill( 0xcccccc );
				_mask.graphics.drawRect( _bounds.x, _bounds.y, _bounds.width, _bounds.height );
				_mask.graphics.endFill();
				_target.parent.addChild( _mask );
				_target.mask = _mask;
			}
			calOverLap();
			initSideBar();
			addMouseDownListener();
		}
		
		/**
		 * 强制更新
		 * 强制重绘位图缓存，重设mask及更新滑移条 
		 * 
		 */		
		public function forceUpdate():void
		{
			if( _blitMask )
			{
				_blitMask.update( null, true );
			}
			if( _mask && !_target.mask )
			{
				_target.mask = _mask;
			}
			var i:int;
			var numChildren:int = _target.numChildren;
			var child:DisplayObject;
			for(i = 0; i < numChildren; i++)
			{
				child = _target.getChildAt( i );
				child.visible = true;
			}
			calOverLap();
			initSideBar( true );
			updateSideBar();
			twinkingSideBar();
		}
		
		/**
		 * 开启滑移 
		 * 
		 */		
		public function enableScroll():void
		{
			addMouseDownListener();
			forceUpdate();
			if( _sideBar && _needSideBar )
			{
				twinkingSideBar();
				initSideBar( true );
			}
		}
		
		/**
		 * 禁止滑移 
		 * 
		 */		
		public function disableScroll():void
		{
			killTweens();
			removeAllListeners();
			if( _sideBar )
			{
				_sideBar.visible = false;
			}
		}
		
		/**
		 * 初始化滑移条 
		 * @param forceUpdate 强制更新滑移条的额定宽或额定高
		 * 
		 */		
		protected function initSideBar( forceUpdate:Boolean = false ):void
		{
			if( _needSideBar && !_sideBar && _direct != ScrollDirection.BOTH )
			{
				_sideBar = new Shape;
				//定位滑移条的位置
				if( _direct == ScrollDirection.HORIZONTAL )
				{
					_sideBar.x = _bounds.x;
					_sideBar.y = _bounds.bottom + _sideBarOffsetY;	
				}
				else if( _direct == ScrollDirection.VECTORIAL )
				{
					_sideBar.x = _bounds.right + _sideBarOffsetX;
					_sideBar.y = _bounds.y;					
				}
				_target.parent.addChild( _sideBar );
				forceUpdate = true;
				_sideBar.visible = _needSideBar;
			}
			if( _sideBar && forceUpdate )
			{
				_sideBar.visible = true;
				_sideBarWidth = _sideBarHeight = 5;
				if( _direct == ScrollDirection.HORIZONTAL )
				{
					_sideBarWidth = _bounds.width / (_bounds.width - _minX) * _bounds.width;
					_sideBarMaxDist = _bounds.width - _sideBarWidth;
					_scrollEndX = _minX;
					_sideBar.visible = (0 > _minX);
				}
				else if( _direct == ScrollDirection.VECTORIAL )
				{
					_sideBarHeight = _bounds.height / (_bounds.height - _minY ) * _bounds.height;
					_sideBarMaxDist = _bounds.height - _sideBarHeight;
					_scrollEndY = _minY;
					_sideBar.visible = (0 > _minY);
				}
				drawSideBar( _sideBarWidth, _sideBarHeight );
			}
		}
		
		/**
		 * 按照所给的width和height重绘滑移条 
		 * @param width
		 * @param height
		 * 
		 */		
		protected function drawSideBar( width:Number = 5, height:Number = 5 ):void
		{
			if( _sideBar )
			{
				_sideBar.graphics.clear();
				_sideBar.graphics.beginFill( _sideBarColor );
				_sideBar.graphics.drawRoundRect( 
					0, 0, width < 0 ? 0 : width,
					height < 0 ? 0 : height, 6, 6 );
				_sideBar.graphics.endFill();
			}
		}
		
		/**
		 * 根据滑移的位置更新滑移条的位置和大小 
		 * 
		 */		
		protected function updateSideBar():void
		{
			if( _sideBar )
			{
				if( _direct == ScrollDirection.HORIZONTAL )
				{
					_sideBar.x = _bounds.x + _sideBarMaxDist * _target.x / _scrollEndX;
					if( _sideBar.x > _bounds.x + _sideBarMaxDist )
					{
						drawSideBar( _sideBarWidth - (_sideBar.x - _bounds.x - _sideBarMaxDist) * 0.5, 5 );
					}
					if( _sideBar.x < _bounds.x + 1 )
					{
						_sideBar.x = _bounds.x;
						drawSideBar( _sideBarWidth - _target.x * 0.5, 5 );
					}
				}
				else if( _direct == ScrollDirection.VECTORIAL )
				{
					_sideBar.y = _bounds.y + _sideBarMaxDist * _target.y / _scrollEndY;
					if( _sideBar.y > _bounds.y + _sideBarMaxDist )
					{
						drawSideBar( 5, _sideBarHeight - (_sideBar.y - _bounds.y - _sideBarMaxDist) );
					}
					if( _sideBar.y < _bounds.y + 1 )
					{
						_sideBar.y = _bounds.y;
						drawSideBar( 5, _sideBarHeight - _target.y * 0.5 );
					}
				}
			}
		} 
		
		/**
		 * 淡入滑移条 
		 * 
		 */		
		protected function tweenShowSideBar():void
		{
			if( _sideBar )
			{
				TweenLite.killTweensOf( _sideBar );
				TweenLite.to( _sideBar, 0.5, { alpha:1 } );
			}
		}
		
		/**
		 * 淡出滑移条 
		 * 
		 */		
		protected function tweenHideSideBar():void
		{
			if( _sideBar )
			{
				TweenLite.killTweensOf( _sideBar );
				TweenLite.to( _sideBar, 0.5, { alpha:0 } );
			}
		}
		
		/**
		 * 闪烁滑移条，提示可以滑移
		 * 
		 */		
		protected function twinkingSideBar():void
		{
			if( _sideBar )
			{
				TweenLite.killTweensOf( _sideBar );
				_sideBar.alpha = 0;
				var tl:TimelineLite = new TimelineLite();
				tl.append( TweenLite.to( _sideBar, 0.8, { alpha: 1 } ) );
				tl.append( TweenLite.to( _sideBar, 0.8, { alpha: 0 } ) );
			}
		}
		
		/**
		 * 添加鼠标按下的事件，鼠标按下则代表滑移监听的开始 
		 * 
		 */		
		protected function addMouseDownListener():void
		{
			//useWeakReference为false，避免GC移除down事件
			AirScroll.log( "===========addMouseDownListener==========" );
			if( _useTouchEvent )
			{
				_bg.addEventListener( TouchEvent.TOUCH_BEGIN, mouseDownHandler );
			}
			else
			{
				_bg.addEventListener( MouseEvent.MOUSE_DOWN, mouseDownHandler );				
			}
		}
		
		/**
		 * 处理鼠标按下，滑移的开始
		 * 停止一切正在进行的滑移 
		 * @param e
		 * 
		 */		
		protected function mouseDownHandler( e:Event ):void
		{
			AirScroll.log( "=====================" );
			AirScroll.log( "super mouseDownHandler" );
			
			if( _bg.stage )
			{
				_bg.stage.quality = StageQuality.LOW;				
			}
			
			killTweens();
			tweenShowSideBar();
			
			enableTargetMouse();
			
			_isMouseDown = true;
			_isMouseMoved = false;
			
			_p1.setTo( Math.ceil(_target.x), Math.ceil(_target.y) );
			_p2.setTo( Math.ceil(_target.x), Math.ceil(_target.y) );
			_offsetPt.setTo( Math.ceil(_bg.mouseX - _target.x), Math.ceil(_bg.mouseY - _target.y) );
			calOverLap();
			_t1 = _t2 = getTimer();
			
			if( _useTouchEvent )
			{
				_bg.addEventListener( TouchEvent.TOUCH_MOVE, mouseMoveHandler );
				_bg.addEventListener( TouchEvent.TOUCH_END, mouseLeaveHandler );
				_bg.addEventListener( TouchEvent.TOUCH_ROLL_OUT, mouseLeaveHandler );	
			}
			else
			{
				_bg.addEventListener( MouseEvent.MOUSE_MOVE, mouseMoveHandler );
				_bg.addEventListener( MouseEvent.MOUSE_UP, mouseLeaveHandler );
				_bg.addEventListener( MouseEvent.ROLL_OUT, mouseLeaveHandler );				
			}
			
		}
		
		/**
		 * 计算触底位置 
		 * 可被子类覆盖，单独计算触底位置
		 */		
		protected function calOverLap():void
		{
			_maxX = _maxXOffset;
			_maxY = _maxYOffset;
			_minX = Math.min( 0, _bounds.width - _target.width - _minXOffset );
			_minY = Math.min( 0, _bounds.height - _target.height - _minYOffset);
		}
		
		/**
		 * 处理鼠标移动，滑移跟随，速度记录，及临界点判定 
		 * @param e
		 * 
		 */		
		protected function mouseMoveHandler( e:Event ):void
		{
			if( _isMouseDown )
			{
				var newX:Number = Math.ceil(_bg.mouseX - _offsetPt.x);
				var newY:Number = Math.ceil(_bg.mouseY - _offsetPt.y);
				
				var moveX:Number = Math.abs(newX - _target.x);
				var moveY:Number = Math.abs(newY - _target.y);
				var isScrollOn:Boolean = false;
				
				//鼠标滑移超过MAX_CLICK_MOVE_DIST 以上才禁掉鼠标点击事件
				if( ( (_direct == ScrollDirection.HORIZONTAL ||
					_direct == ScrollDirection.BOTH) && moveX > MAX_CLICK_MOVE_DIST)
					|| ( (_direct == ScrollDirection.VECTORIAL ||
						_direct == ScrollDirection.BOTH) && moveY > MAX_CLICK_MOVE_DIST)
				)
				{
					isScrollOn = true;
				}
				
				if( !_isMouseMoved && isScrollOn )
				{
					if( _needUpdateWhenMove )
					{
						_bg.addEventListener( Event.ENTER_FRAME, updateHandler );
					}
					_isMouseMoved = true;
					enableBlitMask();
					disableTargetMouse();
				}
				
				if( _direct == ScrollDirection.HORIZONTAL ||
					_direct == ScrollDirection.BOTH )
				{
					if( newX > _maxX )
					{
						_target.x = (newX + _maxX) * 0.5;
					}else if( newX < _minX )
					{
						_target.x = (newX + _minX ) * 0.5;
					}else
					{
						_target.x = newX;
					}
				}
				
				if( _direct == ScrollDirection.VECTORIAL ||
					_direct == ScrollDirection.BOTH )
				{
					if( newY > _maxY )
					{
						_target.y = (newY + _maxY) * 0.5;
					}else if( newY < _minY )
					{
						_target.y = (newY + _minY) * 0.5;
					}else
					{
						_target.y = newY;
					}
				}
				
				if( _blitMask )
				{
					_blitMask.update();
				}
				var t:uint = getTimer();
				if( t - _t2 > 50 )
				{
					_p2.copyFrom( _p1 );
					_t2 = _t1;
					_p1.setTo( _target.x, _target.y );
					_t1 = t;
				}
				updateSideBar();
				if( e is MouseEvent )
				{
					(e as MouseEvent).updateAfterEvent();					
				}
				else if( e is TouchEvent )
				{
					(e as TouchEvent).updateAfterEvent();					
				}
			}
		}
		
		/**
		 * 鼠标移出处理 
		 * @param e
		 * 
		 */		
		protected function mouseLeaveHandler( e:Event ):void
		{
			AirScroll.log( "super mouseLeaveHandler "+e.type );
			_isMouseDown = false;
			
			tweenAfterRelease();
			
			_bg.removeEventListener( Event.ENTER_FRAME, updateHandler );
			if( _useTouchEvent )
			{
				_bg.removeEventListener( TouchEvent.TOUCH_END, mouseLeaveHandler );
				_bg.removeEventListener( TouchEvent.TOUCH_ROLL_OUT, mouseLeaveHandler );
			}
			else
			{
				_bg.removeEventListener( MouseEvent.MOUSE_UP, mouseLeaveHandler );
				_bg.removeEventListener( MouseEvent.ROLL_OUT, mouseLeaveHandler );				
			}
		}
		
		/**
		 * 鼠标释放后的缓动滑移 
		 * 
		 */		
		protected function tweenAfterRelease():void
		{
			AirScroll.log( "super tweenAfterRelease." );
			enableTargetMouse();
			
			var time:Number = ( getTimer() - _t2 ) * 0.001;
			var xVelocity:Number = _speedFactor * ( _target.x - _p2.x ) / time;
			var yVelocity:Number = _speedFactor * ( _target.y - _p2.y ) / time;
			
			var throwProps:Object = {};
			if( _direct == ScrollDirection.HORIZONTAL ||
				_direct == ScrollDirection.BOTH )
			{
				throwProps["x"] = { velocity:xVelocity, max:_maxX, min: _minX, resistance:_resistance };
			}
			if( _direct == ScrollDirection.VECTORIAL ||
				_direct == ScrollDirection.BOTH )
			{
				throwProps["y"] = { velocity:yVelocity, max:_maxY, min: _minY, resistance:_resistance };
			}
			ThrowPropsPlugin.to( _target, 
				{ throwProps:throwProps, ease:Strong.easeOut,
					onUpdate:updateHandler, onComplete:stopAll },
				_tweenMaxDuration, _tweenMinDuration, 0.2 );
		}
		
		/**
		 * 帧事件处理，更新位置和位图缓存 
		 * @param e
		 * 
		 */		
		protected function updateHandler( e:Event = null ):void
		{
			if( _blitMask )
			{
				_blitMask.update();
			}
			updateSideBar();
			
			var i:int;
			var numChildren:int = _target.numChildren;
			var child:DisplayObject;
			for(i = 0; i < numChildren; i++)
			{
				child = _target.getChildAt( i );
				//对所有滑移对象的子项，若其超过mask超过一定距离MAX_VISIBLE_DIST
				//则将其visible设为false
				if( _direct == ScrollDirection.VECTORIAL || _direct == ScrollDirection.BOTH )
				{
					if( child.y + child.height + _target.y < _bounds.top - MAX_VISIBLE_DIST ||
						child.y + _target.y > _bounds.bottom + MAX_VISIBLE_DIST )
					{
						child.visible = false;
					}
					else
					{
						child.visible = true;
					}
				}
				else if( _direct == ScrollDirection.HORIZONTAL || _direct == ScrollDirection.BOTH )
				{
					if( child.x + child.width + _target.x < _bounds.left - MAX_VISIBLE_DIST ||
						child.x + _target.x > _bounds.right + MAX_VISIBLE_DIST )
					{
						child.visible = false;
					}
					else
					{
						child.visible = true;
					}
				}
			}
			
		}
		/**
		 * 若blitmask存在，则启用其位图渲染模式 
		 * 
		 */		
		protected function enableBlitMask():void
		{
			if( _blitMask )
			{
				_blitMask.enableBitmapMode();
			}
		}
		
		/**
		 * 若blitmask存在，则禁用其位图渲染模式 
		 * 
		 */	
		protected function disableBlitMask():void
		{
			if( _blitMask )
			{
				_blitMask.disableBitmapMode();
			}
		}
		
		/**
		 * 启用滑移目标的鼠标属性 
		 * 
		 */		
		protected function enableTargetMouse():void
		{
			_target.mouseChildren = _target.mouseEnabled = true;
		}
		
		/**
		 * 禁用滑移目标的鼠标属性
		 * 
		 */		
		protected function disableTargetMouse():void
		{
			_target.mouseChildren = _target.mouseEnabled = false;
		}
		
		/**
		 * 移除所有事件侦听 
		 * 
		 */		
		protected function removeAllListeners():void
		{
			AirScroll.log( "removeAllListeners" );
			_bg.removeEventListener( Event.ENTER_FRAME, updateHandler );
			if( _useTouchEvent )
			{
				_bg.removeEventListener( TouchEvent.TOUCH_BEGIN, mouseDownHandler );
				_bg.removeEventListener( TouchEvent.TOUCH_MOVE, mouseMoveHandler );
				_bg.removeEventListener( TouchEvent.TOUCH_END, mouseLeaveHandler );
				_bg.removeEventListener( TouchEvent.TOUCH_ROLL_OUT, mouseLeaveHandler );	
			}
			else
			{
				_bg.removeEventListener( MouseEvent.MOUSE_DOWN, mouseDownHandler );
				_bg.removeEventListener( MouseEvent.MOUSE_MOVE, mouseMoveHandler );
				_bg.removeEventListener( MouseEvent.MOUSE_UP, mouseLeaveHandler );
				_bg.removeEventListener( MouseEvent.ROLL_OUT, mouseLeaveHandler );				
			}
		}
		
		/**
		 * 停止所有滑移 
		 * 
		 */		
		protected function stopAll():void
		{
			if( _bg.stage )
			{
				_bg.stage.quality = _stageQuality;
			}
			_bg.removeEventListener( Event.ENTER_FRAME, updateHandler );
			killTweens();
			disableBlitMask();
			enableTargetMouse();
			tweenHideSideBar();
			_isMouseMoved = false;
		}
		
		/**
		 * 停止所有缓动，并清除之 
		 * 
		 */		
		protected function killTweens():void
		{
			TweenLite.killTweensOf( _target );
			AirScroll.log("kill tweens");
		}
		
		/**
		 * 销毁所有跟滑移有关的对象和事件侦听，回收内存 
		 * 
		 */		
		protected function dispose():void
		{
			killTweens();
			removeAllListeners();
			if( _blitMask )
			{
				_blitMask.dispose();
				_blitMask = null;
			}
			if( _mask )
			{
				_mask.graphics.clear();
				if( _mask.parent )
				{
					_mask.parent.removeChild( _mask );					
				}
				_mask = null;
			}
		}
		
	}
}