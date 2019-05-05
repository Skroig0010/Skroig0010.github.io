/*
   仮死状態になり特定の壁抜け出来る
   長すぎると死んでゲームオーバー
   敵に当たるとゲームオーバー
   スイッチを押す
   餌を食うと仮死時間アップ
   */
import h2d.*;
import h3d.*;
import hxd.*;
using Lambda;
class Program extends hxd.App {
    var tileSize(default, never) = 30;
    var moveSpeed(default, never) = 2;
    var you:Entity;
    var syncope:Entity;
    var walls = new Array<Entity>();
    var ghostWalls = new Array<Entity>();
    var enemies = new Array<Entity>();
    var swtches = new Array<Entity>();
    var vanishWalls = new Array<Entity>();

    var timerText:Text;

    var isGhost = false;
    var timer = 0;
    var isGameover = false;

    var yourTile:Tile;
    var ghostTile:Tile;
    var wallTile:Tile;
    var ghostWallTile:Tile;
    var enemyTile:Tile;
    var swtchTile:Tile;
    var vanishWallTile:Tile;


    var layerBG:Object;
    var layerSW:Object;
    var layerCHR:Object;
/*
    0:None;
    1:You;
    2:Wall;
    3:GhostWall;
    4:Enemy;
    5:VanishSwitch(obstacle:Obstacle);
    6:VanishWall(obstacle:Obstacle);
   */
    var map:Array<String> = [
        "222222222222222222222",
        "200000000000000000002",
        "200000000000000000002",
        "200000000000000000002",
        "200000000000000000002",
        "200000000000000000002",
        "200000000000000000002",
        "200000000000000000002",
        "200000000000000000002",
        "200000000000000000002",
        "200000000000000000002",
        "200000050000000000002",
        "222222223620000000002",
        "200506000020000000002",
        "201002200020000000002",
        "222220022222222222222",
        ];

    var idMap:Map<String, Int> =[
        "14,4"=>0,
        "14,6"=>0,

        "12,8"=>2,
        "13,10"=>2,
    ];

    override function init() {
        engine.backgroundColor = 0x404040;
        yourTile = Tile.fromColor(0x00FF00, Std.int(tileSize*0.8), Std.int(tileSize*0.8));
        ghostTile = Tile.fromColor(0x88AA88, Std.int(tileSize*0.8), Std.int(tileSize*0.8));
        wallTile = Tile.fromColor(0x000000, tileSize, tileSize);
        ghostWallTile = Tile.fromColor(0x333333, tileSize, tileSize);
        enemyTile = Tile.fromColor(0xFF0000, Std.int(tileSize*0.8), Std.int(tileSize*0.8));
        swtchTile = Tile.fromColor(0xFF88FF, Std.int(tileSize/2), Std.int(tileSize/2));
        vanishWallTile = Tile.fromColor(0x666600, tileSize, tileSize);

        layerBG = new Object();
        layerSW = new Object();
        layerCHR = new Object();


        s2d.addChild(layerBG);
        s2d.addChild(layerSW);
        s2d.addChild(layerCHR);

        timerText = new Text(hxd.res.DefaultFont.get(), s2d);

        for(y in 0...map.length){
            var s = map[y];
            for(x in 0...s.length){
                var position = new Vector(x * tileSize, y * tileSize);
                switch(s.charAt(x)){
                    case "0":
                    case "1":
                        you = makeEntity(You, position);
                    case "2":
                        walls.push(makeEntity(Wall, position));
                    case "3":
                        ghostWalls.push(makeEntity(GhostWall, position));
                    case "4":
                        enemies.push(makeEntity(Enemy, position));
                    case "5":
                        swtches.push(makeEntity(VanishSwitch(idMap.get(""+(y+1)+","+(x+1))), position));
                    case "6":
                        vanishWalls.push(makeEntity(VanishWall(idMap.get(""+(y+1)+","+(x+1))), position));
                }
            }
        }
    }

    override function update(dt:Float) {
        if(isGameover){
            engine.backgroundColor = 0x000000;
            var tf = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
            tf.x = 100;
            tf.y = 100;
            tf.text = "Game Over!";
        }else{
            game();
        }
    }

