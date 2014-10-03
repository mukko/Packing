package ;

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
	static inline var TEXTURE_NUMBER = 30;
	static inline var MAX_WIDTH = 100;
	static inline var MAX_HEIGHT = 100;

	public function new()
	{
		// 3つのサブテクスチャを作る
		var subTextures = createVariousSubTextures(TEXTURE_NUMBER, MAX_WIDTH, MAX_HEIGHT);
		var regions:Array<Region> = [];
		var rectangle = new Rectangle(0,0,subTextures[0].width,subTextures[0].height);
		var startPoints:Array<Rectangle> = [rectangle];
		sortHeightHigher(subTextures);
		var fieldWidth = Math.floor(totalTextureWidth(subTextures) / subTextures.length);
		tomo_algorithm(subTextures, regions, startPoints, fieldWidth, 64, -1);

		drawRegions(regions);
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

	/**
	*実装したアルゴリズム
**/

	private static function tomo_algorithm(subTextures:Array<SubTexture>, regions:Array<Region>, startPoints:Array<Rectangle>,
										   stageWidth:Int, stageHeight:Int, highest:Int):Void
	{
		var pointPos = 0;//startPointsの使用する番号を保持
		var subtexturePos = 0;//subTexturesの使用する番号を保持

		while (subTextures.length > 0)
		{
			//全ての要素に対して探索をする
			for (i in 0...startPoints.length)
			{
				for (j in 0... subTextures.length)
				{
					var com = Math.floor(stageHeight - (startPoints[i].y + subTextures[j].height));
					if (com > 0 || subTextures[j].width + startPoints[i].x < stageWidth || com < highest)
					{
						highest = com;
						pointPos = i;
						subtexturePos = j;
					}
				}
			}

			if (highest < 0) tomo_algorithm(subTextures, regions, startPoints, stageWidth, stageHeight *= 2, -1);

			//regionsに要素を追加
			var region:Region = {
						x:Math.floor(startPoints[pointPos].x),
						y:Math.floor(startPoints[pointPos].y),
						width:subTextures[subtexturePos].width, 
						height:subTextures[subtexturePos].height, 
						rotated:false
		};
			regions.push(region);

				//startPointsにポイントを追加
				//右上
				var pointRect1 = new Rectangle(
						subTextures[subtexturePos].width + startPoints[pointPos].x, 
						subTextures[subtexturePos].height, 
						subTextures[subtexturePos].width, 
						subTextures[subtexturePos].height);
			startPoints.push(pointRect1);
				//左下
				var pointRect2 = new Rectangle(
						subTextures[subtexturePos].width, 
						subTextures[subtexturePos].height + startPoints[pointPos].y, 
						subTextures[subtexturePos].width, 
						subTextures[subtexturePos].height
				);
			startPoints.push(pointRect2);

			//startPointsから使ったポイントを削除
		startPoints.remove(startPoints[pointPos]);
			//subTexturesから使った画像を削除
		subTextures.remove(subTextures[subtexturePos]);
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

}
