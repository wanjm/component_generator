import 'dart:io';

const ERROR = "ERROR";
const WARN = "WARN";
const INFO = "INFO";
const DEBUG = "DEBUG";

const LEVEL_ERROR = 3;
const LEVEL_WARN = 2;
const LEVEL_INFO = 1;
const LEVEL_DEBUG = 0;

const LEVEL = {ERROR: LEVEL_ERROR, WARN: LEVEL_WARN, INFO: LEVEL_INFO, DEBUG: LEVEL_DEBUG};


int logLevel = LEVEL_INFO;
int markLevel = -1;

bool error(dynamic info, [StackTrace? stackTrace = null]) => _print(ERROR, info, stackTrace);
bool warn(dynamic info, [StackTrace? stackTrace = null]) => _print(WARN, info, stackTrace);
void debug(dynamic info, [StackTrace? stackTrace = null]) {
  _print(DEBUG, info, stackTrace);
  //assert(_print(DEBUG, info));
}

bool info(dynamic info, [StackTrace? stackTrace = null]) => _print(INFO, info, stackTrace);
bool Function(String tag, dynamic info, StackTrace? stackTrace) _print = _print1;
bool _print1(String tag, dynamic info, [StackTrace? stackTrace = null]) {
  var time = DateTime.now();
  var content = "$tag ${time.hour}:${time.minute}:${time.second}.${time.millisecond} $info";
  print(content);
  return true;
}





void initMarkLevel(String dir) {
  logLevel = LEVEL_INFO;
  markLevel = -1;
  LEVEL.forEach((key, levelvalue) {
    print("initMarkLevel $key $levelvalue");
    var maskfile = File("$dir/$levelvalue.mark");
    maskfile.exists().then((value) {
      print("markLevel $value  $levelvalue $markLevel");
      if (value) {
        if (levelvalue > markLevel) {
          markLevel = levelvalue;
        }
        print("markLevel $markLevel");
      }
    });
  });
}

