/*
 * @Author       : Linloir
 * @Date         : 2022-03-06 15:03:57
 * @LastEditTime : 2022-03-07 08:34:56
 * @Description  : Word generator
 */

import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:math';

abstract class Words {
  static Set<String> dataBase = <String>{};
  static int _length = 0;
  static String _cache = "";
  //static Map<String, String> explainations = {};

  static Future<void> importWordsDatabase({int length = 5}) async {
    //explainations.clear();
    if(length != _length || dataBase.isEmpty){
      _length = length;
      dataBase.clear();
      _cache = "";
      var data = await rootBundle.loadString('popular.txt');
      // LineSplitter.split(data).forEach((line) {
      //   int seperatePos = line.indexOf(',');
      //   if(seperatePos != length + 2) {
      //     return;
      //   }
      //   var word = line.substring(1, seperatePos - 1);
      //   var expl = line.substring(seperatePos + 2, line.length - 1);
      //   dataBase.add(word);
      //   explainations[word] = expl;
      // });
      LineSplitter.split(data).forEach((line) {
        if(line.length == length && line != _cache) {
          dataBase.add(line.toLowerCase());
        }
        _cache = line + "s";
      });
      print('Imported ${dataBase.length}');
    }
  }

  static Future<String> generateWord() async{
    int bound = dataBase.length;
    if(bound == 0) {
      await Words.importWordsDatabase();
      bound = dataBase.length;
    }
    var rng = Random();
    return dataBase.elementAt(rng.nextInt(bound));
  }

  static bool isWordValidate(String word) {
    return dataBase.lookup(word.toLowerCase()) != null;
  }
}

