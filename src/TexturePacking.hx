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
class TexturePacking
{
	//fieldWidthを決定する際に使う割る値
	static inline var DEVIDE_NUMBER = 3;
	
	//全てのテクスチャの幅から算出した生成する画像の幅を保持
	public var fieldWidth(default,null):Int;

	public function new()
	{
		// 3つのサブテクスチャを作る
		var subTextures = createVariousSubTextures(3, 50, 50);
		var regions:Array<Region> = [];
		
		sortHeightHigher(subTextures);
		//trace(subTextures);
		configureTexturesheight(subTextures, regions);
		//trace(regions);
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
		return subTextures.map(function(s:SubTexture) return s.width).fold(function(a:Int,b:Int)return a+b,0);
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
	* とりあえず高さをずらしてみている
**/

	private static function configureTexturesheight(subTextures:Array<SubTexture>, regions:Array<Region>)
	{
		var totalHeight = 0;
		var totalWidth = 0;
		var x = 0;
		for (i in 0 ... subTextures.length)
		{
			if (x < 2)
			{
				regions[i] = {
				x:totalWidth, y:totalHeight, width:subTextures[i].width, height:subTextures[i].height, rotated:false
				}
				totalHeight += regions[i].height;
				x++;
			} else if (x == 2)
			{
				totalHeight = 0;
				totalWidth = regions[i - 2].width;
				regions[i] = {
				x:totalWidth, y:totalHeight, width:subTextures[i].width, height:subTextures[i].height, rotated:false
				}
				totalHeight = regions[i].height;
				x = 1;
			}
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