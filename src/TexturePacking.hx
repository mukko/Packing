package ;

import flash.display.Shape;
import flash.Lib;

using Lambda;
/**
*true	回転する
*false	回転しない
**/
/** どこにどう配置するか */
typedef Region = {
x:Int, y:Int, width:Int, height:Int, rotated:Bool,
}

/** 敷き詰めるサブテクスチャ */
typedef SubTexture = {
width:Int, height:Int,
}

typedef AlphaSubTexture = {
width:Int, height:Int, rotated:Bool,
}

class TexturePacking
{
	static inline var TEXTURE_NUMBER = 30;
	static inline var MAX_WIDTH = 100;
	static inline var MAX_HEIGHT = 100;
	static inline var DEFAULT_AREA_SIZE = 100000;
	//書き込み、読み出しはどこからでも可能
	static public var size(default, default) = 2;

	public function new()
	{
		// 3つのサブテクスチャを作る
		var begin = Lib.getTimer();
		var subTextures = createVariousSubTextures(TEXTURE_NUMBER, MAX_WIDTH, MAX_HEIGHT);
		var regions:Array<Region> = [];
		//FFDH(高さ降順のファーストフィット)アルゴリズム
		regions = ffdhAlgorithm(subTextures);
		trace("FIN =>" +size);
		drawLine(size, size);
		drawRegions(regions);
		var end = Lib.getTimer();
		trace(end - begin);
		trace(totalSurfaceArea(subTextures) / (size * size));
	}

	/**
	 * 任意の数のランダムな大きさのサブテクスチャを生成する
	 * @param	numSubTextures 生成するサブテクスチャの数
	 * @param	maxWidth サブテクスチャの最大の幅 [px]
	 * @param	maxHeight サブテクスチャの最大の高さ [px]
	 * @return 生成されたサブテクスチャ集合
	 */

	private static function createVariousSubTextures(numSubTextures:Int, maxWidth:Int, maxHeight:Int):Array<SubTexture>
	{
		return [for (i in 0...numSubTextures)
	{ width : Std.random(maxWidth) + 1, height : Std.random(maxHeight) + 1 } ];
	}

	/**
	 * 複数のサブテクスチャの合計の表面積を算出する
	 * @param	subTextures サブテクスチャの集合
	 * @return 合計の表面積
	 */

	private static function totalSurfaceArea(subTextures:Array<SubTexture>):Int
	{
		return subTextures
		.map(function(s:SubTexture) return s.width * s.height)
		.fold(function(a:Int, b:Int) return a + b, 0);
	}


	/**
*alphaSubTexturesを降順にソート
* @param		alpasubTextures	サブテクスチャの集合
**/

	private static function sortalphaSubHigher(alphasubTextures:Array<AlphaSubTexture>):Void
	{
		for (alpha in alphasubTextures)
		{
			var width:Int = alpha.width;
			var height:Int = alpha.height;
			if (height < width) alpha.rotated = true;
		}
		alphasubTextures.sort(function(a:AlphaSubTexture, b:AlphaSubTexture)
							  {
								  if (a.rotated && !b.rotated) return b.height - a.width; else if (b.rotated && !a.rotated) return b.width -
																																   a.height; else if (a.rotated &&
																																					  b.rotated) return b.width -
																																										a.width; else return b.height -
																																															 a.height;
							  });
	}

	/**
	*複数のサブテクスチャを高さの降順にソートする
	* @param	subTextures サブテクスチャの集合
**/

	private static function sortHeightHigher(subTextures:Array<SubTexture>):Void
	{
		subTextures.sort(function(a:SubTexture, b:SubTexture) return b.height - a.height);
	}

	/**
	*alphasubTexruesをsubTexturesからつくる
	* @param	alphas	AlphaSubTextureの集合
	* @param	subTextures	SubTextureの集合
**/

	private static function makeAlphaArray(alphas:Array<AlphaSubTexture>, subTextures:Array<SubTexture>):Void
	{
		for (sub in subTextures)
		{
			var alpha:AlphaSubTexture = {width:sub.width, height:sub.height, rotated:false};
			alphas.push(alpha);
		}
	}

	/**
	*FFDHアルゴリズム
	* @param	subTextures	サブテクスチャの集合
	* @return	Regionの集合
**/

	private static function ffdhAlgorithm(subTextures:Array<SubTexture>):Array<Region>
	{
		var regions:Array<Region> = [];

		for (textureSize in [64, 128, 256, 512, 1024, 2048])
		{
			size = textureSize;
			regions = [];
			var alphas:Array<AlphaSubTexture> = [];
			makeAlphaArray(alphas, subTextures);
			sortalphaSubHigher(alphas);
			var x:Int = 0;
			var y:Int = 0;
			var level:Int = 0;
			for (alpha in alphas)
			{
				if (alpha.rotated)
				{
					if (x + alpha.height < size)
					{
						if (y + alpha.width < size)
						{
							regions.push({x:x, y:y, width:alpha.width, height:alpha.height, rotated:true});
							if (x == 0) level += alpha.width;
							x += alpha.height;
						}
					} else
					{
						x = 0;
						if (y + alpha.width < size)
						{
							regions.push({x:x, y:level, width:alpha.width, height:alpha.height, rotated:true});
							x += alpha.height;
							y = level;
							level += alpha.width;
						}
					}
				} else
				{
					if (x + alpha.width < size)
					{
						if (y + alpha.height < size)
						{
							regions.push({x:x, y:y, width:alpha.width, height:alpha.height, rotated:false});
							if (x == 0) level += alpha.height;
							x += alpha.width;
						}
					} else
					{
						x = 0;
						if (y + alpha.height < size)
						{
							regions.push({x:x, y:level, width:alpha.width, height:alpha.height, rotated:false});
							x += alpha.width;
							y = level;
							level += alpha.height;
						}
					}
				}
			}
			if (regions.length == TEXTURE_NUMBER) break;
		}
		return regions;
	}

	/**
	 * （確認用）領域をステージ（flash.display.Stage）に描画する
	 * @param	regions 描画する領域の集合
	 */

	private static function drawRegions(regions:Array<Region>):Void
	{
		for (region in regions)
		{
			var shape:Shape = new Shape();
			shape.graphics.lineStyle(0, 0x000000);
			shape.graphics.beginFill(Std.random(0xFFFFFF), 0.2);
			shape.graphics.drawRect(0, 0, region.width, region.height);
			shape.graphics.endFill();
			shape.graphics.lineStyle(0, 0xFF0000);
			shape.graphics.moveTo(0, 0);
			shape.graphics.lineTo(region.width, region.height);
			shape.x = region.x;
			shape.y = region.y;
			shape.graphics.lineTo(region.width, region.height);
			if (region.rotated)
			{
				shape.rotation = 90;
				shape.x = shape.x + shape.width;
			}
			Lib.current.stage.addChild(shape);
		}
	}
	/**
	*外枠の線を描く
	* @param	width	x座標とも言う
	* @param	height	y座標とも言う
**/

	private static function drawLine(width:Int, height:Int)
	{
		var w:Shape = new Shape();
		w.graphics.lineStyle(1, 0x00FF00);
		w.graphics.moveTo(0, height);
		w.graphics.lineTo(width, height);
		var h:Shape = new Shape();
		h.graphics.lineStyle(1, 0x00FF00);
		h.graphics.moveTo(width, 0);
		h.graphics.lineTo(width, height);
		Lib.current.stage.addChild(w);
		Lib.current.stage.addChild(h);
	}
}
