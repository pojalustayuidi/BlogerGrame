import 'package:flutter_test/flutter_test.dart';
import 'package:blogergrame/features/catalog/domain/catalog_models.dart';
import 'package:blogergrame/features/catalog/presentation/catalog_access_rules.dart';
LevelSummary level(int id,{bool completed=false})=>LevelSummary(
  id:'level-$id',category:'streamers',number:id,letters:30,
  difficulty:'normal',completed:completed,preview:false);
void main(){
  test('future levels stay locked and completed cannot replay',(){
    final data=[level(1,completed:true),level(2),level(3)];
    expect(nextPlayableLevel(data)?.id,'level-2');
    expect(mayStartLevel(level:data[0],levels:data,lives:5),false);
    expect(mayStartLevel(level:data[1],levels:data,lives:5),true);
    expect(mayStartLevel(level:data[2],levels:data,lives:5),false);
  });
  test('zero lives locks even recommended level',(){
    final data=[level(1)];
    expect(mayStartLevel(level:data[0],levels:data,lives:0),false);
  });
  test('complete pack has no available level',(){
    expect(nextPlayableLevel([level(1,completed:true)]),isNull);
  });
}
