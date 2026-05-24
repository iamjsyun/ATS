//+------------------------------------------------------------------+
//|                                             ErrorMessages.es.mqh |
//|                                                     joaopedrodev |
//|                       https://www.mql5.com/en/users/joaopedrodev |
//+------------------------------------------------------------------+
#property copyright "joaopedrodev"
#property link      "https://www.mql5.com/en/users/joaopedrodev"
//+------------------------------------------------------------------+
//| Import struct                                                    
//+------------------------------------------------------------------+
#include "../Error.mqh"
void InitializeErrorsSpanish(MqlError &errors[])
  {
   //--- Free and resize
   ArrayFree(errors);
   ArrayResize(errors,274);
   
   //+------------------------------------------------------------------+
   //| Unknown error                                                    |
   //+------------------------------------------------------------------+
   errors[0].code = 0;
   errors[0].description = "No se encontró ningún error";
   errors[0].constant = "ERROR_UNKNOWN";
   //+------------------------------------------------------------------+
   //| Server error                                                     |
   //+------------------------------------------------------------------+
   errors[1].code = 10004;
   errors[1].description = "Nueva cotización";
   errors[1].constant = "TRADE_RETCODE_REQUOTE";
   //---
   errors[2].code = 10006;
   errors[2].description = "Solicitud rechazada";
   errors[2].constant = "TRADE_RETCODE_REJECT";
   //---
   errors[3].code = 10007;
   errors[3].description = "Solicitud cancelada por el operador";
   errors[3].constant = "TRADE_RETCODE_CANCEL";
   //---
   errors[4].code = 10008;
   errors[4].description = "Orden colocada";
   errors[4].constant = "TRADE_RETCODE_PLACED";
   //---
   errors[5].code = 10009;
   errors[5].description = "Solicitud completada";
   errors[5].constant = "TRADE_RETCODE_DONE";
   //---
   errors[6].code = 10010;
   errors[6].description = "Solo se completó parte de la solicitud";
   errors[6].constant = "TRADE_RETCODE_DONE_PARTIAL";
   //---
   errors[7].code = 10011;
   errors[7].description = "Error al procesar la solicitud";
   errors[7].constant = "TRADE_RETCODE_ERROR";
   //---
   errors[8].code = 10012;
   errors[8].description = "Solicitud cancelada por tiempo de espera";
   errors[8].constant = "TRADE_RETCODE_TIMEOUT";
   //---
   errors[9].code = 10013;
   errors[9].description = "Solicitud inválida";
   errors[9].constant = "TRADE_RETCODE_INVALID";
   //---
   errors[10].code = 10014;
   errors[10].description = "Volumen inválido en la solicitud";
   errors[10].constant = "TRADE_RETCODE_INVALID_VOLUME";
   //---
   errors[11].code = 10015;
   errors[11].description = "Precio inválido en la solicitud";
   errors[11].constant = "TRADE_RETCODE_INVALID_PRICE";
   //---
   errors[12].code = 10016;
   errors[12].description = "Stops inválidos en la solicitud";
   errors[12].constant = "TRADE_RETCODE_INVALID_STOPS";
   //---
   errors[13].code = 10017;
   errors[13].description = "La negociación está deshabilitada";
   errors[13].constant = "TRADE_RETCODE_TRADE_DISABLED";
   //---
   errors[14].code = 10018;
   errors[14].description = "El mercado está cerrado";
   errors[14].constant = "TRADE_RETCODE_MARKET_CLOSED";
   //---
   errors[15].code = 10019;
   errors[15].description = "Fondos insuficientes para completar la solicitud";
   errors[15].constant = "TRADE_RETCODE_NO_MONEY";
   //---
   errors[16].code = 10020;
   errors[16].description = "Los precios han cambiado";
   errors[16].constant = "TRADE_RETCODE_PRICE_CHANGED";
   //---
   errors[17].code = 10021;
   errors[17].description = "No hay cotizaciones para procesar la solicitud";
   errors[17].constant = "TRADE_RETCODE_PRICE_OFF";
   //---
   errors[18].code = 10022;
   errors[18].description = "Fecha de expiración de la orden inválida en la solicitud";
   errors[18].constant = "TRADE_RETCODE_INVALID_EXPIRATION";
   //---
   errors[19].code = 10023;
   errors[19].description = "Estado de la orden cambiado";
   errors[19].constant = "TRADE_RETCODE_ORDER_CHANGED";
   //---
   errors[20].code = 10024;
   errors[20].description = "Demasiadas solicitudes";
   errors[20].constant = "TRADE_RETCODE_TOO_MANY_REQUESTS";
   //---
   errors[21].code = 10025;
   errors[21].description = "Sin cambios en la solicitud";
   errors[21].constant = "TRADE_RETCODE_NO_CHANGES";
   //---
   errors[22].code = 10026;
   errors[22].description = "Autotrading deshabilitado por el servidor";
   errors[22].constant = "TRADE_RETCODE_SERVER_DISABLES_AT";
   //---
   errors[23].code = 10027;
   errors[23].description = "Autotrading deshabilitado por el terminal cliente";
   errors[23].constant = "TRADE_RETCODE_CLIENT_DISABLES_AT";
   //---
   errors[24].code = 10028;
   errors[24].description = "Solicitud bloqueada para procesamiento";
   errors[24].constant = "TRADE_RETCODE_LOCKED";
   //---
   errors[25].code = 10029;
   errors[25].description = "Orden o posición congelada";
   errors[25].constant = "TRADE_RETCODE_FROZEN";
   //---
   errors[26].code = 10030;
   errors[26].description = "Tipo de llenado de orden inválido";
   errors[26].constant = "TRADE_RETCODE_INVALID_FILL";
   //---
   errors[27].code = 10031;
   errors[27].description = "Sin conexión con el servidor de trading";
   errors[27].constant = "TRADE_RETCODE_CONNECTION";
   //---
   errors[28].code = 10032;
   errors[28].description = "Operación permitida solo para cuentas reales";
   errors[28].constant = "TRADE_RETCODE_ONLY_REAL";
   //---
   errors[29].code = 10033;
   errors[29].description = "El número de órdenes pendientes alcanzó el límite";
   errors[29].constant = "TRADE_RETCODE_LIMIT_ORDERS";
   //---
   errors[30].code = 10034;
   errors[30].description = "El volumen de órdenes y posiciones para el símbolo alcanzó el límite";
   errors[30].constant = "TRADE_RETCODE_LIMIT_VOLUME";
   //---
   errors[31].code = 10035;
   errors[31].description = "Tipo de orden incorrecto o prohibido";
   errors[31].constant = "TRADE_RETCODE_INVALID_ORDER";
   //---
   errors[32].code = 10036;
   errors[32].description = "La posición con el identificador especificado ya ha sido cerrada";
   errors[32].constant = "TRADE_RETCODE_POSITION_CLOSED";
   //---
   errors[33].code = 10038;
   errors[33].description = "El volumen a cerrar excede el volumen de la posición actual";
   errors[33].constant = "TRADE_RETCODE_INVALID_CLOSE_VOLUME";
   //---
   errors[34].code = 10039;
   errors[34].description = "Ver documentación";
   errors[34].constant = "TRADE_RETCODE_CLOSE_ORDER_EXIST";
   //---
   errors[35].code = 10040;
   errors[35].description = "Ver documentación";
   errors[35].constant = "TRADE_RETCODE_LIMIT_POSITIONS";
   //---
   errors[36].code = 10041;
   errors[36].description = "La solicitud de activación de orden pendiente fue rechazada y la orden cancelada";
   errors[36].constant = "TRADE_RETCODE_REJECT_CANCEL";
   //---
   errors[37].code = 10042;
   errors[37].description = "La orden fue rechazada porque el símbolo está configurado como 'Solo posiciones largas' (POSITION_TYPE_BUY)";
   errors[37].constant = "TRADE_RETCODE_LONG_ONLY";
   //---
   errors[38].code = 10043;
   errors[38].description = "La orden fue rechazada porque el símbolo está configurado como 'Solo posiciones cortas' (POSITION_TYPE_SELL)";
   errors[38].constant = "TRADE_RETCODE_SHORT_ONLY";
   //---
   errors[39].code = 10044;
   errors[39].description = "La orden fue rechazada porque el símbolo está configurado como 'Solo cierre de posición'";
   errors[39].constant = "TRADE_RETCODE_CLOSE_ONLY";
   //---
   errors[40].code = 10045;
   errors[40].description = "La orden fue rechazada porque el símbolo está configurado como 'Solo cierre de posición'";
   errors[40].constant = "TRADE_RETCODE_FIFO_CLOSE";
   //---
   errors[41].code = 10046;
   errors[41].description = "La orden fue rechazada porque el símbolo está configurado como 'Prohibido abrir posiciones opuestas para el mismo símbolo'";
   errors[41].constant = "TRADE_RETCODE_HEDGE_PROHIBITED";
   //+------------------------------------------------------------------+
   //| Errors sistem                                                    |
   //+------------------------------------------------------------------+
   errors[42].code = 4001;
   errors[42].description = "Error interno inesperado";
   errors[42].constant = "ERR_INTERNAL_ERROR";
   //---
   errors[43].code = 4002;
   errors[43].description = "Parámetro incorrecto en llamada interna de función del terminal cliente";
   errors[43].constant = "ERR_WRONG_INTERNAL_PARAMETER";
   //---
   errors[44].code = 4003;
   errors[44].description = "Parámetro incorrecto al llamar a función del sistema";
   errors[44].constant = "ERR_INVALID_PARAMETER";
   //---
   errors[45].code = 4004;
   errors[45].description = "Memoria insuficiente para ejecutar la función del sistema";
   errors[45].constant = "ERR_NOT_ENOUGH_MEMORY";
   //---
   errors[46].code = 4005;
   errors[46].description = "La estructura contiene objetos de cadena y/o arrays dinámicos y/o estructuras de tales objetos y/o clases";
   errors[46].constant = "ERR_STRUCT_WITHOBJECTS_ORCLASS";
   //---
   errors[47].code = 4006;
   errors[47].description = "Array de tipo incorrecto, tamaño incorrecto o objeto defectuoso de un array dinámico";
   errors[47].constant = "ERR_INVALID_ARRAY";
   //---
   errors[48].code = 4007;
   errors[48].description = "Memoria insuficiente para reasignar el array o intento de cambiar el tamaño de un array estático";
   errors[48].constant = "ERR_ARRAY_RESIZE_ERROR";
   //---
   errors[49].code = 4008;
   errors[49].description = "Memoria insuficiente para reasignar la cadena";
   errors[49].constant = "ERR_STRING_RESIZE_ERROR";
   //---
   errors[50].code = 4009;
   errors[50].description = "Cadena no inicializada";
   errors[50].constant = "ERR_NOTINITIALIZED_STRING";
   //---
   errors[51].code = 4010;
   errors[51].description = "Fecha y/o hora inválida";
   errors[51].constant = "ERR_INVALID_DATETIME";
   //---
   errors[52].code = 4011;
   errors[52].description = "La cantidad total de elementos en el array no puede exceder 2147483647";
   errors[52].constant = "ERR_ARRAY_BAD_SIZE";
   //---
   errors[53].code = 4012;
   errors[53].description = "Puntero incorrecto";
   errors[53].constant = "ERR_INVALID_POINTER";
   //---
   errors[54].code = 4013;
   errors[54].description = "Tipo de puntero incorrecto";
   errors[54].constant = "ERR_INVALID_POINTER_TYPE";
   //---
   errors[55].code = 4014;
   errors[55].description = "No se permite llamar a la función del sistema";
   errors[55].constant = "ERR_FUNCTION_NOT_ALLOWED";
   //---
   errors[56].code = 4015;
   errors[56].description = "Los nombres de los recursos dinámicos y estáticos son idénticos";
   errors[56].constant = "ERR_RESOURCE_NAME_DUPLICATED";
   //---
   errors[57].code = 4016;
   errors[57].description = "Recurso con este nombre no encontrado en EX5";
   errors[57].constant = "ERR_RESOURCE_NOT_FOUND";
   //---
   errors[58].code = 4017;
   errors[58].description = "Tipo de recurso no soportado o su tamaño excede 16 Mb";
   errors[58].constant = "ERR_RESOURCE_UNSUPPOTED_TYPE";
   //---
   errors[59].code = 4018;
   errors[59].description = "El nombre del recurso excede los 63 caracteres";
   errors[59].constant = "ERR_RESOURCE_NAME_IS_TOO_LONG";
   //---
   errors[60].code = 4019;
   errors[60].description = "Desbordamiento durante el cálculo de funciones matemáticas";
   errors[60].constant = "ERR_MATH_OVERFLOW";
   //---
   errors[61].code = 4020;
   errors[61].description = "Fin de prueba excedido después de llamar a Sleep()";
   errors[61].constant = "ERR_SLEEP_ERROR";
   //---
   errors[62].code = 4022;
   errors[62].description = "Las pruebas fueron interrumpidas forzosamente desde fuera. Por ejemplo, al detener la optimización, cerrar la ventana de prueba visual o detener el agente de pruebas";
   errors[62].constant = "ERR_STOPPED";
   //+------------------------------------------------------------------+
   //| Charts                                                           |
   //+------------------------------------------------------------------+
   errors[63].code = 4101;
   errors[63].description = "ID de gráfico incorrecto";
   errors[63].constant = "ERR_CHART_WRONG_ID";
   //---
   errors[64].code = 4102;
   errors[64].description = "El gráfico no responde";
   errors[64].constant = "ERR_CHART_NO_REPLY";
   //---
   errors[65].code = 4103;
   errors[65].description = "Gráfico no encontrado";
   errors[65].constant = "ERR_CHART_NOT_FOUND";
   //---
   errors[66].code = 4104;
   errors[66].description = "No hay Asesor Experto en el gráfico para manejar el evento";
   errors[66].constant = "ERR_CHART_NO_EXPERT";
   //---
   errors[67].code = 4105;
   errors[67].description = "Error al abrir el gráfico";
   errors[67].constant = "ERR_CHART_CANNOT_OPEN";
   //---
   errors[68].code = 4106;
   errors[68].description = "Error al cambiar el símbolo y el período del gráfico";
   errors[68].constant = "ERR_CHART_CANNOT_CHANGE";
   //---
   errors[69].code = 4107;
   errors[69].description = "Valor de parámetro incorrecto para la función que trabaja con gráficos";
   errors[69].constant = "ERR_CHART_WRONG_PARAMETER";
   //---
   errors[70].code = 4108;
   errors[70].description = "Error al crear el temporizador";
   errors[70].constant = "ERR_CHART_CANNOT_CREATE_TIMER";
   //---
   errors[71].code = 4109;
   errors[71].description = "ID de propiedad de gráfico incorrecto";
   errors[71].constant = "ERR_CHART_WRONG_PROPERTY";
   //---
   errors[72].code = 4110;
   errors[72].description = "Error al crear capturas de pantalla";
   errors[72].constant = "ERR_CHART_SCREENSHOT_FAILED";
   //---
   errors[73].code = 4111;
   errors[73].description = "Error al navegar por el gráfico";
   errors[73].constant = "ERR_CHART_NAVIGATE_FAILED";
   //---
   errors[74].code = 4112;
   errors[74].description = "Error al aplicar la plantilla";
   errors[74].constant = "ERR_CHART_TEMPLATE_FAILED";
   //---
   errors[75].code = 4113;
   errors[75].description = "Subventana que contiene el indicador no encontrada";
   errors[75].constant = "ERR_CHART_WINDOW_NOT_FOUND";
   //---
   errors[76].code = 4114;
   errors[76].description = "Error al agregar el indicador al gráfico";
   errors[76].constant = "ERR_CHART_INDICATOR_CANNOT_ADD";
   //---
   errors[77].code = 4115;
   errors[77].description = "Error al eliminar el indicador del gráfico";
   errors[77].constant = "ERR_CHART_INDICATOR_CANNOT_DEL";
   //---
   errors[78].code = 4116;
   errors[78].description = "Indicador no encontrado en el gráfico especificado";
   errors[78].constant = "ERR_CHART_INDICATOR_NOT_FOUND";
   //+------------------------------------------------------------------+
   //| Graphical Objects                                                |
   //+------------------------------------------------------------------+
   errors[79].code = 4201;
   errors[79].description = "Error al trabajar con el objeto gráfico";
   errors[79].constant = "ERR_OBJECT_ERROR";
   //---
   errors[80].code = 4202;
   errors[80].description = "Objeto gráfico no encontrado";
   errors[80].constant = "ERR_OBJECT_NOT_FOUND";
   //---
   errors[81].code = 4203;
   errors[81].description = "ID de propiedad de objeto gráfico incorrecto";
   errors[81].constant = "ERR_OBJECT_WRONG_PROPERTY";
   //---
   errors[82].code = 4204;
   errors[82].description = "No se pudo obtener la fecha correspondiente al valor";
   errors[82].constant = "ERR_OBJECT_GETDATE_FAILED";
   //---
   errors[83].code = 4205;
   errors[83].description = "No se pudo obtener el valor correspondiente a la fecha";
   errors[83].constant = "ERR_OBJECT_GETVALUE_FAILED";
   //+------------------------------------------------------------------+
   //| MarketInfo                                                       |
   //+------------------------------------------------------------------+
   errors[84].code = 4301;
   errors[84].description = "Símbolo desconocido";
   errors[84].constant = "ERR_MARKET_UNKNOWN_SYMBOL";
   //---
   errors[85].code = 4302;
   errors[85].description = "El símbolo no está seleccionado en la ventana de Observación de Mercado";
   errors[85].constant = "ERR_MARKET_NOT_SELECTED";
   //---
   errors[86].code = 4303;
   errors[86].description = "ID de propiedad de símbolo incorrecto";
   errors[86].constant = "ERR_MARKET_WRONG_PROPERTY";
   //---
   errors[87].code = 4304;
   errors[87].description = "Hora del último tick desconocida (sin ticks)";
   errors[87].constant = "ERR_MARKET_LASTTIME_UNKNOWN";
   //---
   errors[88].code = 4305;
   errors[88].description = "Error al agregar o eliminar símbolo en la ventana de Observación de Mercado";
   errors[88].constant = "ERR_MARKET_SELECT_ERROR";
   //+------------------------------------------------------------------+
   //| History Access                                                   |
   //+------------------------------------------------------------------+
   errors[89].code = 4401;
   errors[89].description = "Historial solicitado no encontrado";
   errors[89].constant = "ERR_HISTORY_NOT_FOUND";
   //---
   errors[90].code = 4402;
   errors[90].description = "ID de propiedad de historial incorrecto";
   errors[90].constant = "ERR_HISTORY_WRONG_PROPERTY";
   //---
   errors[91].code = 4403;
   errors[91].description = "Tiempo de espera de solicitud de historial agotado";
   errors[91].constant = "ERR_HISTORY_TIMEOUT";
   //---
   errors[92].code = 4404;
   errors[92].description = "Número de barras limitado por la configuración del terminal";
   errors[92].constant = "ERR_HISTORY_BARS_LIMIT";
   //---
   errors[93].code = 4405;
   errors[93].description = "Errores múltiples al cargar el historial";
   errors[93].constant = "ERR_HISTORY_LOAD_ERRORS";
   //---
   errors[94].code = 4407;
   errors[94].description = "El array de recepción es demasiado pequeño para almacenar todos los datos solicitados";
   errors[94].constant = "ERR_HISTORY_SMALL_BUFFER";
   //+------------------------------------------------------------------+
   //| Global Variables                                                 |
   //+------------------------------------------------------------------+
   errors[95].code = 4501;
   errors[95].description = "Variable global del terminal cliente no encontrada";
   errors[95].constant = "ERR_GLOBALVARIABLE_NOT_FOUND";
   //---
   errors[96].code = 4502;
   errors[96].description = "Ya existe una variable global del terminal cliente con el mismo nombre";
   errors[96].constant = "ERR_GLOBALVARIABLE_EXISTS";
   //---
   errors[97].code = 4503;
   errors[97].description = "No hubo modificaciones en las variables globales";
   errors[97].constant = "ERR_GLOBALVARIABLE_NOT_MODIFIED";
   //---
   errors[98].code = 4504;
   errors[98].description = "No se pudo abrir y leer el archivo con los valores de las variables globales";
   errors[98].constant = "ERR_GLOBALVARIABLE_CANNOTREAD";
   //---
   errors[99].code = 4505;
   errors[99].description = "No se pudo escribir el archivo con los valores de las variables globales";
   errors[99].constant = "ERR_GLOBALVARIABLE_CANNOTWRITE";
   //---
   errors[100].code = 4510;
   errors[100].description = "Error al enviar correo electrónico";
   errors[100].constant = "ERR_MAIL_SEND_FAILED";
   //---
   errors[101].code = 4511;
   errors[101].description = "Error al reproducir sonido";
   errors[101].constant = "ERR_PLAY_SOUND_FAILED";
   //---
   errors[102].code = 4512;
   errors[102].description = "ID de propiedad de programa incorrecto";
   errors[102].constant = "ERR_MQL5_WRONG_PROPERTY";
   //---
   errors[103].code = 4513;
   errors[103].description = "ID de propiedad de terminal incorrecto";
   errors[103].constant = "ERR_TERMINAL_WRONG_PROPERTY";
   //---
   errors[104].code = 4514;
   errors[104].description = "Error al enviar archivo por FTP";
   errors[104].constant = "ERR_FTP_SEND_FAILED";
   //---
   errors[105].code = 4515;
   errors[105].description = "Error al enviar notificación";
   errors[105].constant = "ERR_NOTIFICATION_SEND_FAILED";
   //---
   errors[106].code = 4516;
   errors[106].description = "Parámetro inválido para enviar notificación – se pasó una cadena vacía o NULL a SendNotification()";
   errors[106].constant = "ERR_NOTIFICATION_WRONG_PARAMETER";
   //---
   errors[107].code = 4517;
   errors[107].description = "Configuración de notificaciones incorrecta en el terminal (ID no especificado o permiso no establecido)";
   errors[107].constant = "ERR_NOTIFICATION_WRONG_SETTINGS";
   //---
   errors[108].code = 4518;
   errors[108].description = "Frecuencia de envío de notificaciones excedida";
   errors[108].constant = "ERR_NOTIFICATION_TOO_FREQUENT";
   //---
   errors[109].code = 4519;
   errors[109].description = "Servidor FTP no especificado en los atributos de configuración";
   errors[109].constant = "ERR_FTP_NOSERVER";
   //---
   errors[110].code = 4520;
   errors[110].description = "Login FTP no especificado en los atributos de configuración";
   errors[110].constant = "ERR_FTP_NOLOGIN";
   //---
   errors[111].code = 4521;
   errors[111].description = "El archivo no existe";
   errors[111].constant = "ERR_FTP_FILE_ERROR";
   //---
   errors[112].code = 4522;
   errors[112].description = "Error al conectar con el servidor FTP";
   errors[112].constant = "ERR_FTP_CONNECT_FAILED";
   //---
   errors[113].code = 4523;
   errors[113].description = "Directorio para subir archivo no encontrado en el servidor FTP";
   errors[113].constant = "ERR_FTP_CHANGEDIR";
   //---
   errors[114].code = 4524;
   errors[114].description = "Conexión con el servidor FTP cerrada";
   errors[114].constant = "ERR_FTP_CLOSED";
   //+------------------------------------------------------------------+
   //| Custom Indicator Buffers                                         |
   //+------------------------------------------------------------------+
   errors[115].code = 4601;
   errors[115].description = "Memoria insuficiente para asignar buffers de indicador";
   errors[115].constant = "ERR_BUFFERS_NO_MEMORY";
   //---
   errors[116].code = 4602;
   errors[116].description = "Índice de buffer de indicador incorrecto";
   errors[116].constant = "ERR_BUFFERS_WRONG_INDEX";
   //+------------------------------------------------------------------+
   //| Custom Indicator Properties                                      |
   //+------------------------------------------------------------------+
   errors[117].code = 4603;
   errors[117].description = "ID de propiedad de indicador personalizado incorrecto";
   errors[117].constant = "ERR_CUSTOM_WRONG_PROPERTY";
   //+------------------------------------------------------------------+
   //| Account                                                          |
   //+------------------------------------------------------------------+
   errors[118].code = 4701;
   errors[118].description = "ID de propiedad de cuenta incorrecto";
   errors[118].constant = "ERR_ACCOUNT_WRONG_PROPERTY";
   //---
   errors[119].code = 4751;
   errors[119].description = "ID de propiedad de trading incorrecto";
   errors[119].constant = "ERR_TRADE_WRONG_PROPERTY";
   //---
   errors[120].code = 4752;
   errors[120].description = "Trading mediante Expert Advisors está prohibido";
   errors[120].constant = "ERR_TRADE_DISABLED";
   //---
   errors[121].code = 4753;
   errors[121].description = "Posición no encontrada";
   errors[121].constant = "ERR_TRADE_POSITION_NOT_FOUND";
   //---
   errors[122].code = 4754;
   errors[122].description = "Orden no encontrada";
   errors[122].constant = "ERR_TRADE_ORDER_NOT_FOUND";
   //---
   errors[123].code = 4755;
   errors[123].description = "Operación no encontrada";
   errors[123].constant = "ERR_TRADE_DEAL_NOT_FOUND";
   //---
   errors[124].code = 4756;
   errors[124].description = "Error al enviar solicitud de trading";
   errors[124].constant = "ERR_TRADE_SEND_FAILED";
   //---
   errors[125].code = 4758;
   errors[125].description = "No se puede calcular el valor del índice de trading";
   errors[125].constant = "ERR_TRADE_CALC_FAILED";
   //+------------------------------------------------------------------+
   //| Indicators                                                       |
   //+------------------------------------------------------------------+
   errors[126].code = 4801;
   errors[126].description = "Símbolo desconocido";
   errors[126].constant = "ERR_INDICATOR_UNKNOWN_SYMBOL";
   //---
   errors[127].code = 4802;
   errors[127].description = "No se puede crear el indicador";
   errors[127].constant = "ERR_INDICATOR_CANNOT_CREATE";
   //---
   errors[128].code = 4803;
   errors[128].description = "Memoria insuficiente para agregar el indicador";
   errors[128].constant = "ERR_INDICATOR_NO_MEMORY";
   //---
   errors[129].code = 4804;
   errors[129].description = "No se puede aplicar el indicador a otro indicador";
   errors[129].constant = "ERR_INDICATOR_CANNOT_APPLY";
   //---
   errors[130].code = 4805;
   errors[130].description = "Error al aplicar el indicador al gráfico";
   errors[130].constant = "ERR_INDICATOR_CANNOT_ADD";
   //---
   errors[131].code = 4806;
   errors[131].description = "Datos solicitados no encontrados";
   errors[131].constant = "ERR_INDICATOR_DATA_NOT_FOUND";
   //---
   errors[132].code = 4807;
   errors[132].description = "Handle de indicador incorrecto";
   errors[132].constant = "ERR_INDICATOR_WRONG_HANDLE";
   //---
   errors[133].code = 4808;
   errors[133].description = "Número incorrecto de parámetros al crear el indicador";
   errors[133].constant = "ERR_INDICATOR_WRONG_PARAMETERS";
   //---
   errors[134].code = 4809;
   errors[134].description = "Sin parámetros al crear el indicador";
   errors[134].constant = "ERR_INDICATOR_PARAMETERS_MISSING";
   //---
   errors[135].code = 4810;
   errors[135].description = "El primer parámetro en el array debe ser el nombre del indicador personalizado";
   errors[135].constant = "ERR_INDICATOR_CUSTOM_NAME";
   //---
   errors[136].code = 4811;
   errors[136].description = "Tipo de parámetro inválido en el array al crear el indicador";
   errors[136].constant = "ERR_INDICATOR_PARAMETER_TYPE";
   //---
   errors[137].code = 4812;
   errors[137].description = "Índice incorrecto del buffer de indicador solicitado";
   errors[137].constant = "ERR_INDICATOR_WRONG_INDEX";
   //+------------------------------------------------------------------+
   //| Depth of Market                                                  |
   //+------------------------------------------------------------------+
   errors[138].code = 4901;
   errors[138].description = "No se puede agregar la Profundidad de Mercado";
   errors[138].constant = "ERR_BOOKS_CANNOT_ADD";
   //---
   errors[139].code = 4902;
   errors[139].description = "No se puede eliminar la Profundidad de Mercado";
   errors[139].constant = "ERR_BOOKS_CANNOT_DELETE";
   //---
   errors[140].code = 4903;
   errors[140].description = "No se pueden obtener los datos de la Profundidad de Mercado";
   errors[140].constant = "ERR_BOOKS_CANNOT_GET";
   //---
   errors[141].code = 4904;
   errors[141].description = "Error al suscribirse para recibir nuevos datos de la Profundidad de Mercado";
   errors[141].constant = "ERR_BOOKS_CANNOT_SUBSCRIBE";
   //+------------------------------------------------------------------+
   //| File Operations                                                  |
   //+------------------------------------------------------------------+
   errors[142].code = 5001;
   errors[142].description = "No se pueden abrir más de 64 archivos al mismo tiempo";
   errors[142].constant = "ERR_TOO_MANY_FILES";
   //---
   errors[143].code = 5002;
   errors[143].description = "Nombre de archivo inválido";
   errors[143].constant = "ERR_WRONG_FILENAME";
   //---
   errors[144].code = 5003;
   errors[144].description = "Nombre de archivo demasiado largo";
   errors[144].constant = "ERR_TOO_LONG_FILENAME";
   //---
   errors[145].code = 5004;
   errors[145].description = "Error al abrir el archivo";
   errors[145].constant = "ERR_CANNOT_OPEN_FILE";
   //---
   errors[146].code = 5005;
   errors[146].description = "Memoria caché insuficiente para la lectura";
   errors[146].constant = "ERR_FILE_CACHEBUFFER_ERROR";
   //---
   errors[147].code = 5006;
   errors[147].description = "Error al eliminar el archivo";
   errors[147].constant = "ERR_CANNOT_DELETE_FILE";
   //---
   errors[148].code = 5007;
   errors[148].description = "Un archivo con este handle fue cerrado o simplemente no estaba abierto";
   errors[148].constant = "ERR_INVALID_FILEHANDLE";
   //---
   errors[149].code = 5008;
   errors[149].description = "Handle de archivo incorrecto";
   errors[149].constant = "ERR_WRONG_FILEHANDLE";
   //---
   errors[150].code = 5009;
   errors[150].description = "El archivo debe estar abierto para escritura";
   errors[150].constant = "ERR_FILE_NOTTOWRITE";
   //---
   errors[151].code = 5010;
   errors[151].description = "El archivo debe estar abierto para lectura";
   errors[151].constant = "ERR_FILE_NOTTOREAD";
   //---
   errors[152].code = 5011;
   errors[152].description = "El archivo debe estar abierto como binario";
   errors[152].constant = "ERR_FILE_NOTBIN";
   //---
   errors[153].code = 5012;
   errors[153].description = "El archivo debe estar abierto como texto";
   errors[153].constant = "ERR_FILE_NOTTXT";
   //---
   errors[154].code = 5013;
   errors[154].description = "El archivo debe estar abierto como texto o CSV";
   errors[154].constant = "ERR_FILE_NOTTXTORCSV";
   //---
   errors[155].code = 5014;
   errors[155].description = "El archivo debe estar abierto como CSV";
   errors[155].constant = "ERR_FILE_NOTCSV";
   //---
   errors[156].code = 5015;
   errors[156].description = "Error al leer el archivo";
   errors[156].constant = "ERR_FILE_READERROR";
   //---
   errors[157].code = 5016;
   errors[157].description = "El tamaño de la cadena debe especificarse porque el archivo está abierto como binario";
   errors[157].constant = "ERR_FILE_BINSTRINGSIZE";
   //---
   errors[158].code = 5017;
   errors[158].description = "Se debe usar un archivo de texto para arrays de cadenas, para otros arrays - archivos binarios";
   errors[158].constant = "ERR_INCOMPATIBLE_FILE";
   //---
   errors[159].code = 5018;
   errors[159].description = "Esto no es un archivo, es un directorio";
   errors[159].constant = "ERR_FILE_IS_DIRECTORY";
   //---
   errors[160].code = 5019;
   errors[160].description = "El archivo no existe";
   errors[160].constant = "ERR_FILE_NOT_EXIST";
   //---
   errors[161].code = 5020;
   errors[161].description = "El archivo no puede ser sobrescrito";
   errors[161].constant = "ERR_FILE_CANNOT_REWRITE";
   //---
   errors[162].code = 5021;
   errors[162].description = "Nombre de directorio incorrecto";
   errors[162].constant = "ERR_WRONG_DIRECTORYNAME";
   //---
   errors[163].code = 5022;
   errors[163].description = "El directorio no existe";
   errors[163].constant = "ERR_DIRECTORY_NOT_EXIST";
   //---
   errors[164].code = 5023;
   errors[164].description = "Esto es un archivo, no un directorio";
   errors[164].constant = "ERR_FILE_ISNOT_DIRECTORY";
   //---
   errors[165].code = 5024;
   errors[165].description = "No se puede eliminar el directorio";
   errors[165].constant = "ERR_CANNOT_DELETE_DIRECTORY";
   //---
   errors[166].code = 5025;
   errors[166].description = "Error al limpiar el directorio (probablemente uno o más archivos están bloqueados y la operación de eliminación falló)";
   errors[166].constant = "ERR_CANNOT_CLEAN_DIRECTORY";
   //---
   errors[167].code = 5026;
   errors[167].description = "Error al escribir el recurso en el archivo";
   errors[167].constant = "ERR_FILE_WRITEERROR";
   //---
   errors[168].code = 5027;
   errors[168].description = "Error al leer el siguiente bloque de datos del archivo CSV (FileReadString, FileReadNumber, FileReadDatetime, FileReadBool), porque se alcanzó el final del archivo";
   errors[168].constant = "ERR_FILE_ENDOFFILE";
   //+------------------------------------------------------------------+
   //| String Casting                                                   |
   //+------------------------------------------------------------------+
   errors[169].code = 5030;
   errors[169].description = "Sin fecha en la cadena";
   errors[169].constant = "ERR_NO_STRING_DATE";
   //---
   errors[170].code = 5031;
   errors[170].description = "Fecha incorrecta en la cadena";
   errors[170].constant = "ERR_WRONG_STRING_DATE";
   //---
   errors[171].code = 5032;
   errors[171].description = "Hora incorrecta en la cadena";
   errors[171].constant = "ERR_WRONG_STRING_TIME";
   //---
   errors[172].code = 5033;
   errors[172].description = "Error al convertir la cadena en fecha";
   errors[172].constant = "ERR_STRING_TIME_ERROR";
   //---
   errors[173].code = 5034;
   errors[173].description = "Memoria insuficiente para la cadena";
   errors[173].constant = "ERR_STRING_OUT_OF_MEMORY";
   //---
   errors[174].code = 5035;
   errors[174].description = "La longitud de la cadena es menor que la esperada";
   errors[174].constant = "ERR_STRING_SMALL_LEN";
   //---
   errors[175].code = 5036;
   errors[175].description = "Número demasiado grande, mayor que ULONG_MAX";
   errors[175].constant = "ERR_STRING_TOO_BIGNUMBER";
   //---
   errors[176].code = 5037;
   errors[176].description = "Cadena de formato inválida";
   errors[176].constant = "ERR_WRONG_FORMATSTRING";
   //---
   errors[177].code = 5038;
   errors[177].description = "Cantidad de especificadores de formato mayor que la de parámetros";
   errors[177].constant = "ERR_TOO_MANY_FORMATTERS";
   //---
   errors[178].code = 5039;
   errors[178].description = "Cantidad de parámetros mayor que la de especificadores de formato";
   errors[178].constant = "ERR_TOO_MANY_PARAMETERS";
   //---
   errors[179].code = 5040;
   errors[179].description = "Parámetro de tipo cadena defectuoso";
   errors[179].constant = "ERR_WRONG_STRING_PARAMETER";
   //---
   errors[180].code = 5041;
   errors[180].description = "Posición fuera de la cadena";
   errors[180].constant = "ERR_STRINGPOS_OUTOFRANGE";
   //---
   errors[181].code = 5042;
   errors[181].description = "0 añadido al final de la cadena, operación inútil";
   errors[181].constant = "ERR_STRING_ZEROADDED";
   //---
   errors[182].code = 5043;
   errors[182].description = "Tipo de dato desconocido al convertir a cadena";
   errors[182].constant = "ERR_STRING_UNKNOWNTYPE";
   //---
   errors[183].code = 5044;
   errors[183].description = "Objeto de cadena defectuoso";
   errors[183].constant = "ERR_WRONG_STRING_OBJECT";
   //+------------------------------------------------------------------+
   //| Operations with Arrays                                           |
   //+------------------------------------------------------------------+
   errors[184].code = 5050;
   errors[184].description = "Copiando arrays incompatibles. Un array de cadenas solo puede copiarse a otro array de cadenas y un array numérico solo a otro array numérico";
   errors[184].constant = "ERR_INCOMPATIBLE_ARRAYS";
   //---
   errors[185].code = 5051;
   errors[185].description = "El array de recepción está declarado como AS_SERIES y es de tamaño insuficiente";
   errors[185].constant = "ERR_SMALL_ASSERIES_ARRAY";
   //---
   errors[186].code = 5052;
   errors[186].description = "Array demasiado pequeño, la posición inicial está fuera del array";
   errors[186].constant = "ERR_SMALL_ARRAY";
   //---
   errors[187].code = 5053;
   errors[187].description = "Array de longitud cero";
   errors[187].constant = "ERR_ZEROSIZE_ARRAY";
   //---
   errors[188].code = 5054;
   errors[188].description = "Debe ser un array numérico";
   errors[188].constant = "ERR_NUMBER_ARRAYS_ONLY";
   //---
   errors[189].code = 5055;
   errors[189].description = "Debe ser un array unidimensional";
   errors[189].constant = "ERR_ONE_DIMENSIONAL_ARRAY";
   //---
   errors[190].code = 5056;
   errors[190].description = "No se puede usar series temporales (timeseries)";
   errors[190].constant = "ERR_SERIES_ARRAY";
   //---
   errors[191].code = 5057;
   errors[191].description = "Debe ser un array de tipo double";
   errors[191].constant = "ERR_DOUBLE_ARRAY_ONLY";
   //---
   errors[192].code = 5058;
   errors[192].description = "Debe ser un array de tipo float";
   errors[192].constant = "ERR_FLOAT_ARRAY_ONLY";
   //---
   errors[193].code = 5059;
   errors[193].description = "Debe ser un array de tipo long";
   errors[193].constant = "ERR_LONG_ARRAY_ONLY";
   //---
   errors[194].code = 5060;
   errors[194].description = "Debe ser un array de tipo int";
   errors[194].constant = "ERR_INT_ARRAY_ONLY";
   //---
   errors[195].code = 5061;
   errors[195].description = "Debe ser un array de tipo short";
   errors[195].constant = "ERR_SHORT_ARRAY_ONLY";
   //---
   errors[196].code = 5062;
   errors[196].description = "Debe ser un array de tipo char";
   errors[196].constant = "ERR_CHAR_ARRAY_ONLY";
   //---
   errors[197].code = 5063;
   errors[197].description = "Debe ser un array de tipo string";
   errors[197].constant = "ERR_STRING_ARRAY_ONLY";
   //+------------------------------------------------------------------+
   //| Operations with OpenCL                                           |
   //+------------------------------------------------------------------+
   errors[198].code = 5100;
   errors[198].description = "Las funciones OpenCL no son soportadas en este equipo";
   errors[198].constant = "ERR_OPENCL_NOT_SUPPORTED";
   //---
   errors[199].code = 5101;
   errors[199].description = "Error interno al ejecutar OpenCL";
   errors[199].constant = "ERR_OPENCL_INTERNAL";
   //---
   errors[200].code = 5102;
   errors[200].description = "Handle de OpenCL inválido";
   errors[200].constant = "ERR_OPENCL_INVALID_HANDLE";
   //---
   errors[201].code = 5103;
   errors[201].description = "Error al crear el contexto de OpenCL";
   errors[201].constant = "ERR_OPENCL_CONTEXT_CREATE";
   //---
   errors[202].code = 5104;
   errors[202].description = "Error al crear la cola de ejecución en OpenCL";
   errors[202].constant = "ERR_OPENCL_QUEUE_CREATE";
   //---
   errors[203].code = 5105;
   errors[203].description = "Error al compilar el programa OpenCL";
   errors[203].constant = "ERR_OPENCL_PROGRAM_CREATE";
   //---
   errors[204].code = 5106;
   errors[204].description = "Nombre de kernel demasiado largo (kernel de OpenCL)";
   errors[204].constant = "ERR_OPENCL_TOO_LONG_KERNEL_NAME";
   //---
   errors[205].code = 5107;
   errors[205].description = "Error al crear el kernel de OpenCL";
   errors[205].constant = "ERR_OPENCL_KERNEL_CREATE";
   //---
   errors[206].code = 5108;
   errors[206].description = "Error al establecer parámetros para el kernel de OpenCL";
   errors[206].constant = "ERR_OPENCL_SET_KERNEL_PARAMETER";
   //---
   errors[207].code = 5109;
   errors[207].description = "Error al ejecutar el programa OpenCL";
   errors[207].constant = "ERR_OPENCL_EXECUTE";
   //---
   errors[209].code = 5110;
   errors[209].description = "Tamaño de buffer de OpenCL inválido";
   errors[209].constant = "ERR_OPENCL_WRONG_BUFFER_SIZE";
   //---
   errors[210].code = 5111;
   errors[210].description = "Desplazamiento de buffer de OpenCL inválido";
   errors[210].constant = "ERR_OPENCL_WRONG_BUFFER_OFFSET";
   //---
   errors[211].code = 5112;
   errors[211].description = "Error al crear el buffer de OpenCL";
   errors[211].constant = "ERR_OPENCL_BUFFER_CREATE";
   //---
   errors[212].code = 5113;
   errors[212].description = "Número máximo de objetos OpenCL excedido";
   errors[212].constant = "ERR_OPENCL_TOO_MANY_OBJECTS";
   //---
   errors[213].code = 5114;
   errors[213].description = "Error al seleccionar el dispositivo OpenCL";
   errors[213].constant = "ERR_OPENCL_SELECTDEVICE";
   //+------------------------------------------------------------------+
   //| Working with databases                                           |
   //+------------------------------------------------------------------+
   errors[214].code = 5120;
   errors[214].description = "Error interno de base de datos";
   errors[214].constant = "ERR_DATABASE_INTERNAL";
   //---
   errors[215].code = 5121;
   errors[215].description = "Handle de base de datos inválido";
   errors[215].constant = "ERR_DATABASE_INVALID_HANDLE";
   //---
   errors[216].code = 5122;
   errors[216].description = "Número máximo de objetos de base de datos excedido";
   errors[216].constant = "ERR_DATABASE_TOO_MANY_OBJECTS";
   //---
   errors[217].code = 5123;
   errors[217].description = "Error al conectar con la base de datos";
   errors[217].constant = "ERR_DATABASE_CONNECT";
   //---
   errors[218].code = 5124;
   errors[218].description = "Error al ejecutar la consulta";
   errors[218].constant = "ERR_DATABASE_EXECUTE";
   //---
   errors[219].code = 5125;
   errors[219].description = "Error al crear la consulta";
   errors[219].constant = "ERR_DATABASE_PREPARE";
   //---
   errors[220].code = 5126;
   errors[220].description = "No hay más datos para leer";
   errors[220].constant = "ERR_DATABASE_NO_MORE_DATA";
   //---
   errors[221].code = 5127;
   errors[221].description = "Error al pasar al siguiente registro de la consulta";
   errors[221].constant = "ERR_DATABASE_STEP";
   //---
   errors[222].code = 5128;
   errors[222].description = "Los datos para leer los resultados de la consulta aún no están listos";
   errors[222].constant = "ERR_DATABASE_NOT_READY";
   //---
   errors[223].code = 5129;
   errors[223].description = "Error en la sustitución automática de parámetros en la consulta SQL";
   errors[223].constant = "ERR_DATABASE_BIND_PARAMETERS";
   //+------------------------------------------------------------------+
   //| Operations with WebRequest                                       |
   //+------------------------------------------------------------------+
   errors[224].code = 5200;
   errors[224].description = "URL inválida";
   errors[224].constant = "ERR_WEBREQUEST_INVALID_ADDRESS";
   //---
   errors[225].code = 5201;
   errors[225].description = "Error al conectar con la URL especificada";
   errors[225].constant = "ERR_WEBREQUEST_CONNECT_FAILED";
   //---
   errors[226].code = 5202;
   errors[226].description = "Tiempo de espera excedido";
   errors[226].constant = "ERR_WEBREQUEST_TIMEOUT";
   //---
   errors[227].code = 5203;
   errors[227].description = "Error en la solicitud HTTP";
   errors[227].constant = "ERR_WEBREQUEST_REQUEST_FAILED";
   //+------------------------------------------------------------------+
   //| Operations with network (sockets)                                |
   //+------------------------------------------------------------------+
   errors[228].code = 5270;
   errors[228].description = "Handle de socket inválido pasado a la función";
   errors[228].constant = "ERR_NETSOCKET_INVALIDHANDLE";
   //---
   errors[229].code = 5271;
   errors[229].description = "Demasiados sockets abiertos (máximo 128)";
   errors[229].constant = "ERR_NETSOCKET_TOO_MANY_OPENED";
   //---
   errors[230].code = 5272;
   errors[230].description = "Error al conectar con el host remoto";
   errors[230].constant = "ERR_NETSOCKET_CANNOT_CONNECT";
   //---
   errors[231].code = 5273;
   errors[231].description = "Error al enviar/recibir datos por socket";
   errors[231].constant = "ERR_NETSOCKET_IO_ERROR";
   //---
   errors[232].code = 5274;
   errors[232].description = "Error al establecer conexión segura (TLS Handshake)";
   errors[232].constant = "ERR_NETSOCKET_HANDSHAKE_FAILED";
   //---
   errors[233].code = 5275;
   errors[233].description = "No hay información sobre el certificado que protege la conexión";
   errors[233].constant = "ERR_NETSOCKET_NO_CERTIFICATE";
   //+------------------------------------------------------------------+
   //| Custom Symbols                                                   |
   //+------------------------------------------------------------------+
   errors[234].code = 5300;
   errors[234].description = "Debe especificarse el símbolo personalizado";
   errors[234].constant = "ERR_NOT_CUSTOM_SYMBOL";
   //---
   errors[235].code = 5301;
   errors[235].description = "Nombre de símbolo personalizado incorrecto. Solo se permiten caracteres latinos sin puntuación, espacios ni caracteres especiales en el nombre del símbolo (se permiten '.', '_', '&' y '#'). No se recomienda usar <, >, :, ', /, |, ?, *";
   errors[235].constant = "ERR_CUSTOM_SYMBOL_WRONG_NAME";
   //---
   errors[236].code = 5302;
   errors[236].description = "Nombre demasiado largo para el símbolo personalizado. El nombre no debe exceder 32 caracteres incluyendo el 0 final";
   errors[236].constant = "ERR_CUSTOM_SYMBOL_NAME_LONG";
   //---
   errors[237].code = 5303;
   errors[237].description = "Ruta demasiado larga para el símbolo personalizado. La ruta no debe exceder 128 caracteres incluyendo 'Custom\\', el nombre del símbolo, separadores de grupo y el 0 final";
   errors[237].constant = "ERR_CUSTOM_SYMBOL_PATH_LONG";
   //---
   errors[238].code = 5304;
   errors[238].description = "Ya existe un símbolo personalizado con este nombre";
   errors[238].constant = "ERR_CUSTOM_SYMBOL_EXIST";
   //---
   errors[239].code = 5305;
   errors[239].description = "Error al crear, eliminar o modificar el símbolo personalizado";
   errors[239].constant = "ERR_CUSTOM_SYMBOL_ERROR";
   //---
   errors[240].code = 5306;
   errors[240].description = "Intento de eliminar un símbolo personalizado seleccionado en Observación de Mercado";
   errors[240].constant = "ERR_CUSTOM_SYMBOL_SELECTED";
   //---
   errors[241].code = 5307;
   errors[241].description = "Propiedad de símbolo personalizado incorrecta";
   errors[241].constant = "ERR_CUSTOM_SYMBOL_PROPERTY_WRONG";
   //---
   errors[242].code = 5308;
   errors[242].description = "Parámetro incorrecto al establecer propiedad de símbolo personalizado";
   errors[242].constant = "ERR_CUSTOM_SYMBOL_PARAMETER_ERROR";
   //---
   errors[243].code = 5309;
   errors[243].description = "Cadena de parámetro demasiado larga al establecer propiedad de símbolo personalizado";
   errors[243].constant = "ERR_CUSTOM_SYMBOL_PARAMETER_LONG";
   //---
   errors[244].code = 5310;
   errors[244].description = "Array de ticks no ordenado por tiempo";
   errors[244].constant = "ERR_CUSTOM_TICKS_WRONG_ORDER";
   //+------------------------------------------------------------------+
   //| Economic Calendar                                                |
   //+------------------------------------------------------------------+
   errors[245].code = 5400;
   errors[245].description = "Tamaño de array insuficiente para obtener descripciones de todos los valores";
   errors[245].constant = "ERR_CALENDAR_MORE_DATA";
   //---
   errors[246].code = 5401;
   errors[246].description = "Límite de tiempo de solicitud excedido";
   errors[246].constant = "ERR_CALENDAR_TIMEOUT";
   //---
   errors[247].code = 5402;
   errors[247].description = "País no encontrado";
   errors[247].constant = "ERR_CALENDAR_NO_DATA";
   //+------------------------------------------------------------------+
   //| Working with databases                                           |
   //+------------------------------------------------------------------+
   errors[248].code = 5601;
   errors[248].description = "Error general";
   errors[248].constant = "ERR_DATABASE_ERROR";
   //---
   errors[249].code = 5602;
   errors[249].description = "Error lógico interno de SQLite";
   errors[249].constant = "ERR_DATABASE_INTERNAL";
   //---
   errors[250].code = 5603;
   errors[250].description = "Acceso denegado";
   errors[250].constant = "ERR_DATABASE_PERM";
   //---
   errors[251].code = 5604;
   errors[251].description = "Rutina de devolución de llamada solicitó abortar";
   errors[251].constant = "ERR_DATABASE_ABORT";
   //---
   errors[252].code = 5605;
   errors[252].description = "Archivo de base de datos bloqueado";
   errors[252].constant = "ERR_DATABASE_BUSY";
   //---
   errors[253].code = 5606;
   errors[253].description = "Tabla de base de datos bloqueada";
   errors[253].constant = "ERR_DATABASE_LOCKED";
   //---
   errors[254].code = 5607;
   errors[254].description = "Memoria insuficiente para completar la operación";
   errors[254].constant = "ERR_DATABASE_NOMEM";
   //---
   errors[255].code = 5608;
   errors[255].description = "Intento de escribir en base de datos de solo lectura";
   errors[255].constant = "ERR_DATABASE_READONLY";
   //---
   errors[256].code = 5609;
   errors[256].description = "Operación terminada por sqlite3_interrupt()";
   errors[256].constant = "ERR_DATABASE_INTERRUPT";
   //---
   errors[257].code = 5610;
   errors[257].description = "Error de E/S de disco";
   errors[257].constant = "ERR_DATABASE_IOERR";
   //---
   errors[258].code = 5611;
   errors[258].description = "Imagen de disco de base de datos dañada";
   errors[258].constant = "ERR_DATABASE_CORRUPT";
   //---
   errors[259].code = 5612;
   errors[259].description = "Código de operación desconocido en sqlite3_file_control()";
   errors[259].constant = "ERR_DATABASE_NOTFOUND";
   //---
   errors[260].code = 5613;
   errors[260].description = "La inserción falló porque la base de datos está llena";
   errors[260].constant = "ERR_DATABASE_FULL";
   //---
   errors[261].code = 5614;
   errors[261].description = "No se puede abrir el archivo de base de datos";
   errors[261].constant = "ERR_DATABASE_CANTOPEN";
   //---
   errors[262].code = 5615;
   errors[262].description = "Error de protocolo de bloqueo de base de datos";
   errors[262].constant = "ERR_DATABASE_PROTOCOL";
   //---
   errors[263].code = 5616;
   errors[263].description = "Solo para uso interno";
   errors[263].constant = "ERR_DATABASE_EMPTY";
   //---
   errors[264].code = 5617;
   errors[264].description = "Esquema de base de datos cambiado";
   errors[264].constant = "ERR_DATABASE_SCHEMA";
   //---
   errors[265].code = 5618;
   errors[265].description = "Cadena o BLOB excede el límite de tamaño";
   errors[265].constant = "ERR_DATABASE_TOOBIG";
   //---
   errors[266].code = 5619;
   errors[266].description = "Abortar debido a violación de restricción";
   errors[266].constant = "ERR_DATABASE_CONSTRAINT";
   //---
   errors[267].code = 5620;
   errors[267].description = "Incompatibilidad de tipo de datos";
   errors[267].constant = "ERR_DATABASE_MISMATCH";
   //---
   errors[268].code = 5621;
   errors[268].description = "Biblioteca usada incorrectamente";
   errors[268].constant = "ERR_DATABASE_MISUSE";
   //---
   errors[269].code = 5622;
   errors[269].description = "Utiliza recursos del SO no soportados en el host";
   errors[269].constant = "ERR_DATABASE_NOLFS";
   //---
   errors[270].code = 5623;
   errors[270].description = "Autorización denegada";
   errors[270].constant = "ERR_DATABASE_AUTH";
   //---
   errors[271].code = 5624;
   errors[271].description = "No usado";
   errors[271].constant = "ERR_DATABASE_FORMAT";
   //---
   errors[272].code = 5625;
   errors[272].description = "Error de vinculación de parámetro, índice incorrecto";
   errors[272].constant = "ERR_DATABASE_RANGE";
   //---
   errors[273].code = 5626;
   errors[273].description = "El archivo abierto no es un archivo de base de datos";
   errors[273].constant = "ERR_DATABASE_NOTADB";
  }
//+------------------------------------------------------------------+

