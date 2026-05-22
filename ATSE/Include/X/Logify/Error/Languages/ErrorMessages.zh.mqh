//+------------------------------------------------------------------+
//|                                             ErrorMessages.zh.mqh |
//|                                                     joaopedrodev |
//|                       https://www.mql5.com/en/users/joaopedrodev |
//+------------------------------------------------------------------+
#property copyright "joaopedrodev"
#property link      "https://www.mql5.com/en/users/joaopedrodev"
//+------------------------------------------------------------------+
//| Import struct                                                    
//+------------------------------------------------------------------+
#include "../Error.mqh"
void InitializeErrorsChinese(MqlError &errors[])
  {
   //--- Free and resize
   ArrayFree(errors);
   ArrayResize(errors,274);
   
   //+------------------------------------------------------------------+
   //| Unknown error                                                    |
   //+------------------------------------------------------------------+
   errors[0].code = 0;
   errors[0].description = "未发现错误";
   errors[0].constant = "ERROR_UNKNOWN";
   //+------------------------------------------------------------------+
   //| Server error                                                     |
   //+------------------------------------------------------------------+
   errors[1].code = 10004;
   errors[1].description = "新报价";
   errors[1].constant = "TRADE_RETCODE_REQUOTE";
   //---
   errors[2].code = 10006;
   errors[2].description = "请求被拒绝";
   errors[2].constant = "TRADE_RETCODE_REJECT";
   //---
   errors[3].code = 10007;
   errors[3].description = "请求被交易员取消";
   errors[3].constant = "TRADE_RETCODE_CANCEL";
   //---
   errors[4].code = 10008;
   errors[4].description = "订单已下达";
   errors[4].constant = "TRADE_RETCODE_PLACED";
   //---
   errors[5].code = 10009;
   errors[5].description = "请求已完成";
   errors[5].constant = "TRADE_RETCODE_DONE";
   //---
   errors[6].code = 10010;
   errors[6].description = "仅部分请求已完成";
   errors[6].constant = "TRADE_RETCODE_DONE_PARTIAL";
   //---
   errors[7].code = 10011;
   errors[7].description = "请求处理错误";
   errors[7].constant = "TRADE_RETCODE_ERROR";
   //---
   errors[8].code = 10012;
   errors[8].description = "请求因超时被取消";
   errors[8].constant = "TRADE_RETCODE_TIMEOUT";
   //---
   errors[9].code = 10013;
   errors[9].description = "无效请求";
   errors[9].constant = "TRADE_RETCODE_INVALID";
   //---
   errors[10].code = 10014;

   errors[10].description = "请求中无效的交易量";
   errors[10].constant = "TRADE_RETCODE_INVALID_VOLUME";
   //---
   errors[11].code = 10015;

   errors[11].description = "请求中无效的价格";
   errors[11].constant = "TRADE_RETCODE_INVALID_PRICE";
   //---
   errors[12].code = 10016;

   errors[12].description = "请求中无效的止损";
   errors[12].constant = "TRADE_RETCODE_INVALID_STOPS";
   //---
   errors[13].code = 10017;

   errors[13].description = "交易已禁用";
   errors[13].constant = "TRADE_RETCODE_TRADE_DISABLED";
   //---
   errors[14].code = 10018;

   errors[14].description = "市场已关闭";
   errors[14].constant = "TRADE_RETCODE_MARKET_CLOSED";
   //---
   errors[15].code = 10019;

   errors[15].description = "余额不足，无法完成请求";
   errors[15].constant = "TRADE_RETCODE_NO_MONEY";
   //---
   errors[16].code = 10020;

   errors[16].description = "价格已变动";
   errors[16].constant = "TRADE_RETCODE_PRICE_CHANGED";
   //---
   errors[17].code = 10021;

   errors[17].description = "无报价可处理请求";
   errors[17].constant = "TRADE_RETCODE_PRICE_OFF";
   //---
   errors[18].code = 10022;

   errors[18].description = "请求中无效的订单到期日";
   errors[18].constant = "TRADE_RETCODE_INVALID_EXPIRATION";
   //---
   errors[19].code = 10023;

   errors[19].description = "订单状态已更改";
   errors[19].constant = "TRADE_RETCODE_ORDER_CHANGED";
   //---
   errors[20].code = 10024;

   errors[20].description = "请求过多";
   errors[20].constant = "TRADE_RETCODE_TOO_MANY_REQUESTS";
   //---
   errors[21].code = 10025;

   errors[21].description = "请求中无更改";
   errors[21].constant = "TRADE_RETCODE_NO_CHANGES";
   //---
   errors[22].code = 10026;

   errors[22].description = "自动交易被服务器禁用";
   errors[22].constant = "TRADE_RETCODE_SERVER_DISABLES_AT";
   //---
   errors[23].code = 10027;

   errors[23].description = "自动交易被客户端终端禁用";
   errors[23].constant = "TRADE_RETCODE_CLIENT_DISABLES_AT";
   //---
   errors[24].code = 10028;

   errors[24].description = "请求被锁定以处理";
   errors[24].constant = "TRADE_RETCODE_LOCKED";
   //---
   errors[25].code = 10029;

   errors[25].description = "订单或持仓被冻结";
   errors[25].constant = "TRADE_RETCODE_FROZEN";
   //---
   errors[26].code = 10030;

   errors[26].description = "无效的订单成交类型";
   errors[26].constant = "TRADE_RETCODE_INVALID_FILL";
   //---
   errors[27].code = 10031;

   errors[27].description = "与交易服务器无连接";
   errors[27].constant = "TRADE_RETCODE_CONNECTION";
   //---
   errors[28].code = 10032;

   errors[28].description = "仅允许真实账户操作";
   errors[28].constant = "TRADE_RETCODE_ONLY_REAL";
   //---
   errors[29].code = 10033;

   errors[29].description = "挂单数量已达上限";
   errors[29].constant = "TRADE_RETCODE_LIMIT_ORDERS";
   //---
   errors[30].code = 10034;

   errors[30].description = "该品种的订单和持仓量已达上限";
   errors[30].constant = "TRADE_RETCODE_LIMIT_VOLUME";
   //---
   errors[31].code = 10035;

   errors[31].description = "错误或禁止的订单类型";
   errors[31].constant = "TRADE_RETCODE_INVALID_ORDER";
   //---
   errors[32].code = 10036;

   errors[32].description = "指定的持仓标识已被关闭";
   errors[32].constant = "TRADE_RETCODE_POSITION_CLOSED";
   //---
   errors[33].code = 10038;

   errors[33].description = "平仓量超过当前持仓量";
   errors[33].constant = "TRADE_RETCODE_INVALID_CLOSE_VOLUME";
   //---
   errors[34].code = 10039;

   errors[34].description = "参见文档";
   errors[34].constant = "TRADE_RETCODE_CLOSE_ORDER_EXIST";
   //---
   errors[35].code = 10040;

   errors[35].description = "参见文档";
   errors[35].constant = "TRADE_RETCODE_LIMIT_POSITIONS";
   //---
   errors[36].code = 10041;

   errors[36].description = "挂单激活请求被拒绝，订单已取消";
   errors[36].constant = "TRADE_RETCODE_REJECT_CANCEL";
   //---
   errors[37].code = 10042;

   errors[37].description = "订单被拒绝，因为该品种设置为仅允许多头持仓（POSITION_TYPE_BUY）";
   errors[37].constant = "TRADE_RETCODE_LONG_ONLY";
   //---
   errors[38].code = 10043;

   errors[38].description = "订单被拒绝，因为该品种设置为仅允许空头持仓（POSITION_TYPE_SELL）";
   errors[38].constant = "TRADE_RETCODE_SHORT_ONLY";
   //---
   errors[39].code = 10044;

   errors[39].description = "订单被拒绝，因为该品种设置为仅允许平仓";
   errors[39].constant = "TRADE_RETCODE_CLOSE_ONLY";
   //---
   errors[40].code = 10045;

   errors[40].description = "订单被拒绝，因为该品种设置为仅允许平仓";
   errors[40].constant = "TRADE_RETCODE_FIFO_CLOSE";
   //---
   errors[41].code = 10046;

   errors[41].description = "订单被拒绝，因为该品种禁止对冲同一品种的反向持仓";
   errors[41].constant = "TRADE_RETCODE_HEDGE_PROHIBITED";
   //+------------------------------------------------------------------+
   //| Errors sistem                                                    |
   //+------------------------------------------------------------------+
   errors[42].code = 4001;
   errors[42].description = "意外的内部错误";
   errors[42].constant = "ERR_INTERNAL_ERROR";
   //---
   errors[43].code = 4002;
   errors[43].description = "客户端终端函数内部调用参数错误";
   errors[43].constant = "ERR_WRONG_INTERNAL_PARAMETER";
   //---
   errors[44].code = 4003;
   errors[44].description = "调用系统函数时参数错误";
   errors[44].constant = "ERR_INVALID_PARAMETER";
   //---
   errors[45].code = 4004;
   errors[45].description = "内存不足，无法执行系统函数";
   errors[45].constant = "ERR_NOT_ENOUGH_MEMORY";
   //---
   errors[46].code = 4005;
   errors[46].description = "结构体包含字符串对象和/或动态数组和/或此类对象的结构体和/或类";
   errors[46].constant = "ERR_STRUCT_WITHOBJECTS_ORCLASS";
   //---
   errors[47].code = 4006;
   errors[47].description = "错误类型、错误大小的数组或动态数组的损坏对象";
   errors[47].constant = "ERR_INVALID_ARRAY";
   //---
   errors[48].code = 4007;
   errors[48].description = "内存不足，无法重新分配数组，或尝试更改静态数组的大小";
   errors[48].constant = "ERR_ARRAY_RESIZE_ERROR";
   //---
   errors[49].code = 4008;
   errors[49].description = "内存不足，无法重新分配字符串";
   errors[49].constant = "ERR_STRING_RESIZE_ERROR";
   //---
   errors[50].code = 4009;
   errors[50].description = "未初始化的字符串";
   errors[50].constant = "ERR_NOTINITIALIZED_STRING";
   //---
   errors[51].code = 4010;
   errors[51].description = "无效的日期和/或时间";
   errors[51].constant = "ERR_INVALID_DATETIME";
   //---
   errors[52].code = 4011;
   errors[52].description = "数组中的元素总数不能超过2147483647";
   errors[52].constant = "ERR_ARRAY_BAD_SIZE";
   //---
   errors[53].code = 4012;
   errors[53].description = "错误的指针";
   errors[53].constant = "ERR_INVALID_POINTER";
   //---
   errors[54].code = 4013;
   errors[54].description = "错误的指针类型";
   errors[54].constant = "ERR_INVALID_POINTER_TYPE";
   //---
   errors[55].code = 4014;
   errors[55].description = "不允许调用系统函数";
   errors[55].constant = "ERR_FUNCTION_NOT_ALLOWED";
   //---
   errors[56].code = 4015;
   errors[56].description = "动态和静态资源的名称相同";
   errors[56].constant = "ERR_RESOURCE_NAME_DUPLICATED";
   //---
   errors[57].code = 4016;
   errors[57].description = "在EX5中未找到该名称的资源";
   errors[57].constant = "ERR_RESOURCE_NOT_FOUND";
   //---
   errors[58].code = 4017;
   errors[58].description = "不支持的资源类型或其大小超过16Mb";
   errors[58].constant = "ERR_RESOURCE_UNSUPPOTED_TYPE";
   //---
   errors[59].code = 4018;
   errors[59].description = "资源名称超过63个字符";
   errors[59].constant = "ERR_RESOURCE_NAME_IS_TOO_LONG";
   //---
   errors[60].code = 4019;
   errors[60].description = "计算数学函数时发生溢出";
   errors[60].constant = "ERR_MATH_OVERFLOW";
   //---
   errors[61].code = 4020;
   errors[61].description = "调用Sleep()后测试结束超时";
   errors[61].constant = "ERR_SLEEP_ERROR";
   //---
   errors[62].code = 4022;
   errors[62].description = "测试被外部强制中断。例如，停止优化、关闭可视化测试窗口或停止测试代理时";
   errors[62].constant = "ERR_STOPPED";
   //+------------------------------------------------------------------+
   //| Charts                                                           |
   //+------------------------------------------------------------------+
   errors[63].code = 4101;
   errors[63].description = "错误的图表ID";
   errors[63].constant = "ERR_CHART_WRONG_ID";
   //---
   errors[64].code = 4102;
   errors[64].description = "图表无响应";
   errors[64].constant = "ERR_CHART_NO_REPLY";
   //---
   errors[65].code = 4103;
   errors[65].description = "未找到图表";
   errors[65].constant = "ERR_CHART_NOT_FOUND";
   //---
   errors[66].code = 4104;
   errors[66].description = "图表上没有专家顾问处理事件";
   errors[66].constant = "ERR_CHART_NO_EXPERT";
   //---
   errors[67].code = 4105;
   errors[67].description = "图表打开错误";
   errors[67].constant = "ERR_CHART_CANNOT_OPEN";
   //---
   errors[68].code = 4106;
   errors[68].description = "无法更改图表的品种和周期";
   errors[68].constant = "ERR_CHART_CANNOT_CHANGE";
   //---
   errors[69].code = 4107;
   errors[69].description = "用于图表操作函数的参数值错误";
   errors[69].constant = "ERR_CHART_WRONG_PARAMETER";
   //---
   errors[70].code = 4108;
   errors[70].description = "无法创建定时器";
   errors[70].constant = "ERR_CHART_CANNOT_CREATE_TIMER";
   //---
   errors[71].code = 4109;
   errors[71].description = "错误的图表属性ID";
   errors[71].constant = "ERR_CHART_WRONG_PROPERTY";
   //---
   errors[72].code = 4110;
   errors[72].description = "创建截图时出错";
   errors[72].constant = "ERR_CHART_SCREENSHOT_FAILED";
   //---
   errors[73].code = 4111;
   errors[73].description = "图表导航出错";
   errors[73].constant = "ERR_CHART_NAVIGATE_FAILED";
   //---
   errors[74].code = 4112;
   errors[74].description = "应用模板时出错";
   errors[74].constant = "ERR_CHART_TEMPLATE_FAILED";
   //---
   errors[75].code = 4113;
   errors[75].description = "未找到包含指标的子窗口";
   errors[75].constant = "ERR_CHART_WINDOW_NOT_FOUND";
   //---
   errors[76].code = 4114;
   errors[76].description = "无法将指标添加到图表";
   errors[76].constant = "ERR_CHART_INDICATOR_CANNOT_ADD";
   //---
   errors[77].code = 4115;
   errors[77].description = "无法从图表中删除指标";
   errors[77].constant = "ERR_CHART_INDICATOR_CANNOT_DEL";
   //---
   errors[78].code = 4116;
   errors[78].description = "在指定图表中未找到指标";
   errors[78].constant = "ERR_CHART_INDICATOR_NOT_FOUND";
   //+------------------------------------------------------------------+
   //| Graphical Objects                                                |
   //+------------------------------------------------------------------+
   errors[79].code = 4201;
   errors[79].description = "处理图形对象时出错";
   errors[79].constant = "ERR_OBJECT_ERROR";
   //---
   errors[80].code = 4202;
   errors[80].description = "未找到图形对象";
   errors[80].constant = "ERR_OBJECT_NOT_FOUND";
   //---
   errors[81].code = 4203;
   errors[81].description = "图形对象的属性ID错误";
   errors[81].constant = "ERR_OBJECT_WRONG_PROPERTY";
   //---
   errors[82].code = 4204;
   errors[82].description = "无法获取与值对应的日期";
   errors[82].constant = "ERR_OBJECT_GETDATE_FAILED";
   //---
   errors[83].code = 4205;
   errors[83].description = "无法获取与日期对应的值";
   errors[83].constant = "ERR_OBJECT_GETVALUE_FAILED";
   //+------------------------------------------------------------------+
   //| MarketInfo                                                       |
   //+------------------------------------------------------------------+
   errors[84].code = 4301;
   errors[84].description = "未知品种";
   errors[84].constant = "ERR_MARKET_UNKNOWN_SYMBOL";
   //---
   errors[85].code = 4302;
   errors[85].description = "品种未在市场观察窗口中选中";
   errors[85].constant = "ERR_MARKET_NOT_SELECTED";
   //---
   errors[86].code = 4303;
   errors[86].description = "品种的属性ID错误";
   errors[86].constant = "ERR_MARKET_WRONG_PROPERTY";
   //---
   errors[87].code = 4304;
   errors[87].description = "最后一个报价的时间未知（无报价）";
   errors[87].constant = "ERR_MARKET_LASTTIME_UNKNOWN";
   //---
   errors[88].code = 4305;
   errors[88].description = "在市场观察窗口中添加或删除品种时出错";
   errors[88].constant = "ERR_MARKET_SELECT_ERROR";
   //+------------------------------------------------------------------+
   //| History Access                                                   |
   //+------------------------------------------------------------------+
   errors[89].code = 4401;
   errors[89].description = "未找到请求的历史记录";
   errors[89].constant = "ERR_HISTORY_NOT_FOUND";
   //---
   errors[90].code = 4402;
   errors[90].description = "历史记录的属性ID错误";
   errors[90].constant = "ERR_HISTORY_WRONG_PROPERTY";
   //---
   errors[91].code = 4403;
   errors[91].description = "历史请求超时";
   errors[91].constant = "ERR_HISTORY_TIMEOUT";
   //---
   errors[92].code = 4404;
   errors[92].description = "K线数量受终端设置限制";
   errors[92].constant = "ERR_HISTORY_BARS_LIMIT";
   //---
   errors[93].code = 4405;
   errors[93].description = "加载历史记录时发生多个错误";
   errors[93].constant = "ERR_HISTORY_LOAD_ERRORS";
   //---
   errors[94].code = 4407;
   errors[94].description = "接收数组太小，无法存储所有请求的数据";
   errors[94].constant = "ERR_HISTORY_SMALL_BUFFER";
   //+------------------------------------------------------------------+
   //| Global Variables                                                 |
   //+------------------------------------------------------------------+
   errors[95].code = 4501;
   errors[95].description = "未找到客户端终端的全局变量";
   errors[95].constant = "ERR_GLOBALVARIABLE_NOT_FOUND";
   //---
   errors[96].code = 4502;
   errors[96].description = "具有相同名称的客户端终端全局变量已存在";
   errors[96].constant = "ERR_GLOBALVARIABLE_EXISTS";
   //---
   errors[97].code = 4503;
   errors[97].description = "全局变量无更改";
   errors[97].constant = "ERR_GLOBALVARIABLE_NOT_MODIFIED";
   //---
   errors[98].code = 4504;
   errors[98].description = "无法打开和读取包含全局变量值的文件";
   errors[98].constant = "ERR_GLOBALVARIABLE_CANNOTREAD";
   //---
   errors[99].code = 4505;
   errors[99].description = "无法写入包含全局变量值的文件";
   errors[99].constant = "ERR_GLOBALVARIABLE_CANNOTWRITE";
   //---
   errors[100].code = 4510;
   errors[100].description = "邮件发送失败";
   errors[100].constant = "ERR_MAIL_SEND_FAILED";
   //---
   errors[101].code = 4511;
   errors[101].description = "声音播放失败";
   errors[101].constant = "ERR_PLAY_SOUND_FAILED";
   //---
   errors[102].code = 4512;
   errors[102].description = "程序属性ID错误";
   errors[102].constant = "ERR_MQL5_WRONG_PROPERTY";
   //---
   errors[103].code = 4513;
   errors[103].description = "终端属性ID错误";
   errors[103].constant = "ERR_TERMINAL_WRONG_PROPERTY";
   //---
   errors[104].code = 4514;
   errors[104].description = "FTP文件发送失败";
   errors[104].constant = "ERR_FTP_SEND_FAILED";
   //---
   errors[105].code = 4515;
   errors[105].description = "通知发送失败";
   errors[105].constant = "ERR_NOTIFICATION_SEND_FAILED";
   //---
   errors[106].code = 4516;
   errors[106].description = "发送通知的参数无效——向SendNotification()传递了空字符串或NULL";
   errors[106].constant = "ERR_NOTIFICATION_WRONG_PARAMETER";
   //---
   errors[107].code = 4517;
   errors[107].description = "终端中的通知设置错误（未指定ID或未设置权限）";
   errors[107].constant = "ERR_NOTIFICATION_WRONG_SETTINGS";
   //---
   errors[108].code = 4518;
   errors[108].description = "通知发送频率超限";
   errors[108].constant = "ERR_NOTIFICATION_TOO_FREQUENT";
   //---
   errors[109].code = 4519;
   errors[109].description = "FTP服务器未在配置属性中指定";
   errors[109].constant = "ERR_FTP_NOSERVER";
   //---
   errors[110].code = 4520;
   errors[110].description = "FTP登录未在配置属性中指定";
   errors[110].constant = "ERR_FTP_NOLOGIN";
   //---
   errors[111].code = 4521;
   errors[111].description = "文件不存在";
   errors[111].constant = "ERR_FTP_FILE_ERROR";
   //---
   errors[112].code = 4522;
   errors[112].description = "无法连接到FTP服务器";
   errors[112].constant = "ERR_FTP_CONNECT_FAILED";
   //---
   errors[113].code = 4523;
   errors[113].description = "在FTP服务器上未找到文件上传目录";
   errors[113].constant = "ERR_FTP_CHANGEDIR";
   //---
   errors[114].code = 4524;
   errors[114].description = "与FTP服务器的连接已关闭";
   errors[114].constant = "ERR_FTP_CLOSED";
   //+------------------------------------------------------------------+
   //| Custom Indicator Buffers                                         |
   //+------------------------------------------------------------------+
   errors[115].code = 4601;
   errors[115].description = "内存不足，无法分配指标缓冲区";
   errors[115].constant = "ERR_BUFFERS_NO_MEMORY";
   //---
   errors[116].code = 4602;
   errors[116].description = "错误的指标缓冲区索引";
   errors[116].constant = "ERR_BUFFERS_WRONG_INDEX";
   //+------------------------------------------------------------------+
   //| Custom Indicator Properties                                      |
   //+------------------------------------------------------------------+
   errors[117].code = 4603;
   errors[117].description = "错误的自定义指标属性ID";
   errors[117].constant = "ERR_CUSTOM_WRONG_PROPERTY";
   //+------------------------------------------------------------------+
   //| Account                                                          |
   //+------------------------------------------------------------------+
   errors[118].code = 4701;
   errors[118].description = "错误的账户属性ID";
   errors[118].constant = "ERR_ACCOUNT_WRONG_PROPERTY";
   //---
   errors[119].code = 4751;
   errors[119].description = "错误的交易属性ID";
   errors[119].constant = "ERR_TRADE_WRONG_PROPERTY";
   //---
   errors[120].code = 4752;
   errors[120].description = "禁止通过智能交易系统进行交易";
   errors[120].constant = "ERR_TRADE_DISABLED";
   //---
   errors[121].code = 4753;
   errors[121].description = "未找到持仓";
   errors[121].constant = "ERR_TRADE_POSITION_NOT_FOUND";
   //---
   errors[122].code = 4754;
   errors[122].description = "未找到订单";
   errors[122].constant = "ERR_TRADE_ORDER_NOT_FOUND";
   //---
   errors[123].code = 4755;
   errors[123].description = "未找到成交";
   errors[123].constant = "ERR_TRADE_DEAL_NOT_FOUND";
   //---
   errors[124].code = 4756;
   errors[124].description = "无法发送交易请求";
   errors[124].constant = "ERR_TRADE_SEND_FAILED";
   //---
   errors[125].code = 4758;
   errors[125].description = "无法计算交易指数值";
   errors[125].constant = "ERR_TRADE_CALC_FAILED";
   //+------------------------------------------------------------------+
   //| Indicators                                                       |
   //+------------------------------------------------------------------+
   errors[126].code = 4801;
   errors[126].description = "未知品种";
   errors[126].constant = "ERR_INDICATOR_UNKNOWN_SYMBOL";
   //---
   errors[127].code = 4802;
   errors[127].description = "无法创建指标";
   errors[127].constant = "ERR_INDICATOR_CANNOT_CREATE";
   //---
   errors[128].code = 4803;
   errors[128].description = "内存不足，无法添加指标";
   errors[128].constant = "ERR_INDICATOR_NO_MEMORY";
   //---
   errors[129].code = 4804;
   errors[129].description = "无法将指标应用于另一个指标";
   errors[129].constant = "ERR_INDICATOR_CANNOT_APPLY";
   //---
   errors[130].code = 4805;
   errors[130].description = "无法将指标应用到图表";
   errors[130].constant = "ERR_INDICATOR_CANNOT_ADD";
   //---
   errors[131].code = 4806;
   errors[131].description = "未找到请求的数据";
   errors[131].constant = "ERR_INDICATOR_DATA_NOT_FOUND";
   //---
   errors[132].code = 4807;
   errors[132].description = "错误的指标句柄";
   errors[132].constant = "ERR_INDICATOR_WRONG_HANDLE";
   //---
   errors[133].code = 4808;
   errors[133].description = "创建指标时参数数量错误";
   errors[133].constant = "ERR_INDICATOR_WRONG_PARAMETERS";
   //---
   errors[134].code = 4809;
   errors[134].description = "创建指标时缺少参数";
   errors[134].constant = "ERR_INDICATOR_PARAMETERS_MISSING";
   //---
   errors[135].code = 4810;
   errors[135].description = "数组中的第一个参数必须是自定义指标的名称";
   errors[135].constant = "ERR_INDICATOR_CUSTOM_NAME";
   //---
   errors[136].code = 4811;
   errors[136].description = "创建指标时数组中的参数类型无效";
   errors[136].constant = "ERR_INDICATOR_PARAMETER_TYPE";
   //---
   errors[137].code = 4812;
   errors[137].description = "请求的指标缓冲区索引错误";
   errors[137].constant = "ERR_INDICATOR_WRONG_INDEX";
   //+------------------------------------------------------------------+
   //| Depth of Market                                                  |
   //+------------------------------------------------------------------+
   errors[138].code = 4901;
   errors[138].description = "无法添加市场深度";
   errors[138].constant = "ERR_BOOKS_CANNOT_ADD";
   //---
   errors[139].code = 4902;
   errors[139].description = "无法移除市场深度";
   errors[139].constant = "ERR_BOOKS_CANNOT_DELETE";
   //---
   errors[140].code = 4903;
   errors[140].description = "无法获取市场深度数据";
   errors[140].constant = "ERR_BOOKS_CANNOT_GET";
   //---
   errors[141].code = 4904;
   errors[141].description = "订阅新市场深度数据时出错";
   errors[141].constant = "ERR_BOOKS_CANNOT_SUBSCRIBE";
   //+------------------------------------------------------------------+
   //| File Operations                                                  |
   //+------------------------------------------------------------------+
   errors[142].code = 5001;
   errors[142].description = "无法同时打开超过64个文件";
   errors[142].constant = "ERR_TOO_MANY_FILES";
   //---
   errors[143].code = 5002;
   errors[143].description = "无效的文件名";
   errors[143].constant = "ERR_WRONG_FILENAME";
   //---
   errors[144].code = 5003;
   errors[144].description = "文件名过长";
   errors[144].constant = "ERR_TOO_LONG_FILENAME";
   //---
   errors[145].code = 5004;
   errors[145].description = "文件打开错误";
   errors[145].constant = "ERR_CANNOT_OPEN_FILE";
   //---
   errors[146].code = 5005;
   errors[146].description = "读取时缓存内存不足";
   errors[146].constant = "ERR_FILE_CACHEBUFFER_ERROR";
   //---
   errors[147].code = 5006;
   errors[147].description = "文件删除错误";
   errors[147].constant = "ERR_CANNOT_DELETE_FILE";
   //---
   errors[148].code = 5007;
   errors[148].description = "具有此句柄的文件已关闭或未曾打开";
   errors[148].constant = "ERR_INVALID_FILEHANDLE";
   //---
   errors[149].code = 5008;
   errors[149].description = "错误的文件句柄";
   errors[149].constant = "ERR_WRONG_FILEHANDLE";
   //---
   errors[150].code = 5009;
   errors[150].description = "文件必须以写入方式打开";
   errors[150].constant = "ERR_FILE_NOTTOWRITE";
   //---
   errors[151].code = 5010;
   errors[151].description = "文件必须以读取方式打开";
   errors[151].constant = "ERR_FILE_NOTTOREAD";
   //---
   errors[152].code = 5011;
   errors[152].description = "文件必须以二进制方式打开";
   errors[152].constant = "ERR_FILE_NOTBIN";
   //---
   errors[153].code = 5012;
   errors[153].description = "文件必须以文本方式打开";
   errors[153].constant = "ERR_FILE_NOTTXT";
   //---
   errors[154].code = 5013;
   errors[154].description = "文件必须以文本或CSV方式打开";
   errors[154].constant = "ERR_FILE_NOTTXTORCSV";
   //---
   errors[155].code = 5014;
   errors[155].description = "文件必须以CSV方式打开";
   errors[155].constant = "ERR_FILE_NOTCSV";
   //---
   errors[156].code = 5015;
   errors[156].description = "文件读取错误";
   errors[156].constant = "ERR_FILE_READERROR";
   //---
   errors[157].code = 5016;
   errors[157].description = "文件以二进制方式打开时必须指定字符串大小";
   errors[157].constant = "ERR_FILE_BINSTRINGSIZE";
   //---
   errors[158].code = 5017;
   errors[158].description = "字符串数组必须使用文本文件，其他数组必须使用二进制文件";
   errors[158].constant = "ERR_INCOMPATIBLE_FILE";
   //---
   errors[159].code = 5018;
   errors[159].description = "这不是文件，而是目录";
   errors[159].constant = "ERR_FILE_IS_DIRECTORY";
   //---
   errors[160].code = 5019;
   errors[160].description = "文件不存在";
   errors[160].constant = "ERR_FILE_NOT_EXIST";
   //---
   errors[161].code = 5020;
   errors[161].description = "无法覆盖文件";
   errors[161].constant = "ERR_FILE_CANNOT_REWRITE";
   //---
   errors[162].code = 5021;
   errors[162].description = "无效的目录名";
   errors[162].constant = "ERR_WRONG_DIRECTORYNAME";
   //---
   errors[163].code = 5022;
   errors[163].description = "目录不存在";
   errors[163].constant = "ERR_DIRECTORY_NOT_EXIST";
   //---
   errors[164].code = 5023;
   errors[164].description = "这是文件，不是目录";
   errors[164].constant = "ERR_FILE_ISNOT_DIRECTORY";
   //---
   errors[165].code = 5024;
   errors[165].description = "无法删除目录";
   errors[165].constant = "ERR_CANNOT_DELETE_DIRECTORY";
   //---
   errors[166].code = 5025;
   errors[166].description = "无法清空目录（可能有一个或多个文件被锁定，删除操作失败）";
   errors[166].constant = "ERR_CANNOT_CLEAN_DIRECTORY";
   //---
   errors[167].code = 5026;
   errors[167].description = "无法将资源写入文件";
   errors[167].constant = "ERR_FILE_WRITEERROR";
   //---
   errors[168].code = 5027;
   errors[168].description = "无法从CSV文件读取下一个数据块（FileReadString, FileReadNumber, FileReadDatetime, FileReadBool），因为已到达文件末尾";
   errors[168].constant = "ERR_FILE_ENDOFFILE";
   //+------------------------------------------------------------------+
   //| String Casting                                                   |
   //+------------------------------------------------------------------+
   errors[169].code = 5030;
   errors[169].description = "字符串中没有日期";
   errors[169].constant = "ERR_NO_STRING_DATE";
   //---
   errors[170].code = 5031;
   errors[170].description = "字符串中的日期错误";
   errors[170].constant = "ERR_WRONG_STRING_DATE";
   //---
   errors[171].code = 5032;
   errors[171].description = "字符串中的时间错误";
   errors[171].constant = "ERR_WRONG_STRING_TIME";
   //---
   errors[172].code = 5033;
   errors[172].description = "将字符串转换为日期时出错";
   errors[172].constant = "ERR_STRING_TIME_ERROR";
   //---
   errors[173].code = 5034;
   errors[173].description = "字符串内存不足";
   errors[173].constant = "ERR_STRING_OUT_OF_MEMORY";
   //---
   errors[174].code = 5035;
   errors[174].description = "字符串长度小于预期";
   errors[174].constant = "ERR_STRING_SMALL_LEN";
   //---
   errors[175].code = 5036;
   errors[175].description = "数字过大，大于ULONG_MAX";
   errors[175].constant = "ERR_STRING_TOO_BIGNUMBER";
   //---
   errors[176].code = 5037;
   errors[176].description = "无效的格式字符串";
   errors[176].constant = "ERR_WRONG_FORMATSTRING";
   //---
   errors[177].code = 5038;
   errors[177].description = "格式说明符数量大于参数数量";
   errors[177].constant = "ERR_TOO_MANY_FORMATTERS";
   //---
   errors[178].code = 5039;
   errors[178].description = "参数数量大于格式说明符数量";
   errors[178].constant = "ERR_TOO_MANY_PARAMETERS";
   //---
   errors[179].code = 5040;
   errors[179].description = "无效的字符串参数";
   errors[179].constant = "ERR_WRONG_STRING_PARAMETER";
   //---
   errors[180].code = 5041;
   errors[180].description = "字符串中的位置超出范围";
   errors[180].constant = "ERR_STRINGPOS_OUTOFRANGE";
   //---
   errors[181].code = 5042;
   errors[181].description = "在字符串末尾添加了0，这是无用的操作";
   errors[181].constant = "ERR_STRING_ZEROADDED";
   //---
   errors[182].code = 5043;
   errors[182].description = "转换为字符串时数据类型未知";
   errors[182].constant = "ERR_STRING_UNKNOWNTYPE";
   //---
   errors[183].code = 5044;
   errors[183].description = "无效的字符串对象";
   errors[183].constant = "ERR_WRONG_STRING_OBJECT";
   //+------------------------------------------------------------------+
   //| Operations with Arrays                                           |
   //+------------------------------------------------------------------+
   errors[184].code = 5050;
   errors[184].description = "复制不兼容的数组。字符串数组只能复制到字符串数组，数值数组只能复制到数值数组";
   errors[184].constant = "ERR_INCOMPATIBLE_ARRAYS";
   //---
   errors[185].code = 5051;
   errors[185].description = "接收数组声明为AS_SERIES且大小不足";
   errors[185].constant = "ERR_SMALL_ASSERIES_ARRAY";
   //---
   errors[186].code = 5052;
   errors[186].description = "数组太小，起始位置超出数组范围";
   errors[186].constant = "ERR_SMALL_ARRAY";
   //---
   errors[187].code = 5053;
   errors[187].description = "零长度数组";
   errors[187].constant = "ERR_ZEROSIZE_ARRAY";
   //---
   errors[188].code = 5054;
   errors[188].description = "必须是数值数组";
   errors[188].constant = "ERR_NUMBER_ARRAYS_ONLY";
   //---
   errors[189].code = 5055;
   errors[189].description = "必须是一维数组";
   errors[189].constant = "ERR_ONE_DIMENSIONAL_ARRAY";
   //---
   errors[190].code = 5056;
   errors[190].description = "无法使用时间序列";
   errors[190].constant = "ERR_SERIES_ARRAY";
   //---
   errors[191].code = 5057;
   errors[191].description = "必须是double类型的数组";
   errors[191].constant = "ERR_DOUBLE_ARRAY_ONLY";
   //---
   errors[192].code = 5058;
   errors[192].description = "必须是float类型的数组";
   errors[192].constant = "ERR_FLOAT_ARRAY_ONLY";
   //---
   errors[193].code = 5059;
   errors[193].description = "必须是long类型的数组";
   errors[193].constant = "ERR_LONG_ARRAY_ONLY";
   //---
   errors[194].code = 5060;
   errors[194].description = "必须是int类型的数组";
   errors[194].constant = "ERR_INT_ARRAY_ONLY";
   //---
   errors[195].code = 5061;
   errors[195].description = "必须是short类型的数组";
   errors[195].constant = "ERR_SHORT_ARRAY_ONLY";
   //---
   errors[196].code = 5062;
   errors[196].description = "必须是char类型的数组";
   errors[196].constant = "ERR_CHAR_ARRAY_ONLY";
   //---
   errors[197].code = 5063;
   errors[197].description = "必须是string类型的数组";
   errors[197].constant = "ERR_STRING_ARRAY_ONLY";
   //+------------------------------------------------------------------+
   //| Operations with OpenCL                                           |
   //+------------------------------------------------------------------+
   errors[198].code = 5100;
   errors[198].description = "此计算机不支持OpenCL函数";
   errors[198].constant = "ERR_OPENCL_NOT_SUPPORTED";
   //---
   errors[199].code = 5101;
   errors[199].description = "执行OpenCL时发生内部错误";
   errors[199].constant = "ERR_OPENCL_INTERNAL";
   //---
   errors[200].code = 5102;
   errors[200].description = "无效的OpenCL句柄";
   errors[200].constant = "ERR_OPENCL_INVALID_HANDLE";
   //---
   errors[201].code = 5103;
   errors[201].description = "创建OpenCL上下文时出错";
   errors[201].constant = "ERR_OPENCL_CONTEXT_CREATE";
   //---
   errors[202].code = 5104;
   errors[202].description = "无法在OpenCL中创建执行队列";
   errors[202].constant = "ERR_OPENCL_QUEUE_CREATE";
   //---
   errors[203].code = 5105;
   errors[203].description = "编译OpenCL程序时发生错误";
   errors[203].constant = "ERR_OPENCL_PROGRAM_CREATE";
   //---
   errors[204].code = 5106;
   errors[204].description = "内核名称过长（OpenCL内核）";
   errors[204].constant = "ERR_OPENCL_TOO_LONG_KERNEL_NAME";
   //---
   errors[205].code = 5107;
   errors[205].description = "创建OpenCL内核时出错";
   errors[205].constant = "ERR_OPENCL_KERNEL_CREATE";
   //---
   errors[206].code = 5108;
   errors[206].description = "设置OpenCL内核参数时出错";
   errors[206].constant = "ERR_OPENCL_SET_KERNEL_PARAMETER";
   //---
   errors[207].code = 5109;
   errors[207].description = "执行OpenCL程序时出错";
   errors[207].constant = "ERR_OPENCL_EXECUTE";
   //---
   errors[209].code = 5110;
   errors[209].description = "无效的OpenCL缓冲区大小";
   errors[209].constant = "ERR_OPENCL_WRONG_BUFFER_SIZE";
   //---
   errors[210].code = 5111;
   errors[210].description = "无效的OpenCL缓冲区偏移量";
   errors[210].constant = "ERR_OPENCL_WRONG_BUFFER_OFFSET";
   //---
   errors[211].code = 5112;
   errors[211].description = "无法创建OpenCL缓冲区";
   errors[211].constant = "ERR_OPENCL_BUFFER_CREATE";
   //---
   errors[212].code = 5113;
   errors[212].description = "超出OpenCL对象最大数量";
   errors[212].constant = "ERR_OPENCL_TOO_MANY_OBJECTS";
   //---
   errors[213].code = 5114;
   errors[213].description = "选择OpenCL设备时出错";
   errors[213].constant = "ERR_OPENCL_SELECTDEVICE";
   //+------------------------------------------------------------------+
   //| Working with databases                                           |
   //+------------------------------------------------------------------+
   errors[214].code = 5120;
   errors[214].description = "内部数据库错误";
   errors[214].constant = "ERR_DATABASE_INTERNAL";
   //---
   errors[215].code = 5121;
   errors[215].description = "无效的数据库句柄";
   errors[215].constant = "ERR_DATABASE_INVALID_HANDLE";
   //---
   errors[216].code = 5122;
   errors[216].description = "超出数据库对象最大数量";
   errors[216].constant = "ERR_DATABASE_TOO_MANY_OBJECTS";
   //---
   errors[217].code = 5123;
   errors[217].description = "连接数据库时出错";
   errors[217].constant = "ERR_DATABASE_CONNECT";
   //---
   errors[218].code = 5124;
   errors[218].description = "查询执行错误";
   errors[218].constant = "ERR_DATABASE_EXECUTE";
   //---
   errors[219].code = 5125;
   errors[219].description = "创建查询时出错";
   errors[219].constant = "ERR_DATABASE_PREPARE";
   //---
   errors[220].code = 5126;
   errors[220].description = "没有更多数据可读取";
   errors[220].constant = "ERR_DATABASE_NO_MORE_DATA";
   //---
   errors[221].code = 5127;
   errors[221].description = "查询中跳转到下一条记录时出错";
   errors[221].constant = "ERR_DATABASE_STEP";
   //---
   errors[222].code = 5128;
   errors[222].description = "查询结果数据尚未准备好";
   errors[222].constant = "ERR_DATABASE_NOT_READY";
   //---
   errors[223].code = 5129;
   errors[223].description = "SQL查询中自动参数绑定出错";
   errors[223].constant = "ERR_DATABASE_BIND_PARAMETERS";
   //+------------------------------------------------------------------+
   //| Operations with WebRequest                                       |
   //+------------------------------------------------------------------+
   errors[224].code = 5200;
   errors[224].description = "无效的URL";
   errors[224].constant = "ERR_WEBREQUEST_INVALID_ADDRESS";
   //---
   errors[225].code = 5201;
   errors[225].description = "无法连接到指定的URL";
   errors[225].constant = "ERR_WEBREQUEST_CONNECT_FAILED";
   //---
   errors[226].code = 5202;
   errors[226].description = "超时";
   errors[226].constant = "ERR_WEBREQUEST_TIMEOUT";
   //---
   errors[227].code = 5203;
   errors[227].description = "HTTP请求失败";
   errors[227].constant = "ERR_WEBREQUEST_REQUEST_FAILED";
   //+------------------------------------------------------------------+
   //| Operations with network (sockets)                                |
   //+------------------------------------------------------------------+
   errors[228].code = 5270;
   errors[228].description = "传递给函数的套接字句柄无效";
   errors[228].constant = "ERR_NETSOCKET_INVALIDHANDLE";
   //---
   errors[229].code = 5271;
   errors[229].description = "打开的套接字过多（最多128个）";
   errors[229].constant = "ERR_NETSOCKET_TOO_MANY_OPENED";
   //---
   errors[230].code = 5272;
   errors[230].description = "连接远程主机时出错";
   errors[230].constant = "ERR_NETSOCKET_CANNOT_CONNECT";
   //---
   errors[231].code = 5273;
   errors[231].description = "通过套接字发送/接收数据时出错";
   errors[231].constant = "ERR_NETSOCKET_IO_ERROR";
   //---
   errors[232].code = 5274;
   errors[232].description = "建立安全连接时出错（TLS握手）";
   errors[232].constant = "ERR_NETSOCKET_HANDSHAKE_FAILED";
   //---
   errors[233].code = 5275;
   errors[233].description = "没有关于保护连接的证书的信息";
   errors[233].constant = "ERR_NETSOCKET_NO_CERTIFICATE";
   //+------------------------------------------------------------------+
   //| Custom Symbols                                                   |
   //+------------------------------------------------------------------+
   errors[234].code = 5300;
   errors[234].description = "必须指定自定义品种";
   errors[234].constant = "ERR_NOT_CUSTOM_SYMBOL";
   //---
   errors[235].code = 5301;
   errors[235].description = "自定义品种名称不正确。品种名称中只允许使用无标点、空格和特殊字符的拉丁字母（允许'.'、'_'、'&'和'#'）。不建议使用<, >, :, ', /, |, ?, *";
   errors[235].constant = "ERR_CUSTOM_SYMBOL_WRONG_NAME";
   //---
   errors[236].code = 5302;
   errors[236].description = "自定义品种名称过长。名称（包括结尾0）不得超过32个字符";
   errors[236].constant = "ERR_CUSTOM_SYMBOL_NAME_LONG";
   //---
   errors[237].code = 5303;
   errors[237].description = "自定义品种路径过长。路径（包括'Custom\\'、品种名称、分组分隔符和结尾0）不得超过128个字符";
   errors[237].constant = "ERR_CUSTOM_SYMBOL_PATH_LONG";
   //---
   errors[238].code = 5304;
   errors[238].description = "已存在同名自定义品种";
   errors[238].constant = "ERR_CUSTOM_SYMBOL_EXIST";
   //---
   errors[239].code = 5305;
   errors[239].description = "创建、删除或修改自定义品种时出错";
   errors[239].constant = "ERR_CUSTOM_SYMBOL_ERROR";
   //---
   errors[240].code = 5306;
   errors[240].description = "尝试删除市场报价中已选中的自定义品种";
   errors[240].constant = "ERR_CUSTOM_SYMBOL_SELECTED";
   //---
   errors[241].code = 5307;
   errors[241].description = "自定义品种属性不正确";
   errors[241].constant = "ERR_CUSTOM_SYMBOL_PROPERTY_WRONG";
   //---
   errors[242].code = 5308;
   errors[242].description = "设置自定义品种属性时参数错误";
   errors[242].constant = "ERR_CUSTOM_SYMBOL_PARAMETER_ERROR";
   //---
   errors[243].code = 5309;
   errors[243].description = "设置自定义品种属性时参数字符串过长";
   errors[243].constant = "ERR_CUSTOM_SYMBOL_PARAMETER_LONG";
   //---
   errors[244].code = 5310;
   errors[244].description = "Tick数组未按时间排序";
   errors[244].constant = "ERR_CUSTOM_TICKS_WRONG_ORDER";
   //+------------------------------------------------------------------+
   //| Economic Calendar                                                |
   //+------------------------------------------------------------------+
   errors[245].code = 5400;
   errors[245].description = "数组大小不足，无法获取所有值的说明";
   errors[245].constant = "ERR_CALENDAR_MORE_DATA";
   //---
   errors[246].code = 5401;
   errors[246].description = "请求超出时间限制";
   errors[246].constant = "ERR_CALENDAR_TIMEOUT";
   //---
   errors[247].code = 5402;
   errors[247].description = "未找到国家";
   errors[247].constant = "ERR_CALENDAR_NO_DATA";
   //+------------------------------------------------------------------+
   //| Working with databases                                           |
   //+------------------------------------------------------------------+
   errors[248].code = 5601;
   errors[248].description = "通用错误";
   errors[248].constant = "ERR_DATABASE_ERROR";
   //---
   errors[249].code = 5602;
   errors[249].description = "内部SQLite逻辑错误";
   errors[249].constant = "ERR_DATABASE_INTERNAL";
   //---
   errors[250].code = 5603;
   errors[250].description = "拒绝访问";
   errors[250].constant = "ERR_DATABASE_PERM";
   //---
   errors[251].code = 5604;
   errors[251].description = "回调例程请求中止";
   errors[251].constant = "ERR_DATABASE_ABORT";
   //---
   errors[252].code = 5605;
   errors[252].description = "数据库文件被锁定";
   errors[252].constant = "ERR_DATABASE_BUSY";
   //---
   errors[253].code = 5606;
   errors[253].description = "数据库表被锁定";
   errors[253].constant = "ERR_DATABASE_LOCKED";
   //---
   errors[254].code = 5607;
   errors[254].description = "内存不足，无法完成操作";
   errors[254].constant = "ERR_DATABASE_NOMEM";
   //---
   errors[255].code = 5608;
   errors[255].description = "尝试写入只读数据库";
   errors[255].constant = "ERR_DATABASE_READONLY";
   //---
   errors[256].code = 5609;
   errors[256].description = "操作被sqlite3_interrupt()终止";
   errors[256].constant = "ERR_DATABASE_INTERRUPT";
   //---
   errors[257].code = 5610;
   errors[257].description = "磁盘I/O错误";
   errors[257].constant = "ERR_DATABASE_IOERR";
   //---
   errors[258].code = 5611;
   errors[258].description = "数据库磁盘映像已损坏";
   errors[258].constant = "ERR_DATABASE_CORRUPT";
   //---
   errors[259].code = 5612;
   errors[259].description = "sqlite3_file_control()中未知的操作码";
   errors[259].constant = "ERR_DATABASE_NOTFOUND";
   //---
   errors[260].code = 5613;
   errors[260].description = "插入失败，因为数据库已满";
   errors[260].constant = "ERR_DATABASE_FULL";
   //---
   errors[261].code = 5614;
   errors[261].description = "无法打开数据库文件";
   errors[261].constant = "ERR_DATABASE_CANTOPEN";
   //---
   errors[262].code = 5615;
   errors[262].description = "数据库锁定协议错误";
   errors[262].constant = "ERR_DATABASE_PROTOCOL";
   //---
   errors[263].code = 5616;
   errors[263].description = "仅供内部使用";
   errors[263].constant = "ERR_DATABASE_EMPTY";
   //---
   errors[264].code = 5617;
   errors[264].description = "数据库架构已更改";
   errors[264].constant = "ERR_DATABASE_SCHEMA";
   //---
   errors[265].code = 5618;
   errors[265].description = "字符串或BLOB超出大小限制";
   errors[265].constant = "ERR_DATABASE_TOOBIG";
   //---
   errors[266].code = 5619;
   errors[266].description = "因违反约束而中止";
   errors[266].constant = "ERR_DATABASE_CONSTRAINT";
   //---
   errors[267].code = 5620;
   errors[267].description = "数据类型不匹配";
   errors[267].constant = "ERR_DATABASE_MISMATCH";
   //---
   errors[268].code = 5621;
   errors[268].description = "库使用不当";
   errors[268].constant = "ERR_DATABASE_MISUSE";
   //---
   errors[269].code = 5622;
   errors[269].description = "使用主机不支持的操作系统资源";
   errors[269].constant = "ERR_DATABASE_NOLFS";
   //---
   errors[270].code = 5623;
   errors[270].description = "授权被拒绝";
   errors[270].constant = "ERR_DATABASE_AUTH";
   //---
   errors[271].code = 5624;
   errors[271].description = "未使用";
   errors[271].constant = "ERR_DATABASE_FORMAT";
   //---
   errors[272].code = 5625;
   errors[272].description = "参数绑定错误，索引错误";
   errors[272].constant = "ERR_DATABASE_RANGE";
   //---
   errors[273].code = 5626;
   errors[273].description = "打开的文件不是数据库文件";
   errors[273].constant = "ERR_DATABASE_NOTADB";
  }
//+------------------------------------------------------------------+


