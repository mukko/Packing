package ;

import flash.geom.Point;
import flash.geom.Rectangle;
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
class TexturePacking
{
	static inline var TEXTURE_NUMBER = 5;
	static inline var MAX_WIDTH = 100;
	static inline var MAX_HEIGHT = 100;

	var fieldWidth = 64;
	var fieldHeight = 64;

	public function new()
	{
		// 3つのサブテクスチャを作る
		var subTextures = createVariousSubTextures(TEXTURE_NUMBER, MAX_WIDTH, MAX_HEIGHT);
		var regions:Array<Region> = [];
		sortHeightHigher(subTextures);
		var p = new Point(0, 0);
		var points:Array<Point> = [p];
		var rectangle = new Rectangle(0, 0, subTextures[0].width, subTextures[0].height);
		var startPoints:Array<Rectangle> = [rectangle];

		trace(subTextures);

		//var fieldWidth = Math.floor(totalTextureWidth(subTextures) / Math.floor(subTextures.length));
		//var fieldWidth = 64;
		//var fieldHeight = 64;
		tomo_algorithm(subTextures, regions, points, fieldWidth, 64);
		drawRegions(regions);
		trace(fieldWidth, fieldHeight);
		drawLine(fieldWidth, fieldHeight);
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
	*全サブテクスチャの幅の合計値を算出する
	* @param	subTextures サブテクスチャの集合
	* @return	幅の合計
**/

	private static function totalTextureWidth(subTextures:Array<SubTexture>):Int
	{
		return subTextures.map(function(s:SubTexture) return s.width).fold(function(a:Int, b:Int)return a + b, 0);
	}

	/**
	*複数のサブテクスチャを高さの昇順にソートする
	* @param	subTextures サブテクスチャの集合
**/

	private static function sortHeightHigher(subTextures:Array<SubTexture>):Void
	{
		subTextures.sort(function(a:SubTexture, b:SubTexture) return b.height - a.height);
	}

	/**
	*複数のサブテクスチャを幅の昇順にソートする
	* @param	subTextures サブテクスチャの集合
**/

	private static function sortWidthHigher(subTextures:Array<SubTexture>):Void
	{
		subTextures.sort(function(a:SubTexture, b:SubTexture) return b.width - a.width);
	}

	/**
	*複数のサブテクスチャの位置を決定し、regionsに突っ込む
	* @param	subTextures サブテクスチャの集合
	* @param	regions 描画する領域の集合
	* @param	fieldHeight 幅の値
	* とりあえず高さをずらしてみている
**/

	private static function configureTexturesheight(subTextures:Array<SubTexture>, regions:Array<Region>, fieldWidth:Int)
	{
		var totalHeight = 0;
		var totalWidth = 0;
		var saveHeight = 0;
		var counter = 0;
		for (i in 0 ... subTextures.length)
		{
			if (totalWidth < fieldWidth)
			{
				regions[i] = {
				x:totalWidth, y:totalHeight, width:subTextures[i].width, height:subTextures[i].height, rotated:false
				}
				totalWidth += regions[i].width;
				if (counter == 0) saveHeight = regions[i].height;
				counter++;
			} else
			{
				totalHeight += saveHeight;
				totalWidth = 0;
				regions[i] = {
				x:totalWidth, y:totalHeight, width:subTextures[i].width, height:subTextures[i].height, rotated:false
				}
				totalWidth = regions[i].width;
				saveHeight = regions[i].height;
				counter = 1;
			}
		}
	}

	private static function test_algorithm(subTextures:Array<SubTexture>, regions:Array<Region>, stageWidth:Int)
	{
		//var points:Array<Point> = {0,0};
		//while(subTextures.)
	}
	/**
	*実装したアルゴリズム
**/

	private static function tomo_algorithm(subTextures:Array<SubTexture>, regions:Array<Region>, points:Array<Point>, stageWidth:Int,
										   stageHeight:Int):Void
	{
		//var pointPos = 0;//startPointsの使用する番号を保持
		//var subtexturePos = 0;//subTexturesの使用する番号を保持
		var lower = 10000;//高さとstageHeightの差が低い物が保持される
		while (true)
		{
			var pointPos = 0;//startPointsの使用する番号を保持
			var subtexturePos = 0;//subTexturesの使用する番号を保持
			//全ての要素に対して探索をする
			for (i in 0...points.length)
			{
				for (j in 0...subTextures.length)
				{
					var com;
					if (stageHeight - subTextures[j].height < 0)
					{
						stageHeight *= 2;
						tomo_algorithm(subTextures, regions, points, stageWidth, stageHeight);
					}
					if (stageWidth - subTextures[j].width < 0)
					{
						stageWidth *= 2;
						tomo_algorithm(subTextures, regions, points, stageWidth, stageHeight);
					}
					if (points[i + 1] == null) com = Math.floor(stageHeight -
																(points[i].y + subTextures[j].height)); else com = Math.floor(points[i].y -
																															  subTextures[j].height);
					//if (com < 0) tomo_algorithm(subTextures, regions, startPoints, stageWidth, stageHeight *= 2);
					if (com >= 0 && subTextures[j].width + points[i].x < stageWidth && com < lower)
					{
						lower = com;
						pointPos = i;
						subtexturePos = j;
					}
				}
			}

			//高さがどれも足りなかったら高さを2倍にしてもう一度
			//if (lower == 10000) tomo_algorithm(subTextures, regions, points, stageWidth, stageHeight * 2);

			var sTstPos = subTextures[subtexturePos];
			var sPpPos = points[pointPos];

			//regionsに要素を追加
			var region:Region = {
			x:Math.floor(sPpPos.x), y:Math.floor(sPpPos.y), width:sTstPos.width, height:sTstPos.height, rotated:false
			};

			regions.push(region);

			//startPointsにポイントを追加
			//左下
			var pointRect1 = new Point(
			sPpPos.x, sTstPos.height + sPpPos.y + 1);
			points.push(pointRect1);
			//右上
			var pointRect2 = new Point(
			sTstPos.width + sPpPos.x + 1, sPpPos.y);
			points.push(pointRect2);

			//startPointsから使ったポイントを削除
			points.remove(sPpPos);
			//subTexturesから使った画像を削除
			subTextures.remove(sTstPos);

			trace(sTstPos);
			trace(regions);
			trace(subTextures);
			trace(points);

			if (subTextures.length == 0) break;
		}
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
