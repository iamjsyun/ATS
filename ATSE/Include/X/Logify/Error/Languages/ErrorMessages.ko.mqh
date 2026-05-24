//+------------------------------------------------------------------+
//|                                             ErrorMessages.ko.mqh |
//|                                                     joaopedrodev |
//|                       https://www.mql5.com/en/users/joaopedrodev |
//+------------------------------------------------------------------+
#property copyright "joaopedrodev"
#property link      "https://www.mql5.com/en/users/joaopedrodev"
//+------------------------------------------------------------------+
//| Import struct                                                    
//+------------------------------------------------------------------+
#include "../Error.mqh"
void InitializeErrorsKorean(MqlError &errors[])
  {
   //--- Free and resize
   ArrayFree(errors);
   ArrayResize(errors,274);
   
   //+------------------------------------------------------------------+
   //| Unknown error                                                    |
   //+------------------------------------------------------------------+
   errors[0].code = 0;
   errors[0].description = "오류가 발견되지 않았습니다";
   errors[0].constant = "ERROR_UNKNOWN";
   //+------------------------------------------------------------------+
   //| Server error                                                     |
   //+------------------------------------------------------------------+
   errors[1].code = 10004;
   errors[1].description = "새로운 시세";
   errors[1].constant = "TRADE_RETCODE_REQUOTE";
   //---
   errors[2].code = 10006;
   errors[2].description = "요청이 거부되었습니다";
   errors[2].constant = "TRADE_RETCODE_REJECT";
   //---
   errors[3].code = 10007;
   errors[3].description = "요청이 딜러에 의해 취소되었습니다";
   errors[3].constant = "TRADE_RETCODE_CANCEL";
   //---
   errors[4].code = 10008;
   errors[4].description = "주문이 제출되었습니다";
   errors[4].constant = "TRADE_RETCODE_PLACED";
   //---
   errors[5].code = 10009;
   errors[5].description = "요청이 완료되었습니다";
   errors[5].constant = "TRADE_RETCODE_DONE";
   //---
   errors[6].code = 10010;
   errors[6].description = "요청의 일부만 완료되었습니다";
   errors[6].constant = "TRADE_RETCODE_DONE_PARTIAL";
   //---
   errors[7].code = 10011;
   errors[7].description = "요청 처리 오류";
   errors[7].constant = "TRADE_RETCODE_ERROR";
   //---
   errors[8].code = 10012;
   errors[8].description = "타임아웃으로 인한 요청 취소";
   errors[8].constant = "TRADE_RETCODE_TIMEOUT";
   //---
   errors[9].code = 10013;
   errors[9].description = "잘못된 요청";
   errors[9].constant = "TRADE_RETCODE_INVALID";
   //---
   errors[10].code = 10014;
   errors[10].description = "요청의 잘못된 볼륨";
   errors[10].constant = "TRADE_RETCODE_INVALID_VOLUME";
   //---
   errors[11].code = 10015;
   errors[11].description = "요청의 잘못된 가격";
   errors[11].constant = "TRADE_RETCODE_INVALID_PRICE";
   //---
   errors[12].code = 10016;
   errors[12].description = "요청의 잘못된 스톱";
   errors[12].constant = "TRADE_RETCODE_INVALID_STOPS";
   //---
   errors[13].code = 10017;
   errors[13].description = "거래가 비활성화되었습니다";
   errors[13].constant = "TRADE_RETCODE_TRADE_DISABLED";
   //---
   errors[14].code = 10018;
   errors[14].description = "시장이 닫혔습니다";
   errors[14].constant = "TRADE_RETCODE_MARKET_CLOSED";
   //---
   errors[15].code = 10019;
   errors[15].description = "요청을 완료할 충분한 자금이 없습니다";
   errors[15].constant = "TRADE_RETCODE_NO_MONEY";
   //---
   errors[16].code = 10020;
   errors[16].description = "가격이 변경되었습니다";
   errors[16].constant = "TRADE_RETCODE_PRICE_CHANGED";
   //---
   errors[17].code = 10021;
   errors[17].description = "요청을 처리할 시세가 없습니다";
   errors[17].constant = "TRADE_RETCODE_PRICE_OFF";
   //---
   errors[18].code = 10022;
   errors[18].description = "요청의 잘못된 주문 만료일";
   errors[18].constant = "TRADE_RETCODE_INVALID_EXPIRATION";
   //---
   errors[19].code = 10023;
   errors[19].description = "주문의 상태가 변경되었습니다";
   errors[19].constant = "TRADE_RETCODE_ORDER_CHANGED";
   //---
   errors[20].code = 10024;
   errors[20].description = "요청이 너무 많습니다";
   errors[20].constant = "TRADE_RETCODE_TOO_MANY_REQUESTS";
   //---
   errors[21].code = 10025;
   errors[21].description = "요청에 변경 사항이 없습니다";
   errors[21].constant = "TRADE_RETCODE_NO_CHANGES";
   //---
   errors[22].code = 10026;
   errors[22].description = "서버에서 자동거래가 비활성화되었습니다";
   errors[22].constant = "TRADE_RETCODE_SERVER_DISABLES_AT";
   //---
   errors[23].code = 10027;
   errors[23].description = "클라이언트 터미널에서 자동거래가 비활성화되었습니다";
   errors[23].constant = "TRADE_RETCODE_CLIENT_DISABLES_AT";
   //---
   errors[24].code = 10028;
   errors[24].description = "요청이 처리 위해 잠겼습니다";
   errors[24].constant = "TRADE_RETCODE_LOCKED";
   //---
   errors[25].code = 10029;
   errors[25].description = "주문 또는 포지션이 동결되었습니다";
   errors[25].constant = "TRADE_RETCODE_FROZEN";
   //---
   errors[26].code = 10030;
   errors[26].description = "잘못된 주문 체결 방식";
   errors[26].constant = "TRADE_RETCODE_INVALID_FILL";
   //---
   errors[27].code = 10031;
   errors[27].description = "거래 서버에 연결이 없습니다";
   errors[27].constant = "TRADE_RETCODE_CONNECTION";
   //---
   errors[28].code = 10032;
   errors[28].description = "이 작업은 실계좌에서만 허용됩니다";
   errors[28].constant = "TRADE_RETCODE_ONLY_REAL";
   //---
   errors[29].code = 10033;
   errors[29].description = "대기 중인 주문 수가 한도에 도달했습니다";
   errors[29].constant = "TRADE_RETCODE_LIMIT_ORDERS";
   //---
   errors[30].code = 10034;
   errors[30].description = "종목의 주문 및 포지션 볼륨이 한도에 도달했습니다";
   errors[30].constant = "TRADE_RETCODE_LIMIT_VOLUME";
   //---
   errors[31].code = 10035;
   errors[31].description = "잘못되었거나 금지된 주문 유형";
   errors[31].constant = "TRADE_RETCODE_INVALID_ORDER";
   //---
   errors[32].code = 10036;
   errors[32].description = "POSITION_IDENTIFIER로 지정된 포지션이 이미 청산되었습니다";
   errors[32].constant = "TRADE_RETCODE_POSITION_CLOSED";
   //---
   errors[33].code = 10038;
   errors[33].description = "청산 가능한 볼륨이 현재 포지션의 볼륨을 초과합니다";
   errors[33].constant = "TRADE_RETCODE_INVALID_CLOSE_VOLUME";
   //---
   errors[34].code = 10039;
   errors[34].description = "문서를 참조하십시오";
   errors[34].constant = "TRADE_RETCODE_CLOSE_ORDER_EXIST";
   //---
   errors[35].code = 10040;
   errors[35].description = "문서를 참조하십시오";
   errors[35].constant = "TRADE_RETCODE_LIMIT_POSITIONS";
   //---
   errors[36].code = 10041;
   errors[36].description = "대기 주문 활성화 요청이 거부되어 주문이 취소되었습니다";
   errors[36].constant = "TRADE_RETCODE_REJECT_CANCEL";
   //---
   errors[37].code = 10042;
   errors[37].description = "이 종목에는 '롱 포지션만 허용' 규칙이 설정되어 있습니다 (POSITION_TYPE_BUY)";
   errors[37].constant = "TRADE_RETCODE_LONG_ONLY";
   //---
   errors[38].code = 10043;
   errors[38].description = "이 종목에는 '쇼트 포지션만 허용' 규칙이 설정되어 있습니다 (POSITION_TYPE_SELL)";
   errors[38].constant = "TRADE_RETCODE_SHORT_ONLY";
   //---
   errors[39].code = 10044;
   errors[39].description = "이 종목에는 '포지션 청산만 허용' 규칙이 설정되어 있습니다";
   errors[39].constant = "TRADE_RETCODE_CLOSE_ONLY";
   //---
   errors[40].code = 10045;
   errors[40].description = "이 종목에는 '포지션 청산만 허용' 규칙이 설정되어 있습니다";
   errors[40].constant = "TRADE_RETCODE_FIFO_CLOSE";
   //---
   errors[41].code = 10046;
   errors[41].description = "이 종목에는 '동일 종목에서 반대 포지션 오픈 금지' 규칙이 설정되어 있습니다";
   errors[41].constant = "TRADE_RETCODE_HEDGE_PROHIBITED";
   //+------------------------------------------------------------------+
   //| Errors sistem                                                    |
   //+------------------------------------------------------------------+
   errors[42].code = 4001;
   errors[42].description = "예상치 못한 내부 오류";
   errors[42].constant = "ERR_INTERNAL_ERROR";
   //---
   errors[43].code = 4002;
   errors[43].description = "클라이언트 터미널의 내부 함수 호출에서 잘못된 매개변수";
   errors[43].constant = "ERR_WRONG_INTERNAL_PARAMETER";
   //---
   errors[44].code = 4003;
   errors[44].description = "시스템 함수 호출에서 잘못된 매개변수";
   errors[44].constant = "ERR_INVALID_PARAMETER";
   //---
   errors[45].code = 4004;
   errors[45].description = "시스템 함수를 실행할 충분한 메모리가 없습니다";
   errors[45].constant = "ERR_NOT_ENOUGH_MEMORY";
   //---
   errors[46].code = 4005;
   errors[46].description = "구조체에 문자열 객체, 동적 배열 또는 해당 구조체/클래스가 포함되어 있습니다";
   errors[46].constant = "ERR_STRUCT_WITHOBJECTS_ORCLASS";
   //---
   errors[47].code = 4006;
   errors[47].description = "잘못된 유형 또는 크기의 배열, 또는 동적 배열의 결함 객체";
   errors[47].constant = "ERR_INVALID_ARRAY";
   //---
   errors[48].code = 4007;
   errors[48].description = "배열 재할당에 충분한 메모리가 없거나, 정적 배열 크기 변경 시도";
   errors[48].constant = "ERR_ARRAY_RESIZE_ERROR";
   //---
   errors[49].code = 4008;
   errors[49].description = "문자열 재할당에 충분한 메모리가 없습니다";
   errors[49].constant = "ERR_STRING_RESIZE_ERROR";
   //---
   errors[50].code = 4009;
   errors[50].description = "문자열이 초기화되지 않았습니다";
   errors[50].constant = "ERR_NOTINITIALIZED_STRING";
   //---
   errors[51].code = 4010;
   errors[51].description = "잘못된 날짜 또는 시간";
   errors[51].constant = "ERR_INVALID_DATETIME";
   //---
   errors[52].code = 4011;
   errors[52].description = "배열의 총 요소 수는 2147483647을 초과할 수 없습니다";
   errors[52].constant = "ERR_ARRAY_BAD_SIZE";
   //---
   errors[53].code = 4012;
   errors[53].description = "잘못된 포인터";
   errors[53].constant = "ERR_INVALID_POINTER";
   //---
   errors[54].code = 4013;
   errors[54].description = "잘못된 유형의 포인터";
   errors[54].constant = "ERR_INVALID_POINTER_TYPE";
   //---
   errors[55].code = 4014;
   errors[55].description = "시스템 함수 호출이 허용되지 않습니다";
   errors[55].constant = "ERR_FUNCTION_NOT_ALLOWED";
   //---
   errors[56].code = 4015;
   errors[56].description = "동적 리소스 이름과 정적 리소스 이름이 동일합니다";
   errors[56].constant = "ERR_RESOURCE_NAME_DUPLICATED";
   //---
   errors[57].code = 4016;
   errors[57].description = "이 이름의 리소스를 EX5에서 찾을 수 없습니다";
   errors[57].constant = "ERR_RESOURCE_NOT_FOUND";
   //---
   errors[58].code = 4017;
   errors[58].description = "지원되지 않는 리소스 유형이거나 크기가 16MB를 초과합니다";
   errors[58].constant = "ERR_RESOURCE_UNSUPPOTED_TYPE";
   //---
   errors[59].code = 4018;
   errors[59].description = "리소스 이름이 63자를 초과합니다";
   errors[59].constant = "ERR_RESOURCE_NAME_IS_TOO_LONG";
   //---
   errors[60].code = 4019;
   errors[60].description = "수학 함수 계산 중 오버플로우가 발생했습니다";
   errors[60].constant = "ERR_MATH_OVERFLOW";
   //---
   errors[61].code = 4020;
   errors[61].description = "Sleep() 호출 후 테스트 종료일을 초과했습니다";
   errors[61].constant = "ERR_SLEEP_ERROR";
   //---
   errors[62].code = 4022;
   errors[62].description = "테스트가 외부에서 강제로 중단되었습니다. 예: 최적화 중단, 시각적 테스트 창 닫기, 테스트 에이전트 중지 등";
   errors[62].constant = "ERR_STOPPED";
   //+------------------------------------------------------------------+
   //| Charts                                                           |
   //+------------------------------------------------------------------+
   errors[63].code = 4101;
   errors[63].description = "잘못된 차트 ID";
   errors[63].constant = "ERR_CHART_WRONG_ID";
   //---
   errors[64].code = 4102;
   errors[64].description = "차트가 응답하지 않습니다";
   errors[64].constant = "ERR_CHART_NO_REPLY";
   //---
   errors[65].code = 4103;
   errors[65].description = "차트를 찾을 수 없습니다";
   errors[65].constant = "ERR_CHART_NOT_FOUND";
   //---
   errors[66].code = 4104;
   errors[66].description = "이벤트를 처리할 수 있는 전문가 어드바이저가 차트에 없습니다";
   errors[66].constant = "ERR_CHART_NO_EXPERT";
   //---
   errors[67].code = 4105;
   errors[67].description = "차트 열기 오류";
   errors[67].constant = "ERR_CHART_CANNOT_OPEN";
   //---
   errors[68].code = 4106;
   errors[68].description = "차트의 종목 또는 기간 변경 실패";
   errors[68].constant = "ERR_CHART_CANNOT_CHANGE";
   //---
   errors[69].code = 4107;
   errors[69].description = "차트 작업 함수의 매개변수 오류";
   errors[69].constant = "ERR_CHART_WRONG_PARAMETER";
   //---
   errors[70].code = 4108;
   errors[70].description = "타이머 생성 실패";
   errors[70].constant = "ERR_CHART_CANNOT_CREATE_TIMER";
   //---
   errors[71].code = 4109;
   errors[71].description = "잘못된 차트 속성 ID";
   errors[71].constant = "ERR_CHART_WRONG_PROPERTY";
   //---
   errors[72].code = 4110;
   errors[72].description = "스크린샷 생성 오류";
   errors[72].constant = "ERR_CHART_SCREENSHOT_FAILED";
   //---
   errors[73].code = 4111;
   errors[73].description = "차트 탐색 오류";
   errors[73].constant = "ERR_CHART_NAVIGATE_FAILED";
   //---
   errors[74].code = 4112;
   errors[74].description = "템플릿 적용 오류";
   errors[74].constant = "ERR_CHART_TEMPLATE_FAILED";
   //---
   errors[75].code = 4113;
   errors[75].description = "지표가 포함된 하위 창을 찾을 수 없습니다";
   errors[75].constant = "ERR_CHART_WINDOW_NOT_FOUND";
   //---
   errors[76].code = 4114;
   errors[76].description = "차트에 지표 추가 오류";
   errors[76].constant = "ERR_CHART_INDICATOR_CANNOT_ADD";
   //---
   errors[77].code = 4115;
   errors[77].description = "차트에서 지표 삭제 오류";
   errors[77].constant = "ERR_CHART_INDICATOR_CANNOT_DEL";
   //---
   errors[78].code = 4116;
   errors[78].description = "지정된 차트에 지표를 찾을 수 없습니다";
   errors[78].constant = "ERR_CHART_INDICATOR_NOT_FOUND";
   //+------------------------------------------------------------------+
   //| Graphical Objects                                                |
   //+------------------------------------------------------------------+
   errors[79].code = 4201;
   errors[79].description = "그래픽 객체 작업 오류";
   errors[79].constant = "ERR_OBJECT_ERROR";
   //---
   errors[80].code = 4202;
   errors[80].description = "그래픽 객체를 찾을 수 없습니다";
   errors[80].constant = "ERR_OBJECT_NOT_FOUND";
   //---
   errors[81].code = 4203;
   errors[81].description = "잘못된 그래픽 객체 속성 ID";
   errors[81].constant = "ERR_OBJECT_WRONG_PROPERTY";
   //---
   errors[82].code = 4204;
   errors[82].description = "값에 해당하는 날짜를 가져올 수 없습니다";
   errors[82].constant = "ERR_OBJECT_GETDATE_FAILED";
   //---
   errors[83].code = 4205;
   errors[83].description = "날짜에 해당하는 값을 가져올 수 없습니다";
   errors[83].constant = "ERR_OBJECT_GETVALUE_FAILED";
   //+------------------------------------------------------------------+
   //| MarketInfo                                                       |
   //+------------------------------------------------------------------+
   errors[84].code = 4301;
   errors[84].description = "알 수 없는 종목";
   errors[84].constant = "ERR_MARKET_UNKNOWN_SYMBOL";
   //---
   errors[85].code = 4302;
   errors[85].description = "종목이 마켓 워치 창에서 선택되지 않았습니다";
   errors[85].constant = "ERR_MARKET_NOT_SELECTED";
   //---
   errors[86].code = 4303;
   errors[86].description = "잘못된 종목 속성 ID";
   errors[86].constant = "ERR_MARKET_WRONG_PROPERTY";
   //---
   errors[87].code = 4304;
   errors[87].description = "마지막 틱의 시간이 알 수 없습니다(틱 없음)";
   errors[87].constant = "ERR_MARKET_LASTTIME_UNKNOWN";
   //---
   errors[88].code = 4305;
   errors[88].description = "마켓 워치 창에서 종목 추가 또는 삭제 오류";
   errors[88].constant = "ERR_MARKET_SELECT_ERROR";
   //+------------------------------------------------------------------+
   //| History Access                                                   |
   //+------------------------------------------------------------------+
   errors[89].code = 4401;
   errors[89].description = "요청한 이력을 찾을 수 없습니다";
   errors[89].constant = "ERR_HISTORY_NOT_FOUND";
   //---
   errors[90].code = 4402;
   errors[90].description = "잘못된 이력 속성 ID";
   errors[90].constant = "ERR_HISTORY_WRONG_PROPERTY";
   //---
   errors[91].code = 4403;
   errors[91].description = "이력 요청 타임아웃";
   errors[91].constant = "ERR_HISTORY_TIMEOUT";
   //---
   errors[92].code = 4404;
   errors[92].description = "터미널 설정에 의한 바 제한";
   errors[92].constant = "ERR_HISTORY_BARS_LIMIT";
   //---
   errors[93].code = 4405;
   errors[93].description = "이력 로드 중 여러 오류가 발생했습니다";
   errors[93].constant = "ERR_HISTORY_LOAD_ERRORS";
   //---
   errors[94].code = 4407;
   errors[94].description = "수신 배열이 모든 데이터를 저장하기에 너무 작습니다";
   errors[94].constant = "ERR_HISTORY_SMALL_BUFFER";
   //+------------------------------------------------------------------+
   //| Global Variables                                                 |
   //+------------------------------------------------------------------+
   errors[95].code = 4501;
   errors[95].description = "클라이언트 터미널의 글로벌 변수를 찾을 수 없습니다";
   errors[95].constant = "ERR_GLOBALVARIABLE_NOT_FOUND";
   //---
   errors[96].code = 4502;
   errors[96].description = "동일한 이름의 글로벌 변수가 이미 존재합니다";
   errors[96].constant = "ERR_GLOBALVARIABLE_EXISTS";
   //---
   errors[97].code = 4503;
   errors[97].description = "글로벌 변수에 변경 사항이 없습니다";
   errors[97].constant = "ERR_GLOBALVARIABLE_NOT_MODIFIED";
   //---
   errors[98].code = 4504;
   errors[98].description = "글로벌 변수 값 파일을 열거나 읽을 수 없습니다";
   errors[98].constant = "ERR_GLOBALVARIABLE_CANNOTREAD";
   //---
   errors[99].code = 4505;
   errors[99].description = "글로벌 변수 값 파일을 쓸 수 없습니다";
   errors[99].constant = "ERR_GLOBALVARIABLE_CANNOTWRITE";
   //---
   errors[100].code = 4510;
   errors[100].description = "이메일 전송 실패";
   errors[100].constant = "ERR_MAIL_SEND_FAILED";
   //---
   errors[101].code = 4511;
   errors[101].description = "사운드 재생 실패";
   errors[101].constant = "ERR_PLAY_SOUND_FAILED";
   //---
   errors[102].code = 4512;
   errors[102].description = "잘못된 프로그램 속성 ID";
   errors[102].constant = "ERR_MQL5_WRONG_PROPERTY";
   //---
   errors[103].code = 4513;
   errors[103].description = "잘못된 터미널 속성 ID";
   errors[103].constant = "ERR_TERMINAL_WRONG_PROPERTY";
   //---
   errors[104].code = 4514;
   errors[104].description = "FTP 파일 전송 실패";
   errors[104].constant = "ERR_FTP_SEND_FAILED";
   //---
   errors[105].code = 4515;
   errors[105].description = "알림 전송 실패";
   errors[105].constant = "ERR_NOTIFICATION_SEND_FAILED";
   //---
   errors[106].code = 4516;
   errors[106].description = "알림 전송 매개변수가 잘못되었습니다(빈 문자열 또는 NULL이 SendNotification()에 전달됨)";
   errors[106].constant = "ERR_NOTIFICATION_WRONG_PARAMETER";
   //---
   errors[107].code = 4517;
   errors[107].description = "터미널의 알림 설정이 잘못되었습니다(ID가 지정되지 않았거나 권한이 설정되지 않음)";
   errors[107].constant = "ERR_NOTIFICATION_WRONG_SETTINGS";
   //---
   errors[108].code = 4518;
   errors[108].description = "알림 전송 빈도가 너무 높습니다";
   errors[108].constant = "ERR_NOTIFICATION_TOO_FREQUENT";
   //---
   errors[109].code = 4519;
   errors[109].description = "FTP 서버가 설정 속성에 지정되지 않았습니다";
   errors[109].constant = "ERR_FTP_NOSERVER";
   //---
   errors[110].code = 4520;
   errors[110].description = "FTP 로그인이 설정 속성에 지정되지 않았습니다";
   errors[110].constant = "ERR_FTP_NOLOGIN";
   //---
   errors[111].code = 4521;
   errors[111].description = "파일이 존재하지 않습니다";
   errors[111].constant = "ERR_FTP_FILE_ERROR";
   //---
   errors[112].code = 4522;
   errors[112].description = "FTP 서버 연결 실패";
   errors[112].constant = "ERR_FTP_CONNECT_FAILED";
   //---
   errors[113].code = 4523;
   errors[113].description = "FTP 서버의 파일 업로드 디렉터리를 찾을 수 없습니다";
   errors[113].constant = "ERR_FTP_CHANGEDIR";
   //---
   errors[114].code = 4524;
   errors[114].description = "FTP 서버 연결이 끊어졌습니다";
   errors[114].constant = "ERR_FTP_CLOSED";
   //+------------------------------------------------------------------+
   //| Custom Indicator Buffers                                         |
   //+------------------------------------------------------------------+
   errors[115].code = 4601;
   errors[115].description = "지표 버퍼 할당에 충분한 메모리가 없습니다";
   errors[115].constant = "ERR_BUFFERS_NO_MEMORY";
   //---
   errors[116].code = 4602;
   errors[116].description = "잘못된 지표 버퍼 인덱스";
   errors[116].constant = "ERR_BUFFERS_WRONG_INDEX";
   //+------------------------------------------------------------------+
   //| Custom Indicator Properties                                      |
   //+------------------------------------------------------------------+
   errors[117].code = 4603;
   errors[117].description = "잘못된 사용자 지정 지표 속성 ID";
   errors[117].constant = "ERR_CUSTOM_WRONG_PROPERTY";
   //+------------------------------------------------------------------+
   //| Account                                                          |
   //+------------------------------------------------------------------+
   errors[118].code = 4701;
   errors[118].description = "잘못된 계정 속성 ID";
   errors[118].constant = "ERR_ACCOUNT_WRONG_PROPERTY";
   //---
   errors[119].code = 4751;
   errors[119].description = "잘못된 거래 속성 ID";
   errors[119].constant = "ERR_TRADE_WRONG_PROPERTY";
   //---
   errors[120].code = 4752;
   errors[120].description = "전문가 어드바이저 거래가 금지되었습니다";
   errors[120].constant = "ERR_TRADE_DISABLED";
   //---
   errors[121].code = 4753;
   errors[121].description = "포지션을 찾을 수 없습니다";
   errors[121].constant = "ERR_TRADE_POSITION_NOT_FOUND";
   //---
   errors[122].code = 4754;
   errors[122].description = "주문을 찾을 수 없습니다";
   errors[122].constant = "ERR_TRADE_ORDER_NOT_FOUND";
   //---
   errors[123].code = 4755;
   errors[123].description = "거래(딜)를 찾을 수 없습니다";
   errors[123].constant = "ERR_TRADE_DEAL_NOT_FOUND";
   //---
   errors[124].code = 4756;
   errors[124].description = "거래 요청 전송 실패";
   errors[124].constant = "ERR_TRADE_SEND_FAILED";
   //---
   errors[125].code = 4758;
   errors[125].description = "거래 인덱스 값을 계산할 수 없습니다";
   errors[125].constant = "ERR_TRADE_CALC_FAILED";
   //+------------------------------------------------------------------+
   //| Indicators                                                       |
   //+------------------------------------------------------------------+
   errors[126].code = 4801;
   errors[126].description = "알 수 없는 종목";
   errors[126].constant = "ERR_INDICATOR_UNKNOWN_SYMBOL";
   //---
   errors[127].code = 4802;
   errors[127].description = "지표를 생성할 수 없습니다";
   errors[127].constant = "ERR_INDICATOR_CANNOT_CREATE";
   //---
   errors[128].code = 4803;
   errors[128].description = "지표 추가에 충분한 메모리가 없습니다";
   errors[128].constant = "ERR_INDICATOR_NO_MEMORY";
   //---
   errors[129].code = 4804;
   errors[129].description = "지표는 다른 지표에 적용할 수 없습니다";
   errors[129].constant = "ERR_INDICATOR_CANNOT_APPLY";
   //---
   errors[130].code = 4805;
   errors[130].description = "지표를 차트에 적용할 때 오류 발생";
   errors[130].constant = "ERR_INDICATOR_CANNOT_ADD";
   //---
   errors[131].code = 4806;
   errors[131].description = "요청한 데이터를 찾을 수 없습니다";
   errors[131].constant = "ERR_INDICATOR_DATA_NOT_FOUND";
   //---
   errors[132].code = 4807;
   errors[132].description = "잘못된 지표 핸들";
   errors[132].constant = "ERR_INDICATOR_WRONG_HANDLE";
   //---
   errors[133].code = 4808;
   errors[133].description = "지표 생성 시 매개변수 수가 잘못되었습니다";
   errors[133].constant = "ERR_INDICATOR_WRONG_PARAMETERS";
   //---
   errors[134].code = 4809;
   errors[134].description = "지표 생성 시 매개변수가 없습니다";
   errors[134].constant = "ERR_INDICATOR_PARAMETERS_MISSING";
   //---
   errors[135].code = 4810;
   errors[135].description = "배열의 첫 번째 매개변수는 사용자 지정 지표 이름이어야 합니다";
   errors[135].constant = "ERR_INDICATOR_CUSTOM_NAME";
   //---
   errors[136].code = 4811;
   errors[136].description = "지표 생성 시 배열 내 매개변수 유형이 잘못되었습니다";
   errors[136].constant = "ERR_INDICATOR_PARAMETER_TYPE";
   //---
   errors[137].code = 4812;
   errors[137].description = "요청한 지표 버퍼 인덱스가 잘못되었습니다";
   errors[137].constant = "ERR_INDICATOR_WRONG_INDEX";
   //+------------------------------------------------------------------+
   //| Depth of Market                                                  |
   //+------------------------------------------------------------------+
   errors[138].code = 4901;
   errors[138].description = "호가창(Depth of Market)을 추가할 수 없습니다";
   errors[138].constant = "ERR_BOOKS_CANNOT_ADD";
   //---
   errors[139].code = 4902;
   errors[139].description = "호가창(Depth of Market)을 삭제할 수 없습니다";
   errors[139].constant = "ERR_BOOKS_CANNOT_DELETE";
   //---
   errors[140].code = 4903;
   errors[140].description = "호가창(Depth of Market) 데이터를 가져올 수 없습니다";
   errors[140].constant = "ERR_BOOKS_CANNOT_GET";
   //---
   errors[141].code = 4904;
   errors[141].description = "호가창(Depth of Market) 새 데이터 구독 실패";
   errors[141].constant = "ERR_BOOKS_CANNOT_SUBSCRIBE";
   //+------------------------------------------------------------------+
   //| File Operations                                                  |
   //+------------------------------------------------------------------+
   errors[142].code = 5001;
   errors[142].description = "동시에 열 수 있는 파일은 최대 64개입니다";
   errors[142].constant = "ERR_TOO_MANY_FILES";
   //---
   errors[143].code = 5002;
   errors[143].description = "잘못된 파일 이름";
   errors[143].constant = "ERR_WRONG_FILENAME";
   //---
   errors[144].code = 5003;
   errors[144].description = "파일 이름이 너무 깁니다";
   errors[144].constant = "ERR_TOO_LONG_FILENAME";
   //---
   errors[145].code = 5004;
   errors[145].description = "파일 열기 오류";
   errors[145].constant = "ERR_CANNOT_OPEN_FILE";
   //---
   errors[146].code = 5005;
   errors[146].description = "읽기 캐시 메모리가 부족합니다";
   errors[146].constant = "ERR_FILE_CACHEBUFFER_ERROR";
   //---
   errors[147].code = 5006;
   errors[147].description = "파일 삭제 오류";
   errors[147].constant = "ERR_CANNOT_DELETE_FILE";
   //---
   errors[148].code = 5007;
   errors[148].description = "이 핸들의 파일은 이미 닫혔거나 열려 있지 않습니다";
   errors[148].constant = "ERR_INVALID_FILEHANDLE";
   //---
   errors[149].code = 5008;
   errors[149].description = "잘못된 파일 핸들";
   errors[149].constant = "ERR_WRONG_FILEHANDLE";
   //---
   errors[150].code = 5009;
   errors[150].description = "파일은 쓰기용으로 열려 있어야 합니다";
   errors[150].constant = "ERR_FILE_NOTTOWRITE";
   //---
   errors[151].code = 5010;
   errors[151].description = "파일은 읽기용으로 열려 있어야 합니다";
   errors[151].constant = "ERR_FILE_NOTTOREAD";
   //---
   errors[152].code = 5011;
   errors[152].description = "파일은 바이너리로 열려 있어야 합니다";
   errors[152].constant = "ERR_FILE_NOTBIN";
   //---
   errors[153].code = 5012;
   errors[153].description = "파일은 텍스트로 열려 있어야 합니다";
   errors[153].constant = "ERR_FILE_NOTTXT";
   //---
   errors[154].code = 5013;
   errors[154].description = "파일은 텍스트 또는 CSV로 열려 있어야 합니다";
   errors[154].constant = "ERR_FILE_NOTTXTORCSV";
   //---
   errors[155].code = 5014;
   errors[155].description = "파일은 CSV로 열려 있어야 합니다";
   errors[155].constant = "ERR_FILE_NOTCSV";
   //---
   errors[156].code = 5015;
   errors[156].description = "파일 읽기 오류";
   errors[156].constant = "ERR_FILE_READERROR";
   //---
   errors[157].code = 5016;
   errors[157].description = "파일이 바이너리로 열려 있으므로 문자열 크기를 지정해야 합니다";
   errors[157].constant = "ERR_FILE_BINSTRINGSIZE";
   //---
   errors[158].code = 5017;
   errors[158].description = "문자열 배열에는 텍스트 파일, 그 외 배열에는 바이너리 파일을 사용해야 합니다";
   errors[158].constant = "ERR_INCOMPATIBLE_FILE";
   //---
   errors[159].code = 5018;
   errors[159].description = "이것은 파일이 아니라 디렉터리입니다";
   errors[159].constant = "ERR_FILE_IS_DIRECTORY";
   //---
   errors[160].code = 5019;
   errors[160].description = "파일이 존재하지 않습니다";
   errors[160].constant = "ERR_FILE_NOT_EXIST";
   //---
   errors[161].code = 5020;
   errors[161].description = "파일을 덮어쓸 수 없습니다";
   errors[161].constant = "ERR_FILE_CANNOT_REWRITE";
   //---
   errors[162].code = 5021;
   errors[162].description = "잘못된 디렉터리 이름";
   errors[162].constant = "ERR_WRONG_DIRECTORYNAME";
   //---
   errors[163].code = 5022;
   errors[163].description = "디렉터리가 존재하지 않습니다";
   errors[163].constant = "ERR_DIRECTORY_NOT_EXIST";
   //---
   errors[164].code = 5023;
   errors[164].description = "이것은 디렉터리가 아니라 파일입니다";
   errors[164].constant = "ERR_FILE_ISNOT_DIRECTORY";
   //---
   errors[165].code = 5024;
   errors[165].description = "디렉터리를 삭제할 수 없습니다";
   errors[165].constant = "ERR_CANNOT_DELETE_DIRECTORY";
   //---
   errors[166].code = 5025;
   errors[166].description = "디렉터리 정리에 실패했습니다(하나 이상의 파일이 잠겨 있거나 삭제에 실패했을 수 있음)";
   errors[166].constant = "ERR_CANNOT_CLEAN_DIRECTORY";
   //---
   errors[167].code = 5026;
   errors[167].description = "리소스를 파일에 쓰는 데 실패했습니다";
   errors[167].constant = "ERR_FILE_WRITEERROR";
   //---
   errors[168].code = 5027;
   errors[168].description = "CSV 파일에서 다음 데이터 블록을 읽을 때 파일 끝에 도달했습니다";
   errors[168].constant = "ERR_FILE_ENDOFFILE";
   //+------------------------------------------------------------------+
   //| String Casting                                                   |
   //+------------------------------------------------------------------+
   errors[169].code = 5030;
   errors[169].description = "문자열에 날짜가 없습니다";
   errors[169].constant = "ERR_NO_STRING_DATE";
   //---
   errors[170].code = 5031;
   errors[170].description = "문자열의 날짜가 잘못되었습니다";
   errors[170].constant = "ERR_WRONG_STRING_DATE";
   //---
   errors[171].code = 5032;
   errors[171].description = "문자열의 시간이 잘못되었습니다";
   errors[171].constant = "ERR_WRONG_STRING_TIME";
   //---
   errors[172].code = 5033;
   errors[172].description = "문자열을 날짜로 변환하는 중 오류";
   errors[172].constant = "ERR_STRING_TIME_ERROR";
   //---
   errors[173].code = 5034;
   errors[173].description = "문자열 메모리가 부족합니다";
   errors[173].constant = "ERR_STRING_OUT_OF_MEMORY";
   //---
   errors[174].code = 5035;
   errors[174].description = "문자열 길이가 예상보다 짧습니다";
   errors[174].constant = "ERR_STRING_SMALL_LEN";
   //---
   errors[175].code = 5036;
   errors[175].description = "숫자가 너무 큽니다(ULONG_MAX 초과)";
   errors[175].constant = "ERR_STRING_TOO_BIGNUMBER";
   //---
   errors[176].code = 5037;
   errors[176].description = "잘못된 형식 문자열";
   errors[176].constant = "ERR_WRONG_FORMATSTRING";
   //---
   errors[177].code = 5038;
   errors[177].description = "형식 지정자 수가 매개변수보다 많습니다";
   errors[177].constant = "ERR_TOO_MANY_FORMATTERS";
   //---
   errors[178].code = 5039;
   errors[178].description = "매개변수 수가 형식 지정자보다 많습니다";
   errors[178].constant = "ERR_TOO_MANY_PARAMETERS";
   //---
   errors[179].code = 5040;
   errors[179].description = "잘못된 유형의 문자열 매개변수";
   errors[179].constant = "ERR_WRONG_STRING_PARAMETER";
   //---
   errors[180].code = 5041;
   errors[180].description = "문자열 범위를 벗어난 위치입니다";
   errors[180].constant = "ERR_STRINGPOS_OUTOFRANGE";
   //---
   errors[181].code = 5042;
   errors[181].description = "문자열 끝에 0이 추가되었습니다(의미 없는 작업)";
   errors[181].constant = "ERR_STRING_ZEROADDED";
   //---
   errors[182].code = 5043;
   errors[182].description = "데이터 유형을 알 수 없어 문자열로 변환할 수 없습니다";
   errors[182].constant = "ERR_STRING_UNKNOWNTYPE";
   //---
   errors[183].code = 5044;
   errors[183].description = "잘못된 문자열 객체";
   errors[183].constant = "ERR_WRONG_STRING_OBJECT";
   //+------------------------------------------------------------------+
   //| Operations with Arrays                                           |
   //+------------------------------------------------------------------+
   errors[184].code = 5050;
   errors[184].description = "호환되지 않는 배열 복사. 문자열 배열은 문자열 배열에만, 숫자 배열은 숫자 배열에만 복사할 수 있습니다";
   errors[184].constant = "ERR_INCOMPATIBLE_ARRAYS";
   //---
   errors[185].code = 5051;
   errors[185].description = "AS_SERIES로 선언된 수신 배열의 크기가 부족합니다";
   errors[185].constant = "ERR_SMALL_ASSERIES_ARRAY";
   //---
   errors[186].code = 5052;
   errors[186].description = "배열이 너무 작아 시작 위치가 범위를 벗어났습니다";
   errors[186].constant = "ERR_SMALL_ARRAY";
   //---
   errors[187].code = 5053;
   errors[187].description = "배열 길이가 0입니다";
   errors[187].constant = "ERR_ZEROSIZE_ARRAY";
   //---
   errors[188].code = 5054;
   errors[188].description = "숫자 배열이어야 합니다";
   errors[188].constant = "ERR_NUMBER_ARRAYS_ONLY";
   //---
   errors[189].code = 5055;
   errors[189].description = "1차원 배열이어야 합니다";
   errors[189].constant = "ERR_ONE_DIMENSIONAL_ARRAY";
   //---
   errors[190].code = 5056;
   errors[190].description = "타임시리즈 배열은 사용할 수 없습니다";
   errors[190].constant = "ERR_SERIES_ARRAY";
   //---
   errors[191].code = 5057;
   errors[191].description = "double형 배열이어야 합니다";
   errors[191].constant = "ERR_DOUBLE_ARRAY_ONLY";
   //---
   errors[192].code = 5058;
   errors[192].description = "float형 배열이어야 합니다";
   errors[192].constant = "ERR_FLOAT_ARRAY_ONLY";
   //---
   errors[193].code = 5059;
   errors[193].description = "long형 배열이어야 합니다";
   errors[193].constant = "ERR_LONG_ARRAY_ONLY";
   //---
   errors[194].code = 5060;
   errors[194].description = "int형 배열이어야 합니다";
   errors[194].constant = "ERR_INT_ARRAY_ONLY";
   //---
   errors[195].code = 5061;
   errors[195].description = "short형 배열이어야 합니다";
   errors[195].constant = "ERR_SHORT_ARRAY_ONLY";
   //---
   errors[196].code = 5062;
   errors[196].description = "char형 배열이어야 합니다";
   errors[196].constant = "ERR_CHAR_ARRAY_ONLY";
   //---
   errors[197].code = 5063;
   errors[197].description = "문자열 배열이어야 합니다";
   errors[197].constant = "ERR_STRING_ARRAY_ONLY";
   //+------------------------------------------------------------------+
   //| Operations with OpenCL                                           |
   //+------------------------------------------------------------------+
   errors[198].code = 5100;
   errors[198].description = "이 컴퓨터에서는 OpenCL 함수가 지원되지 않습니다";
   errors[198].constant = "ERR_OPENCL_NOT_SUPPORTED";
   //---
   errors[199].code = 5101;
   errors[199].description = "OpenCL 실행 중 내부 오류가 발생했습니다";
   errors[199].constant = "ERR_OPENCL_INTERNAL";
   //---
   errors[200].code = 5102;
   errors[200].description = "잘못된 OpenCL 핸들";
   errors[200].constant = "ERR_OPENCL_INVALID_HANDLE";
   //---
   errors[201].code = 5103;
   errors[201].description = "OpenCL 컨텍스트 생성 오류";
   errors[201].constant = "ERR_OPENCL_CONTEXT_CREATE";
   //---
   errors[202].code = 5104;
   errors[202].description = "OpenCL 명령 큐 생성 실패";
   errors[202].constant = "ERR_OPENCL_QUEUE_CREATE";
   //---
   errors[203].code = 5105;
   errors[203].description = "OpenCL 프로그램 컴파일 중 오류 발생";
   errors[203].constant = "ERR_OPENCL_PROGRAM_CREATE";
   //---
   errors[204].code = 5106;
   errors[204].description = "OpenCL 커널 이름이 너무 깁니다";
   errors[204].constant = "ERR_OPENCL_TOO_LONG_KERNEL_NAME";
   //---
   errors[205].code = 5107;
   errors[205].description = "OpenCL 커널 생성 오류";
   errors[205].constant = "ERR_OPENCL_KERNEL_CREATE";
   //---
   errors[206].code = 5108;
   errors[206].description = "OpenCL 커널 매개변수 설정 오류";
   errors[206].constant = "ERR_OPENCL_SET_KERNEL_PARAMETER";
   //---
   errors[207].code = 5109;
   errors[207].description = "OpenCL 프로그램 실행 시 오류";
   errors[207].constant = "ERR_OPENCL_EXECUTE";
   //---
   errors[209].code = 5110;
   errors[209].description = "잘못된 OpenCL 버퍼 크기";
   errors[209].constant = "ERR_OPENCL_WRONG_BUFFER_SIZE";
   //---
   errors[210].code = 5111;
   errors[210].description = "잘못된 OpenCL 버퍼 오프셋";
   errors[210].constant = "ERR_OPENCL_WRONG_BUFFER_OFFSET";
   //---
   errors[211].code = 5112;
   errors[211].description = "OpenCL 버퍼 생성 실패";
   errors[211].constant = "ERR_OPENCL_BUFFER_CREATE";
   //---
   errors[212].code = 5113;
   errors[212].description = "OpenCL 객체의 최대 수를 초과했습니다";
   errors[212].constant = "ERR_OPENCL_TOO_MANY_OBJECTS";
   //---
   errors[213].code = 5114;
   errors[213].description = "OpenCL 디바이스 선택 오류";
   errors[213].constant = "ERR_OPENCL_SELECTDEVICE";
   //+------------------------------------------------------------------+
   //| Working with databases                                           |
   //+------------------------------------------------------------------+
   errors[214].code = 5120;
   errors[214].description = "데이터베이스 내부 오류";
   errors[214].constant = "ERR_DATABASE_INTERNAL";
   //---
   errors[215].code = 5121;
   errors[215].description = "잘못된 데이터베이스 핸들";
   errors[215].constant = "ERR_DATABASE_INVALID_HANDLE";
   //---
   errors[216].code = 5122;
   errors[216].description = "데이터베이스 객체의 최대 수를 초과했습니다";
   errors[216].constant = "ERR_DATABASE_TOO_MANY_OBJECTS";
   //---
   errors[217].code = 5123;
   errors[217].description = "데이터베이스 연결 오류";
   errors[217].constant = "ERR_DATABASE_CONNECT";
   //---
   errors[218].code = 5124;
   errors[218].description = "쿼리 실행 오류";
   errors[218].constant = "ERR_DATABASE_EXECUTE";
   //---
   errors[219].code = 5125;
   errors[219].description = "쿼리 생성 오류";
   errors[219].constant = "ERR_DATABASE_PREPARE";
   //---
   errors[220].code = 5126;
   errors[220].description = "더 이상 읽을 데이터가 없습니다";
   errors[220].constant = "ERR_DATABASE_NO_MORE_DATA";
   //---
   errors[221].code = 5127;
   errors[221].description = "쿼리 결과의 다음 레코드로 이동 오류";
   errors[221].constant = "ERR_DATABASE_STEP";
   //---
   errors[222].code = 5128;
   errors[222].description = "쿼리 결과 데이터가 아직 준비되지 않았습니다";
   errors[222].constant = "ERR_DATABASE_NOT_READY";
   //---
   errors[223].code = 5129;
   errors[223].description = "SQL 쿼리의 매개변수 자동 대체 오류";
   errors[223].constant = "ERR_DATABASE_BIND_PARAMETERS";
   //+------------------------------------------------------------------+
   //| Operations with WebRequest                                       |
   //+------------------------------------------------------------------+
   errors[224].code = 5200;
   errors[224].description = "잘못된 URL";
   errors[224].constant = "ERR_WEBREQUEST_INVALID_ADDRESS";
   //---
   errors[225].code = 5201;
   errors[225].description = "지정된 URL에 연결 실패";
   errors[225].constant = "ERR_WEBREQUEST_CONNECT_FAILED";
   //---
   errors[226].code = 5202;
   errors[226].description = "타임아웃";
   errors[226].constant = "ERR_WEBREQUEST_TIMEOUT";
   //---
   errors[227].code = 5203;
   errors[227].description = "HTTP 요청 실패";
   errors[227].constant = "ERR_WEBREQUEST_REQUEST_FAILED";
   //+------------------------------------------------------------------+
   //| Operations with network (sockets)                                |
   //+------------------------------------------------------------------+
   errors[228].code = 5270;
   errors[228].description = "함수에 잘못된 소켓 핸들이 전달되었습니다";
   errors[228].constant = "ERR_NETSOCKET_INVALIDHANDLE";
   //---
   errors[229].code = 5271;
   errors[229].description = "열린 소켓이 너무 많습니다(최대 128개)";
   errors[229].constant = "ERR_NETSOCKET_TOO_MANY_OPENED";
   //---
   errors[230].code = 5272;
   errors[230].description = "원격 호스트 연결 오류";
   errors[230].constant = "ERR_NETSOCKET_CANNOT_CONNECT";
   //---
   errors[231].code = 5273;
   errors[231].description = "소켓 송수신 오류";
   errors[231].constant = "ERR_NETSOCKET_IO_ERROR";
   //---
   errors[232].code = 5274;
   errors[232].description = "보안 연결(TLS 핸드셰이크) 설정 오류";
   errors[232].constant = "ERR_NETSOCKET_HANDSHAKE_FAILED";
   //---
   errors[233].code = 5275;
   errors[233].description = "연결을 보호하는 인증서 데이터가 없습니다";
   errors[233].constant = "ERR_NETSOCKET_NO_CERTIFICATE";
   //+------------------------------------------------------------------+
   //| Custom Symbols                                                   |
   //+------------------------------------------------------------------+
   errors[234].code = 5300;
   errors[234].description = "사용자 지정 심볼을 지정해야 합니다";
   errors[234].constant = "ERR_NOT_CUSTOM_SYMBOL";
   //---
   errors[235].code = 5301;
   errors[235].description = "잘못된 사용자 지정 심볼 이름입니다. 심볼 이름에는 라틴 문자만 사용할 수 있으며, 구두점, 공백, 특수 문자는 사용할 수 없습니다('.','_','&','#'는 허용). <, >, :, ', /, |, ?, *는 권장되지 않습니다.";
   errors[235].constant = "ERR_CUSTOM_SYMBOL_WRONG_NAME";
   //---
   errors[236].code = 5302;
   errors[236].description = "사용자 지정 심볼 이름이 너무 깁니다(32자 이내)";
   errors[236].constant = "ERR_CUSTOM_SYMBOL_NAME_LONG";
   //---
   errors[237].code = 5303;
   errors[237].description = "사용자 지정 심볼 경로가 너무 깁니다(128자 이내)";
   errors[237].constant = "ERR_CUSTOM_SYMBOL_PATH_LONG";
   //---
   errors[238].code = 5304;
   errors[238].description = "이 이름의 사용자 지정 심볼이 이미 존재합니다";
   errors[238].constant = "ERR_CUSTOM_SYMBOL_EXIST";
   //---
   errors[239].code = 5305;
   errors[239].description = "사용자 지정 심볼 생성, 삭제, 변경 오류";
   errors[239].constant = "ERR_CUSTOM_SYMBOL_ERROR";
   //---
   errors[240].code = 5306;
   errors[240].description = "마켓 워치에서 선택된 사용자 지정 심볼을 삭제하려고 시도했습니다";
   errors[240].constant = "ERR_CUSTOM_SYMBOL_SELECTED";
   //---
   errors[241].code = 5307;
   errors[241].description = "잘못된 사용자 지정 심볼 속성";
   errors[241].constant = "ERR_CUSTOM_SYMBOL_PROPERTY_WRONG";
   //---
   errors[242].code = 5308;
   errors[242].description = "사용자 지정 심볼 속성 설정 시 매개변수 오류";
   errors[242].constant = "ERR_CUSTOM_SYMBOL_PARAMETER_ERROR";
   //---
   errors[243].code = 5309;
   errors[243].description = "사용자 지정 심볼 속성 설정 시 문자열 매개변수가 너무 깁니다";
   errors[243].constant = "ERR_CUSTOM_SYMBOL_PARAMETER_LONG";
   //---
   errors[244].code = 5310;
   errors[244].description = "틱 배열이 시간 순서대로 정렬되어 있지 않습니다";
   errors[244].constant = "ERR_CUSTOM_TICKS_WRONG_ORDER";
   //+------------------------------------------------------------------+
   //| Economic Calendar                                                |
   //+------------------------------------------------------------------+
   errors[245].code = 5400;
   errors[245].description = "모든 값의 설명을 얻으려면 배열 크기가 부족합니다";
   errors[245].constant = "ERR_CALENDAR_MORE_DATA";
   //---
   errors[246].code = 5401;
   errors[246].description = "요청 타임아웃";
   errors[246].constant = "ERR_CALENDAR_TIMEOUT";
   //---
   errors[247].code = 5402;
   errors[247].description = "국가를 찾을 수 없습니다";
   errors[247].constant = "ERR_CALENDAR_NO_DATA";
   //+------------------------------------------------------------------+
   //| Working with databases                                           |
   //+------------------------------------------------------------------+
   errors[248].code = 5601;
   errors[248].description = "일반 오류";
   errors[248].constant = "ERR_DATABASE_ERROR";
   //---
   errors[249].code = 5602;
   errors[249].description = "SQLite 내부 논리 오류";
   errors[249].constant = "ERR_DATABASE_INTERNAL";
   //---
   errors[250].code = 5603;
   errors[250].description = "액세스가 거부되었습니다";
   errors[250].constant = "ERR_DATABASE_PERM";
   //---
   errors[251].code = 5604;
   errors[251].description = "콜백 루틴이 중단을 요청했습니다";
   errors[251].constant = "ERR_DATABASE_ABORT";
   //---
   errors[252].code = 5605;
   errors[252].description = "데이터베이스 파일이 잠겨 있습니다";
   errors[252].constant = "ERR_DATABASE_BUSY";
   //---
   errors[253].code = 5606;
   errors[253].description = "데이터베이스 테이블이 잠겨 있습니다";
   errors[253].constant = "ERR_DATABASE_LOCKED";
   //---
   errors[254].code = 5607;
   errors[254].description = "작업을 완료할 메모리가 부족합니다";
   errors[254].constant = "ERR_DATABASE_NOMEM";
   //---
   errors[255].code = 5608;
   errors[255].description = "읽기 전용 데이터베이스에 쓰기를 시도했습니다";
   errors[255].constant = "ERR_DATABASE_READONLY";
   //---
   errors[256].code = 5609;
   errors[256].description = "sqlite3_interrupt()로 작업이 종료되었습니다";
   errors[256].constant = "ERR_DATABASE_INTERRUPT";
   //---
   errors[257].code = 5610;
   errors[257].description = "디스크 I/O 오류";
   errors[257].constant = "ERR_DATABASE_IOERR";
   //---
   errors[258].code = 5611;
   errors[258].description = "데이터베이스 디스크 이미지가 손상되었습니다";
   errors[258].constant = "ERR_DATABASE_CORRUPT";
   //---
   errors[259].code = 5612;
   errors[259].description = "sqlite3_file_control()에서 알 수 없는 작업 코드";
   errors[259].constant = "ERR_DATABASE_NOTFOUND";
   //---
   errors[260].code = 5613;
   errors[260].description = "데이터베이스가 가득 차서 삽입에 실패했습니다";
   errors[260].constant = "ERR_DATABASE_FULL";
   //---
   errors[261].code = 5614;
   errors[261].description = "데이터베이스 파일을 열 수 없습니다";
   errors[261].constant = "ERR_DATABASE_CANTOPEN";
   //---
   errors[262].code = 5615;
   errors[262].description = "데이터베이스 잠금 프로토콜 오류";
   errors[262].constant = "ERR_DATABASE_PROTOCOL";
   //---
   errors[263].code = 5616;
   errors[263].description = "내부 사용 전용";
   errors[263].constant = "ERR_DATABASE_EMPTY";
   //---
   errors[264].code = 5617;
   errors[264].description = "데이터베이스 스키마가 변경되었습니다";
   errors[264].constant = "ERR_DATABASE_SCHEMA";
   //---
   errors[265].code = 5618;
   errors[265].description = "문자열 또는 BLOB이 크기 제한을 초과합니다";
   errors[265].constant = "ERR_DATABASE_TOOBIG";
   //---
   errors[266].code = 5619;
   errors[266].description = "제약 조건 위반으로 인한 중단";
   errors[266].constant = "ERR_DATABASE_CONSTRAINT";
   //---
   errors[267].code = 5620;
   errors[267].description = "데이터 유형 불일치";
   errors[267].constant = "ERR_DATABASE_MISMATCH";
   //---
   errors[268].code = 5621;
   errors[268].description = "라이브러리 오용";
   errors[268].constant = "ERR_DATABASE_MISUSE";
   //---
   errors[269].code = 5622;
   errors[269].description = "호스트에서 지원되지 않는 OS 리소스를 사용합니다";
   errors[269].constant = "ERR_DATABASE_NOLFS";
   //---
   errors[270].code = 5623;
   errors[270].description = "인증이 거부되었습니다";
   errors[270].constant = "ERR_DATABASE_AUTH";
   //---
   errors[271].code = 5624;
   errors[271].description = "사용되지 않음";
   errors[271].constant = "ERR_DATABASE_FORMAT";
   //---
   errors[272].code = 5625;
   errors[272].description = "바인드 매개변수 오류, 잘못된 인덱스";
   errors[272].constant = "ERR_DATABASE_RANGE";
   //---
   errors[273].code = 5626;
   errors[273].description = "열려 있는 파일이 데이터베이스 파일이 아닙니다";
   errors[273].constant = "ERR_DATABASE_NOTADB";
  }
//+------------------------------------------------------------------+