    function game(){
        if (Key.isDown(Key.LEFT)) {
            you.position.x-=moveSpeed;
        }

        if (Key.isDown(Key.RIGHT)) {
            you.position.x+=moveSpeed;
        }

        if (Key.isDown(Key.UP)) {
            you.position.y-=moveSpeed;
        }

        if (Key.isDown(Key.DOWN)) {
            you.position.y+=moveSpeed;
        }
        if (Key.isPressed(Key.SPACE)) {
            // 重なっている状態
            if(isGhost && syncope != null && syncope.bmp.getBounds().intersects(you.bmp.getBounds())){
                isGhost = false;
                layerCHR.removeChild(you.bmp);
                you.bmp = syncope.bmp;
                you.position = syncope.position;
                syncope = null;
            }else if(!isGhost){
                isGhost = true;
                syncope = new Entity();
                syncope.position = you.position.clone();
                syncope.bmp = you.bmp;
                you.bmp = new Bitmap(ghostTile, layerCHR);
                timer = 240;
            }
        }

        if(isGhost){
            timer--;
            timerText.text = "" + Std.int(timer/60);
            if(timer<0){
                isGameover = true;
            }
        }else{
            timerText.text = "";
        }
        for(wall in walls){
            collision(you, wall);
        }

        for(vanishWall in vanishWalls){
            collision(you, vanishWall);
        }

        for(ghostWall in ghostWalls){
            if(!isGhost){
                collision(you, ghostWall);
            }
        }

        swtches = swtches.filter((swtch)->{
            if(you.bmp.getBounds().intersects(swtch.bmp.getBounds())){
                switch(swtch.type){
                    case VanishSwitch(id):
                        layerSW.removeChild(swtch.bmp);
                        // 壁を探して消去
                        var wall = vanishWalls.find((wall)->{
                            return switch(wall.type){
                                case VanishWall(wallId):
                                    id == wallId;
                                default:
                                    false;
                            };
                        });
                        layerBG.removeChild(wall.bmp);
                        vanishWalls.remove(wall);
                        return false;
                    default:
                        throw "swtch";

                }
            }
            return true;
        });

        setPosition();
    }

    function collision(mover:Entity, wall:Entity){
        if(mover.bmp.getBounds().intersects(wall.bmp.getBounds())){
            var v = mover.position.sub(wall.position);
            v.scale3(1/v.length());
            if(Math.abs(v.x) > Math.abs(v.y)){
                v.y = 0;
            }else if(Math.abs(v.x) < Math.abs(v.y)){
                v.x = 0;
            }
            v.scale3(moveSpeed+1);
            mover.position = mover.position.add(v);
        }
    }

    function setPosition(){
        you.bmp.x = you.position.x;
        you.bmp.y = you.position.y;
        timerText.x = you.position.x;
        timerText.y = you.position.y - 20;
    }

    function makeEntity(obstacle:Obstacle, position:Vector):Entity{
        var entity = new Entity();
        entity.position = position;
        entity.type = obstacle;
        entity.bmp = switch(obstacle){
            case You:
                new Bitmap(yourTile, layerCHR);
            case Wall:
                new Bitmap(wallTile, layerBG);
            case GhostWall:
                new Bitmap(ghostWallTile, layerBG);
            case Enemy:
                new Bitmap(enemyTile, layerCHR);
            case VanishSwitch(_):
                new Bitmap(swtchTile, layerSW);
            case VanishWall(_):
                new Bitmap(vanishWallTile, layerBG);
            case None:
                throw "makeEntity";
        }
        entity.bmp.x = position.x;
        entity.bmp.y = position.y;
        return entity;
    }

    static function main() {
        new Program();
    }

}

class Entity{
    public var position:Vector;
    public var bmp:Bitmap;
    public var type:Obstacle;
    public function new(){}
}

enum Obstacle{
    None;
    You;
    Wall;
    GhostWall;
    Enemy;
    VanishSwitch(id:Int);
    VanishWall(id:Int);
}
