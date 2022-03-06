/*
 * @Author       : Linloir
 * @Date         : 2022-03-05 21:40:51
 * @LastEditTime : 2022-03-06 23:13:23
 * @Description  : Validation Provider class
 */

import 'package:flutter/material.dart';
import './event_bus.dart';
import './generator.dart';

enum InputType { singleCharacter, backSpace, inputConfirmation }

class InputNotification extends Notification {
  const InputNotification({required this.type, required this.msg});

  final InputType type;
  final String msg;
}

class ValidationProvider extends StatefulWidget {
  const ValidationProvider({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  State<ValidationProvider> createState() => _ValidationProviderState();
}

class _ValidationProviderState extends State<ValidationProvider> {
  String answer = "";
  Map<String, int> letterMap = {};
  String curAttempt = "";
  int curAttemptCount = 0;
  bool acceptInput = true;

  void _onNewGame(dynamic args) {
    _newGame();
  }

  void _newGame() async{
    answer = await Words.generateWord();
    answer = answer.toUpperCase();
    letterMap = {};
    answer.split('').forEach((c) {
      letterMap[c] ??= 0;
      letterMap[c] = letterMap[c]! + 1;
    });
    letterMap = Map.unmodifiable(letterMap);
    curAttempt = "";
    curAttemptCount = 0;
    acceptInput = true;
  }

  void _onGameEnd(dynamic args) {
    args as bool ? _onGameWin() : _onGameLoose();
  }

  void _onGameWin() {
    acceptInput = false;
    _showResult(true);
  }

  void _onGameLoose() {
    acceptInput = false;
    _showResult(false);
  }

  void _showResult(bool result) async {
    var startNew = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Result'),
          content: Text(result ? "Won" : "Lost, answer is $answer"),
          actions: [
            TextButton(
              child: const Text('Back'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('New Game'),
              onPressed: () => Navigator.of(context).pop(true),
            )
          ],
        );
      }
    );
    if(startNew == true) {
      mainBus.emit(event: "NewGame", args: []);
    }
  }

  @override
  void initState(){
    super.initState();
    _newGame();
    mainBus.onBus(event: "NewGame", onEvent: _onNewGame);
    mainBus.onBus(event: "Result", onEvent: _onGameEnd);
  }

  @override
  void dispose() {
    mainBus.offBus(event: "NewGame", callBack: _onNewGame);
    mainBus.offBus(event: "Result", callBack: _onGameEnd);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<InputNotification>(
      child: widget.child,
      onNotification: (noti) {
        if(noti.type == InputType.inputConfirmation) {
          if(curAttempt.length < 5) {
            //Not enough
            return true;
          }
          else {
            //Check validation
            if(Words.isWordValidate(curAttempt)) {
              //Generate map
              Map<String, int> leftWordMap = Map.from(letterMap);
              var positionValRes = <int>[for(int i = 0; i < 5; i++) -1];
              var letterValRes = <String, int>{};
              for(int i = 0; i < 5; i++) {
                if(curAttempt[i] == answer[i]) {
                  positionValRes[i] = 1;
                  leftWordMap[curAttempt[i]] = leftWordMap[curAttempt[i]]! - 1;
                  letterValRes[curAttempt[i]] = 1;
                }
              }
              for(int i = 0; i < 5; i++) {
                if(curAttempt[i] != answer[i] && leftWordMap[curAttempt[i]] != null && leftWordMap[curAttempt[i]]! > 0) {
                  positionValRes[i] = 2;
                  leftWordMap[curAttempt[i]] = leftWordMap[curAttempt[i]]! - 1;
                  letterValRes[curAttempt[i]] = letterValRes[curAttempt[i]] == 1 ? 1 : 2;
                }
                else if(curAttempt[i] != answer[i]) {
                  positionValRes[i] = -1;
                  letterValRes[curAttempt[i]] ??= -1;
                }
              }
              //emit current attempt
              mainBus.emit(
                event: "Attempt",
                args:  positionValRes,
              );
              mainBus.emit(
                event: "Validation",
                args: letterValRes,
              );
              curAttempt = "";
              curAttemptCount++;
            }
            else {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Info'),
                    content: const Text('Not a word!'),
                    actions: [
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    ],
                  );
                }
              );
            }
          }
        }
        else if(noti.type == InputType.backSpace) {
          if(curAttempt.isNotEmpty) {
            curAttempt = curAttempt.substring(0, curAttempt.length - 1);
          }
        }
        else{
          if(acceptInput && curAttempt.length < 5) {
            curAttempt += noti.msg;
          }
        }
        return true;
      },
    );
  }
}
