//+------------------------------------------------------------------+
//|                                             ErrorMessages.it.mqh |
//|                                                     joaopedrodev |
//|                       https://www.mql5.com/en/users/joaopedrodev |
//+------------------------------------------------------------------+
#property copyright "joaopedrodev"
#property link      "https://www.mql5.com/en/users/joaopedrodev"
//+------------------------------------------------------------------+
//| Import struct                                                    
//+------------------------------------------------------------------+
#include "../Error.mqh"
void InitializeErrorsItalian(MqlError &errors[])
  {
   //--- Free and resize
   ArrayFree(errors);
   ArrayResize(errors,274);
   
   //+------------------------------------------------------------------+
   //| Unknown error                                                    |
   //+------------------------------------------------------------------+
   errors[0].code = 0;
   errors[0].description = "Nessun errore trovato";
   errors[0].constant = "ERROR_UNKNOWN";
   //+------------------------------------------------------------------+
   //| Server error                                                     |
   //+------------------------------------------------------------------+
   errors[1].code = 10004;
   errors[1].description = "Nuova quotazione";
   errors[1].constant = "TRADE_RETCODE_REQUOTE";
   //---
   errors[2].code = 10006;
   errors[2].description = "Richiesta rifiutata";
   errors[2].constant = "TRADE_RETCODE_REJECT";
   //---
   errors[3].code = 10007;
   errors[3].description = "Richiesta annullata dall'operatore";
   errors[3].constant = "TRADE_RETCODE_CANCEL";
   //---
   errors[4].code = 10008;
   errors[4].description = "Ordine inserito";
   errors[4].constant = "TRADE_RETCODE_PLACED";
   //---
   errors[5].code = 10009;
   errors[5].description = "Richiesta completata";
   errors[5].constant = "TRADE_RETCODE_DONE";
   //---
   errors[6].code = 10010;
   errors[6].description = "Solo parte della richiesta è stata completata";
   errors[6].constant = "TRADE_RETCODE_DONE_PARTIAL";
   //---
   errors[7].code = 10011;
   errors[7].description = "Errore nell'elaborazione della richiesta";
   errors[7].constant = "TRADE_RETCODE_ERROR";
   //---
   errors[8].code = 10012;
   errors[8].description = "Richiesta annullata per timeout";
   errors[8].constant = "TRADE_RETCODE_TIMEOUT";
   //---
   errors[9].code = 10013;
   errors[9].description = "Richiesta non valida";
   errors[9].constant = "TRADE_RETCODE_INVALID";
   //---
   errors[10].code = 10014;
   errors[10].description = "Volume non valido nella richiesta";
   errors[10].constant = "TRADE_RETCODE_INVALID_VOLUME";
   //---
   errors[11].code = 10015;
   errors[11].description = "Prezzo non valido nella richiesta";
   errors[11].constant = "TRADE_RETCODE_INVALID_PRICE";
   //---
   errors[12].code = 10016;
   errors[12].description = "Stop non validi nella richiesta";
   errors[12].constant = "TRADE_RETCODE_INVALID_STOPS";
   //---
   errors[13].code = 10017;
   errors[13].description = "Trading disabilitato";
   errors[13].constant = "TRADE_RETCODE_TRADE_DISABLED";
   //---
   errors[14].code = 10018;
   errors[14].description = "Mercato chiuso";
   errors[14].constant = "TRADE_RETCODE_MARKET_CLOSED";
   //---
   errors[15].code = 10019;
   errors[15].description = "Fondi insufficienti per completare la richiesta";
   errors[15].constant = "TRADE_RETCODE_NO_MONEY";
   //---
   errors[16].code = 10020;
   errors[16].description = "I prezzi sono cambiati";
   errors[16].constant = "TRADE_RETCODE_PRICE_CHANGED";
   //---
   errors[17].code = 10021;
   errors[17].description = "Nessuna quotazione per elaborare la richiesta";
   errors[17].constant = "TRADE_RETCODE_PRICE_OFF";
   //---
   errors[18].code = 10022;
   errors[18].description = "Data di scadenza dell'ordine non valida nella richiesta";
   errors[18].constant = "TRADE_RETCODE_INVALID_EXPIRATION";
   //---
   errors[19].code = 10023;
   errors[19].description = "Stato dell'ordine modificato";
   errors[19].constant = "TRADE_RETCODE_ORDER_CHANGED";
   //---
   errors[20].code = 10024;
   errors[20].description = "Troppe richieste";
   errors[20].constant = "TRADE_RETCODE_TOO_MANY_REQUESTS";
   //---
   errors[21].code = 10025;
   errors[21].description = "Nessuna modifica nella richiesta";
   errors[21].constant = "TRADE_RETCODE_NO_CHANGES";
   //---
   errors[22].code = 10026;
   errors[22].description = "Trading automatico disabilitato dal server";
   errors[22].constant = "TRADE_RETCODE_SERVER_DISABLES_AT";
   //---
   errors[23].code = 10027;
   errors[23].description = "Trading automatico disabilitato dal terminale client";
   errors[23].constant = "TRADE_RETCODE_CLIENT_DISABLES_AT";
   //---
   errors[24].code = 10028;
   errors[24].description = "Richiesta bloccata per l'elaborazione";
   errors[24].constant = "TRADE_RETCODE_LOCKED";
   //---
   errors[25].code = 10029;
   errors[25].description = "Ordine o posizione congelati";
   errors[25].constant = "TRADE_RETCODE_FROZEN";
   //---
   errors[26].code = 10030;
   errors[26].description = "Tipo di esecuzione ordine non valido";
   errors[26].constant = "TRADE_RETCODE_INVALID_FILL";
   //---
   errors[27].code = 10031;
   errors[27].description = "Nessuna connessione al server di trading";
   errors[27].constant = "TRADE_RETCODE_CONNECTION";
   //---
   errors[28].code = 10032;
   errors[28].description = "Operazione consentita solo per conti reali";
   errors[28].constant = "TRADE_RETCODE_ONLY_REAL";
   //---
   errors[29].code = 10033;
   errors[29].description = "Il numero di ordini pendenti ha raggiunto il limite";
   errors[29].constant = "TRADE_RETCODE_LIMIT_ORDERS";
   //---
   errors[30].code = 10034;
   errors[30].description = "Il volume di ordini e posizioni per il simbolo ha raggiunto il limite";
   errors[30].constant = "TRADE_RETCODE_LIMIT_VOLUME";
   //---
   errors[31].code = 10035;
   errors[31].description = "Tipo di ordine errato o proibito";
   errors[31].constant = "TRADE_RETCODE_INVALID_ORDER";
   //---
   errors[32].code = 10036;
   errors[32].description = "La posizione con l'identificativo specificato è già stata chiusa";
   errors[32].constant = "TRADE_RETCODE_POSITION_CLOSED";
   //---
   errors[33].code = 10038;
   errors[33].description = "Il volume da chiudere supera il volume della posizione attuale";
   errors[33].constant = "TRADE_RETCODE_INVALID_CLOSE_VOLUME";
   //---
   errors[34].code = 10039;
   errors[34].description = "Vedi documentazione";
   errors[34].constant = "TRADE_RETCODE_CLOSE_ORDER_EXIST";
   //---
   errors[35].code = 10040;
   errors[35].description = "Vedi documentazione";
   errors[35].constant = "TRADE_RETCODE_LIMIT_POSITIONS";
   //---
   errors[36].code = 10041;
   errors[36].description = "La richiesta di attivazione dell'ordine pendente è stata rifiutata e l'ordine annullato";
   errors[36].constant = "TRADE_RETCODE_REJECT_CANCEL";
   //---
   errors[37].code = 10042;
   errors[37].description = "Ordine rifiutato perché il simbolo è impostato su 'Solo posizioni long' (POSITION_TYPE_BUY)";
   errors[37].constant = "TRADE_RETCODE_LONG_ONLY";
   //---
   errors[38].code = 10043;
   errors[38].description = "Ordine rifiutato perché il simbolo è impostato su 'Solo posizioni short' (POSITION_TYPE_SELL)";
   errors[38].constant = "TRADE_RETCODE_SHORT_ONLY";
   //---
   errors[39].code = 10044;
   errors[39].description = "Ordine rifiutato perché il simbolo è impostato su 'Solo chiusura'";
   errors[39].constant = "TRADE_RETCODE_CLOSE_ONLY";
   //---
   errors[40].code = 10045;
   errors[40].description = "Ordine rifiutato perché il simbolo è impostato su 'Solo chiusura'";
   errors[40].constant = "TRADE_RETCODE_FIFO_CLOSE";
   //---
   errors[41].code = 10046;
   errors[41].description = "Ordine rifiutato perché il simbolo è impostato su 'Vietato aprire posizioni opposte sullo stesso simbolo'";
   errors[41].constant = "TRADE_RETCODE_HEDGE_PROHIBITED";
   //+------------------------------------------------------------------+
   //| Errors sistem                                                    |
   //+------------------------------------------------------------------+
   errors[42].code = 4001;
   errors[42].description = "Errore interno inatteso";
   errors[42].constant = "ERR_INTERNAL_ERROR";
   //---
   errors[43].code = 4002;
   errors[43].description = "Parametro errato nella chiamata interna della funzione del terminale client";
   errors[43].constant = "ERR_WRONG_INTERNAL_PARAMETER";
   //---
   errors[44].code = 4003;
   errors[44].description = "Parametro errato nella chiamata della funzione di sistema";
   errors[44].constant = "ERR_INVALID_PARAMETER";
   //---
   errors[45].code = 4004;
   errors[45].description = "Memoria insufficiente per eseguire la funzione di sistema";
   errors[45].constant = "ERR_NOT_ENOUGH_MEMORY";
   //---
   errors[46].code = 4005;
   errors[46].description = "La struttura contiene oggetti stringa e/o array dinamici e/o strutture di tali oggetti e/o classi";
   errors[46].constant = "ERR_STRUCT_WITHOBJECTS_ORCLASS";
   //---
   errors[47].code = 4006;
   errors[47].description = "Array di tipo errato, dimensione errata o oggetto difettoso di un array dinamico";
   errors[47].constant = "ERR_INVALID_ARRAY";
   //---
   errors[48].code = 4007;
   errors[48].description = "Memoria insufficiente per riallocare un array o tentativo di cambiare la dimensione di un array statico";
   errors[48].constant = "ERR_ARRAY_RESIZE_ERROR";
   //---
   errors[49].code = 4008;
   errors[49].description = "Memoria insufficiente per riallocare la stringa";
   errors[49].constant = "ERR_STRING_RESIZE_ERROR";
   //---
   errors[50].code = 4009;
   errors[50].description = "Stringa non inizializzata";
   errors[50].constant = "ERR_NOTINITIALIZED_STRING";
   //---
   errors[51].code = 4010;
   errors[51].description = "Data e/o ora non valida";
   errors[51].constant = "ERR_INVALID_DATETIME";
   //---
   errors[52].code = 4011;
   errors[52].description = "Il numero totale di elementi nell'array non può superare 2147483647";
   errors[52].constant = "ERR_ARRAY_BAD_SIZE";
   //---
   errors[53].code = 4012;
   errors[53].description = "Puntatore errato";
   errors[53].constant = "ERR_INVALID_POINTER";
   //---
   errors[54].code = 4013;
   errors[54].description = "Tipo di puntatore errato";
   errors[54].constant = "ERR_INVALID_POINTER_TYPE";
   //---
   errors[55].code = 4014;
   errors[55].description = "Funzione di sistema non consentita per la chiamata";
   errors[55].constant = "ERR_FUNCTION_NOT_ALLOWED";
   //---
   errors[56].code = 4015;
   errors[56].description = "I nomi delle risorse dinamiche e statiche sono uguali";
   errors[56].constant = "ERR_RESOURCE_NAME_DUPLICATED";
   //---
   errors[57].code = 4016;
   errors[57].description = "Risorsa con questo nome non trovata in EX5";
   errors[57].constant = "ERR_RESOURCE_NOT_FOUND";
   //---
   errors[58].code = 4017;
   errors[58].description = "Tipo di risorsa non supportato o dimensione superiore a 16 MB";
   errors[58].constant = "ERR_RESOURCE_UNSUPPOTED_TYPE";
   //---
   errors[59].code = 4018;
   errors[59].description = "Il nome della risorsa supera i 63 caratteri";
   errors[59].constant = "ERR_RESOURCE_NAME_IS_TOO_LONG";
   //---
   errors[60].code = 4019;
   errors[60].description = "Overflow durante il calcolo di funzioni matematiche";
   errors[60].constant = "ERR_MATH_OVERFLOW";
   //---
   errors[61].code = 4020;
   errors[61].description = "Fine del test superata dopo la chiamata a Sleep()";
   errors[61].constant = "ERR_SLEEP_ERROR";
   //---
   errors[62].code = 4022;
   errors[62].description = "I test sono stati interrotti forzatamente dall'esterno. Ad esempio, interrompendo l'ottimizzazione, chiudendo la finestra di test visivo o fermando l'agente di test";
   errors[62].constant = "ERR_STOPPED";
   //+------------------------------------------------------------------+
   //| Charts                                                           |
   //+------------------------------------------------------------------+
   errors[63].code = 4101;
   errors[63].description = "Identificativo grafico (chart ID) errato";
   errors[63].constant = "ERR_CHART_WRONG_ID";
   //---
   errors[64].code = 4102;
   errors[64].description = "Grafico non risponde";
   errors[64].constant = "ERR_CHART_NO_REPLY";
   //---
   errors[65].code = 4103;
   errors[65].description = "Grafico non trovato";
   errors[65].constant = "ERR_CHART_NOT_FOUND";
   //---
   errors[66].code = 4104;
   errors[66].description = "Nessun Expert Advisor sul grafico che possa gestire l'evento";
   errors[66].constant = "ERR_CHART_NO_EXPERT";
   //---
   errors[67].code = 4105;
   errors[67].description = "Errore di apertura del grafico";
   errors[67].constant = "ERR_CHART_CANNOT_OPEN";
   //---
   errors[68].code = 4106;
   errors[68].description = "Impossibile cambiare simbolo e periodo del grafico";
   errors[68].constant = "ERR_CHART_CANNOT_CHANGE";
   //---
   errors[69].code = 4107;
   errors[69].description = "Valore errato del parametro per la funzione che lavora con i grafici";
   errors[69].constant = "ERR_CHART_WRONG_PARAMETER";
   //---
   errors[70].code = 4108;
   errors[70].description = "Impossibile creare il timer";
   errors[70].constant = "ERR_CHART_CANNOT_CREATE_TIMER";
   //---
   errors[71].code = 4109;
   errors[71].description = "Identificativo di proprietà (property ID) del grafico errato";
   errors[71].constant = "ERR_CHART_WRONG_PROPERTY";
   //---
   errors[72].code = 4110;
   errors[72].description = "Errore nella creazione dello screenshot";
   errors[72].constant = "ERR_CHART_SCREENSHOT_FAILED";
   //---
   errors[73].code = 4111;
   errors[73].description = "Errore nella navigazione del grafico";
   errors[73].constant = "ERR_CHART_NAVIGATE_FAILED";
   //---
   errors[74].code = 4112;
   errors[74].description = "Errore nell'applicazione del template";
   errors[74].constant = "ERR_CHART_TEMPLATE_FAILED";
   //---
   errors[75].code = 4113;
   errors[75].description = "Sottofinestra contenente l'indicatore non trovata";
   errors[75].constant = "ERR_CHART_WINDOW_NOT_FOUND";
   //---
   errors[76].code = 4114;
   errors[76].description = "Errore nell'aggiunta di un indicatore al grafico";
   errors[76].constant = "ERR_CHART_INDICATOR_CANNOT_ADD";
   //---
   errors[77].code = 4115;
   errors[77].description = "Errore nell'eliminazione di un indicatore dal grafico";
   errors[77].constant = "ERR_CHART_INDICATOR_CANNOT_DEL";
   //---
   errors[78].code = 4116;
   errors[78].description = "Indicatore non trovato sul grafico specificato";
   errors[78].constant = "ERR_CHART_INDICATOR_NOT_FOUND";
   //+------------------------------------------------------------------+
   //| Graphical Objects                                                |
   //+------------------------------------------------------------------+
   errors[79].code = 4201;
   errors[79].description = "Errore nella gestione di un oggetto grafico";
   errors[79].constant = "ERR_OBJECT_ERROR";
   //---
   errors[80].code = 4202;
   errors[80].description = "Oggetto grafico non trovato";
   errors[80].constant = "ERR_OBJECT_NOT_FOUND";
   //---
   errors[81].code = 4203;
   errors[81].description = "Identificativo (ID) di proprietà dell'oggetto grafico errato";
   errors[81].constant = "ERR_OBJECT_WRONG_PROPERTY";
   //---
   errors[82].code = 4204;
   errors[82].description = "Impossibile ottenere la data corrispondente al valore";
   errors[82].constant = "ERR_OBJECT_GETDATE_FAILED";
   //---
   errors[83].code = 4205;
   errors[83].description = "Impossibile ottenere il valore corrispondente alla data";
   errors[83].constant = "ERR_OBJECT_GETVALUE_FAILED";
   //+------------------------------------------------------------------+
   //| MarketInfo                                                       |
   //+------------------------------------------------------------------+
   errors[84].code = 4301;
   errors[84].description = "Simbolo sconosciuto";
   errors[84].constant = "ERR_MARKET_UNKNOWN_SYMBOL";
   //---
   errors[85].code = 4302;
   errors[85].description = "Simbolo non selezionato nella finestra Market Watch";
   errors[85].constant = "ERR_MARKET_NOT_SELECTED";
   //---
   errors[86].code = 4303;
   errors[86].description = "Identificativo di proprietà del simbolo errato";
   errors[86].constant = "ERR_MARKET_WRONG_PROPERTY";
   //---
   errors[87].code = 4304;
   errors[87].description = "Orario dell'ultimo tick sconosciuto (nessun tick)";
   errors[87].constant = "ERR_MARKET_LASTTIME_UNKNOWN";
   //---
   errors[88].code = 4305;
   errors[88].description = "Errore nell'aggiunta o rimozione di un simbolo nella finestra Market Watch";
   errors[88].constant = "ERR_MARKET_SELECT_ERROR";
   //+------------------------------------------------------------------+
   //| History Access                                                   |
   //+------------------------------------------------------------------+
   errors[89].code = 4401;
   errors[89].description = "Storico richiesto non trovato";
   errors[89].constant = "ERR_HISTORY_NOT_FOUND";
   //---
   errors[90].code = 4402;
   errors[90].description = "Identificativo (ID) di proprietà dello storico errato";
   errors[90].constant = "ERR_HISTORY_WRONG_PROPERTY";
   //---
   errors[91].code = 4403;
   errors[91].description = "Timeout della richiesta dello storico";
   errors[91].constant = "ERR_HISTORY_TIMEOUT";
   //---
   errors[92].code = 4404;
   errors[92].description = "Numero di barre limitato dalle impostazioni del terminale";
   errors[92].constant = "ERR_HISTORY_BARS_LIMIT";
   //---
   errors[93].code = 4405;
   errors[93].description = "Errori multipli durante il caricamento dello storico";
   errors[93].constant = "ERR_HISTORY_LOAD_ERRORS";
   //---
   errors[94].code = 4407;
   errors[94].description = "L'array di ricezione è troppo piccolo per memorizzare tutti i dati richiesti";
   errors[94].constant = "ERR_HISTORY_SMALL_BUFFER";
   //+------------------------------------------------------------------+
   //| Global Variables                                                 |
   //+------------------------------------------------------------------+
   errors[95].code = 4501;
   errors[95].description = "Variabile globale del terminale client non trovata";
   errors[95].constant = "ERR_GLOBALVARIABLE_NOT_FOUND";
   //---
   errors[96].code = 4502;
   errors[96].description = "Variabile globale del terminale client con lo stesso nome già esistente";
   errors[96].constant = "ERR_GLOBALVARIABLE_EXISTS";
   //---
   errors[97].code = 4503;
   errors[97].description = "Nessuna modifica delle variabili globali";
   errors[97].constant = "ERR_GLOBALVARIABLE_NOT_MODIFIED";
   //---
   errors[98].code = 4504;
   errors[98].description = "Impossibile aprire e leggere il file con i valori delle variabili globali";
   errors[98].constant = "ERR_GLOBALVARIABLE_CANNOTREAD";
   //---
   errors[99].code = 4505;
   errors[99].description = "Impossibile scrivere il file con i valori delle variabili globali";
   errors[99].constant = "ERR_GLOBALVARIABLE_CANNOTWRITE";
   //---
   errors[100].code = 4510;
   errors[100].description = "Invio email fallito";
   errors[100].constant = "ERR_MAIL_SEND_FAILED";
   //---
   errors[101].code = 4511;
   errors[101].description = "Riproduzione audio fallita";
   errors[101].constant = "ERR_PLAY_SOUND_FAILED";
   //---
   errors[102].code = 4512;
   errors[102].description = "Identificativo di proprietà del programma errato";
   errors[102].constant = "ERR_MQL5_WRONG_PROPERTY";
   //---
   errors[103].code = 4513;
   errors[103].description = "Identificativo di proprietà del terminale errato";
   errors[103].constant = "ERR_TERMINAL_WRONG_PROPERTY";
   //---
   errors[104].code = 4514;
   errors[104].description = "Invio file via FTP fallito";
   errors[104].constant = "ERR_FTP_SEND_FAILED";
   //---
   errors[105].code = 4515;
   errors[105].description = "Invio notifica fallito";
   errors[105].constant = "ERR_NOTIFICATION_SEND_FAILED";
   //---
   errors[106].code = 4516;
   errors[106].description = "Parametro non valido per l'invio di una notifica – è stata passata una stringa vuota o NULL alla funzione SendNotification()";
   errors[106].constant = "ERR_NOTIFICATION_WRONG_PARAMETER";
   //---
   errors[107].code = 4517;
   errors[107].description = "Impostazioni di notifica errate nel terminale (ID non specificato o autorizzazione non impostata)";
   errors[107].constant = "ERR_NOTIFICATION_WRONG_SETTINGS";
   //---
   errors[108].code = 4518;
   errors[108].description = "Frequenza di invio notifiche eccessiva";
   errors[108].constant = "ERR_NOTIFICATION_TOO_FREQUENT";
   //---
   errors[109].code = 4519;
   errors[109].description = "Server FTP non specificato negli attributi di configurazione";
   errors[109].constant = "ERR_FTP_NOSERVER";
   //---
   errors[110].code = 4520;
   errors[110].description = "Login FTP non specificato negli attributi di configurazione";
   errors[110].constant = "ERR_FTP_NOLOGIN";
   //---
   errors[111].code = 4521;
   errors[111].description = "File non esistente";
   errors[111].constant = "ERR_FTP_FILE_ERROR";
   //---
   errors[112].code = 4522;
   errors[112].description = "Connessione al server FTP fallita";
   errors[112].constant = "ERR_FTP_CONNECT_FAILED";
   //---
   errors[113].code = 4523;
   errors[113].description = "Cartella non trovata sul server FTP per il caricamento del file";
   errors[113].constant = "ERR_FTP_CHANGEDIR";
   //---
   errors[114].code = 4524;
   errors[114].description = "Connessione al server FTP chiusa";
   errors[114].constant = "ERR_FTP_CLOSED";
   //+------------------------------------------------------------------+
   //| Custom Indicator Buffers                                         |
   //+------------------------------------------------------------------+
   errors[115].code = 4601;
   errors[115].description = "Memoria insufficiente per l'allocazione dei buffer dell'indicatore";
   errors[115].constant = "ERR_BUFFERS_NO_MEMORY";
   //---
   errors[116].code = 4602;
   errors[116].description = "Indice del buffer dell'indicatore errato";
   errors[116].constant = "ERR_BUFFERS_WRONG_INDEX";
   //+------------------------------------------------------------------+
   //| Custom Indicator Properties                                      |
   //+------------------------------------------------------------------+
   errors[117].code = 4603;
   errors[117].description = "Identificativo (ID) di proprietà dell'indicatore personalizzato errato";
   errors[117].constant = "ERR_CUSTOM_WRONG_PROPERTY";
   //+------------------------------------------------------------------+
   //| Account                                                          |
   //+------------------------------------------------------------------+
   errors[118].code = 4701;
   errors[118].description = "Identificativo (ID) di proprietà del conto errato";
   errors[118].constant = "ERR_ACCOUNT_WRONG_PROPERTY";
   //---
   errors[119].code = 4751;
   errors[119].description = "Identificativo (ID) di proprietà della negoziazione errato";
   errors[119].constant = "ERR_TRADE_WRONG_PROPERTY";
   //---
   errors[120].code = 4752;
   errors[120].description = "Negoziazione tramite Expert Advisors vietata";
   errors[120].constant = "ERR_TRADE_DISABLED";
   //---
   errors[121].code = 4753;
   errors[121].description = "Posizione non trovata";
   errors[121].constant = "ERR_TRADE_POSITION_NOT_FOUND";
   //---
   errors[122].code = 4754;
   errors[122].description = "Ordine non trovato";
   errors[122].constant = "ERR_TRADE_ORDER_NOT_FOUND";
   //---
   errors[123].code = 4755;
   errors[123].description = "Operazione (deal) non trovata";
   errors[123].constant = "ERR_TRADE_DEAL_NOT_FOUND";
   //---
   errors[124].code = 4756;
   errors[124].description = "Invio richiesta di negoziazione fallito";
   errors[124].constant = "ERR_TRADE_SEND_FAILED";
   //---
   errors[125].code = 4758;
   errors[125].description = "Impossibile calcolare il valore dell'indice di negoziazione";
   errors[125].constant = "ERR_TRADE_CALC_FAILED";
   //+------------------------------------------------------------------+
   //| Indicators                                                       |
   //+------------------------------------------------------------------+
   errors[126].code = 4801;
   errors[126].description = "Simbolo sconosciuto";
   errors[126].constant = "ERR_INDICATOR_UNKNOWN_SYMBOL";
   //---
   errors[127].code = 4802;
   errors[127].description = "Impossibile creare l'indicatore";
   errors[127].constant = "ERR_INDICATOR_CANNOT_CREATE";
   //---
   errors[128].code = 4803;
   errors[128].description = "Memoria insufficiente per aggiungere l'indicatore";
   errors[128].constant = "ERR_INDICATOR_NO_MEMORY";
   //---
   errors[129].code = 4804;
   errors[129].description = "Impossibile applicare l'indicatore a un altro indicatore";
   errors[129].constant = "ERR_INDICATOR_CANNOT_APPLY";
   //---
   errors[130].code = 4805;
   errors[130].description = "Errore nell'applicazione di un indicatore al grafico";
   errors[130].constant = "ERR_INDICATOR_CANNOT_ADD";
   //---
   errors[131].code = 4806;
   errors[131].description = "Dati richiesti non trovati";
   errors[131].constant = "ERR_INDICATOR_DATA_NOT_FOUND";
   //---
   errors[132].code = 4807;
   errors[132].description = "Gestione dell'indicatore errata";
   errors[132].constant = "ERR_INDICATOR_WRONG_HANDLE";
   //---
   errors[133].code = 4808;
   errors[133].description = "Numero errato di parametri nella creazione di un indicatore";
   errors[133].constant = "ERR_INDICATOR_WRONG_PARAMETERS";
   //---
   errors[134].code = 4809;
   errors[134].description = "Nessun parametro nella creazione di un indicatore";
   errors[134].constant = "ERR_INDICATOR_PARAMETERS_MISSING";
   //---
   errors[135].code = 4810;
   errors[135].description = "Il primo parametro nell'array deve essere il nome dell'indicatore personalizzato";
   errors[135].constant = "ERR_INDICATOR_CUSTOM_NAME";
   //---
   errors[136].code = 4811;
   errors[136].description = "Tipo di parametro non valido nell'array durante la creazione di un indicatore";
   errors[136].constant = "ERR_INDICATOR_PARAMETER_TYPE";
   //---
   errors[137].code = 4812;
   errors[137].description = "Indice errato del buffer dell'indicatore richiesto";
   errors[137].constant = "ERR_INDICATOR_WRONG_INDEX";
   //+------------------------------------------------------------------+
   //| Depth of Market                                                  |
   //+------------------------------------------------------------------+
   errors[138].code = 4901;
   errors[138].description = "Depth of Market non può essere aggiunto";
   errors[138].constant = "ERR_BOOKS_CANNOT_ADD";
   //---
   errors[139].code = 4902;
   errors[139].description = "Depth of Market non può essere rimosso";
   errors[139].constant = "ERR_BOOKS_CANNOT_DELETE";
   //---
   errors[140].code = 4903;
   errors[140].description = "Impossibile ottenere i dati Depth of Market";
   errors[140].constant = "ERR_BOOKS_CANNOT_GET";
   //---
   errors[141].code = 4904;
   errors[141].description = "Errore nella sottoscrizione per ricevere nuovi dati Depth of Market";
   errors[141].constant = "ERR_BOOKS_CANNOT_SUBSCRIBE";
   //+------------------------------------------------------------------+
   //| File Operations                                                  |
   //+------------------------------------------------------------------+
   errors[142].code = 5001;
   errors[142].description = "Non è possibile aprire più di 64 file contemporaneamente";
   errors[142].constant = "ERR_TOO_MANY_FILES";
   //---
   errors[143].code = 5002;
   errors[143].description = "Nome file non valido";
   errors[143].constant = "ERR_WRONG_FILENAME";
   //---
   errors[144].code = 5003;
   errors[144].description = "Nome file troppo lungo";
   errors[144].constant = "ERR_TOO_LONG_FILENAME";
   //---
   errors[145].code = 5004;
   errors[145].description = "Errore nell'apertura del file";
   errors[145].constant = "ERR_CANNOT_OPEN_FILE";
   //---
   errors[146].code = 5005;
   errors[146].description = "Memoria cache insufficiente per la lettura";
   errors[146].constant = "ERR_FILE_CACHEBUFFER_ERROR";
   //---
   errors[147].code = 5006;
   errors[147].description = "Errore nell'eliminazione del file";
   errors[147].constant = "ERR_CANNOT_DELETE_FILE";
   //---
   errors[148].code = 5007;
   errors[148].description = "Un file con questo handle è stato chiuso o semplicemente non era aperto";
   errors[148].constant = "ERR_INVALID_FILEHANDLE";
   //---
   errors[149].code = 5008;
   errors[149].description = "Handle file errato";
   errors[149].constant = "ERR_WRONG_FILEHANDLE";
   //---
   errors[150].code = 5009;
   errors[150].description = "Il file deve essere aperto per la scrittura";
   errors[150].constant = "ERR_FILE_NOTTOWRITE";
   //---
   errors[151].code = 5010;
   errors[151].description = "Il file deve essere aperto per la lettura";
   errors[151].constant = "ERR_FILE_NOTTOREAD";
   //---
   errors[152].code = 5011;
   errors[152].description = "Il file deve essere aperto come file binario";
   errors[152].constant = "ERR_FILE_NOTBIN";
   //---
   errors[153].code = 5012;
   errors[153].description = "Il file deve essere aperto come testo";
   errors[153].constant = "ERR_FILE_NOTTXT";
   //---
   errors[154].code = 5013;
   errors[154].description = "Il file deve essere aperto come testo o CSV";
   errors[154].constant = "ERR_FILE_NOTTXTORCSV";
   //---
   errors[155].code = 5014;
   errors[155].description = "Il file deve essere aperto come CSV";
   errors[155].constant = "ERR_FILE_NOTCSV";
   //---
   errors[156].code = 5015;
   errors[156].description = "Errore nella lettura del file";
   errors[156].constant = "ERR_FILE_READERROR";
   //---
   errors[157].code = 5016;
   errors[157].description = "La dimensione della stringa deve essere specificata perché il file è aperto come binario";
   errors[157].constant = "ERR_FILE_BINSTRINGSIZE";
   //---
   errors[158].code = 5017;
   errors[158].description = "Un file di testo deve essere usato per array di stringhe, per altri array - binario";
   errors[158].constant = "ERR_INCOMPATIBLE_FILE";
   //---
   errors[159].code = 5018;
   errors[159].description = "Questo non è un file, è una cartella";
   errors[159].constant = "ERR_FILE_IS_DIRECTORY";
   //---
   errors[160].code = 5019;
   errors[160].description = "File inesistente";
   errors[160].constant = "ERR_FILE_NOT_EXIST";
   //---
   errors[161].code = 5020;
   errors[161].description = "Il file non può essere riscritto";
   errors[161].constant = "ERR_FILE_CANNOT_REWRITE";
   //---
   errors[162].code = 5021;
   errors[162].description = "Nome cartella errato";
   errors[162].constant = "ERR_WRONG_DIRECTORYNAME";
   //---
   errors[163].code = 5022;
   errors[163].description = "Cartella inesistente";
   errors[163].constant = "ERR_DIRECTORY_NOT_EXIST";
   //---
   errors[164].code = 5023;
   errors[164].description = "Questo è un file, non una cartella";
   errors[164].constant = "ERR_FILE_ISNOT_DIRECTORY";
   //---
   errors[165].code = 5024;
   errors[165].description = "Impossibile eliminare la cartella";
   errors[165].constant = "ERR_CANNOT_DELETE_DIRECTORY";
   //---
   errors[166].code = 5025;
   errors[166].description = "Impossibile svuotare la cartella (probabilmente uno o più file sono bloccati e l'operazione di eliminazione è fallita)";
   errors[166].constant = "ERR_CANNOT_CLEAN_DIRECTORY";
   //---
   errors[167].code = 5026;
   errors[167].description = "Impossibile scrivere una risorsa su un file";
   errors[167].constant = "ERR_FILE_WRITEERROR";
   //---
   errors[168].code = 5027;
   errors[168].description = "Impossibile leggere il prossimo blocco di dati dal file CSV (FileReadString, FileReadNumber, FileReadDatetime, FileReadBool), perché è stata raggiunta la fine del file";
   errors[168].constant = "ERR_FILE_ENDOFFILE";
   //+------------------------------------------------------------------+
   //| String Casting                                                   |
   //+------------------------------------------------------------------+
   errors[169].code = 5030;
   errors[169].description = "Nessuna data nella stringa";
   errors[169].constant = "ERR_NO_STRING_DATE";
   //---
   errors[170].code = 5031;
   errors[170].description = "Data errata nella stringa";
   errors[170].constant = "ERR_WRONG_STRING_DATE";
   //---
   errors[171].code = 5032;
   errors[171].description = "Ora errata nella stringa";
   errors[171].constant = "ERR_WRONG_STRING_TIME";
   //---
   errors[172].code = 5033;
   errors[172].description = "Errore nella conversione della stringa in data";
   errors[172].constant = "ERR_STRING_TIME_ERROR";
   //---
   errors[173].code = 5034;
   errors[173].description = "Memoria insufficiente per la stringa";
   errors[173].constant = "ERR_STRING_OUT_OF_MEMORY";
   //---
   errors[174].code = 5035;
   errors[174].description = "La lunghezza della stringa è inferiore a quella prevista";
   errors[174].constant = "ERR_STRING_SMALL_LEN";
   //---
   errors[175].code = 5036;
   errors[175].description = "Numero troppo grande, superiore a ULONG_MAX";
   errors[175].constant = "ERR_STRING_TOO_BIGNUMBER";
   //---
   errors[176].code = 5037;
   errors[176].description = "Stringa di formato non valida";
   errors[176].constant = "ERR_WRONG_FORMATSTRING";
   //---
   errors[177].code = 5038;
   errors[177].description = "Numero di specificatori di formato superiore ai parametri";
   errors[177].constant = "ERR_TOO_MANY_FORMATTERS";
   //---
   errors[178].code = 5039;
   errors[178].description = "Numero di parametri superiore ai specificatori di formato";
   errors[178].constant = "ERR_TOO_MANY_PARAMETERS";
   //---
   errors[179].code = 5040;
   errors[179].description = "Parametro di tipo stringa difettoso";
   errors[179].constant = "ERR_WRONG_STRING_PARAMETER";
   //---
   errors[180].code = 5041;
   errors[180].description = "Posizione fuori dalla stringa";
   errors[180].constant = "ERR_STRINGPOS_OUTOFRANGE";
   //---
   errors[181].code = 5042;
   errors[181].description = "0 aggiunto alla fine della stringa, operazione inutile";
   errors[181].constant = "ERR_STRING_ZEROADDED";
   //---
   errors[182].code = 5043;
   errors[182].description = "Tipo di dato sconosciuto durante la conversione in stringa";
   errors[182].constant = "ERR_STRING_UNKNOWNTYPE";
   //---
   errors[183].code = 5044;
   errors[183].description = "Oggetto stringa difettoso";
   errors[183].constant = "ERR_WRONG_STRING_OBJECT";
   //+------------------------------------------------------------------+
   //| Operations with Arrays                                           |
   //+------------------------------------------------------------------+
   errors[184].code = 5050;
   errors[184].description = "Copia di array incompatibili. Un array di stringhe può essere copiato solo in un array di stringhe, e un array numerico solo in un array numerico";
   errors[184].constant = "ERR_INCOMPATIBLE_ARRAYS";
   //---
   errors[185].code = 5051;
   errors[185].description = "L'array di ricezione è dichiarato come AS_SERIES ed è di dimensione insufficiente";
   errors[185].constant = "ERR_SMALL_ASSERIES_ARRAY";
   //---
   errors[186].code = 5052;
   errors[186].description = "Array troppo piccolo, posizione iniziale fuori dall'array";
   errors[186].constant = "ERR_SMALL_ARRAY";
   //---
   errors[187].code = 5053;
   errors[187].description = "Array di lunghezza zero";
   errors[187].constant = "ERR_ZEROSIZE_ARRAY";
   //---
   errors[188].code = 5054;
   errors[188].description = "Deve essere un array numerico";
   errors[188].constant = "ERR_NUMBER_ARRAYS_ONLY";
   //---
   errors[189].code = 5055;
   errors[189].description = "Deve essere un array monodimensionale";
   errors[189].constant = "ERR_ONE_DIMENSIONAL_ARRAY";
   //---
   errors[190].code = 5056;
   errors[190].description = "Serie temporale (timeseries) non può essere utilizzata";
   errors[190].constant = "ERR_SERIES_ARRAY";
   //---
   errors[191].code = 5057;
   errors[191].description = "Deve essere un array di tipo double";
   errors[191].constant = "ERR_DOUBLE_ARRAY_ONLY";
   //---
   errors[192].code = 5058;
   errors[192].description = "Deve essere un array di tipo float";
   errors[192].constant = "ERR_FLOAT_ARRAY_ONLY";
   //---
   errors[193].code = 5059;
   errors[193].description = "Deve essere un array di tipo long";
   errors[193].constant = "ERR_LONG_ARRAY_ONLY";
   //---
   errors[194].code = 5060;
   errors[194].description = "Deve essere un array di tipo int";
   errors[194].constant = "ERR_INT_ARRAY_ONLY";
   //---
   errors[195].code = 5061;
   errors[195].description = "Deve essere un array di tipo short";
   errors[195].constant = "ERR_SHORT_ARRAY_ONLY";
   //---
   errors[196].code = 5062;
   errors[196].description = "Deve essere un array di tipo char";
   errors[196].constant = "ERR_CHAR_ARRAY_ONLY";
   //---
   errors[197].code = 5063;
   errors[197].description = "Deve essere un array di tipo stringa";
   errors[197].constant = "ERR_STRING_ARRAY_ONLY";
   //+------------------------------------------------------------------+
   //| Operations with OpenCL                                           |
   //+------------------------------------------------------------------+
   errors[198].code = 5100;
   errors[198].description = "Funzioni OpenCL non supportate su questo computer";
   errors[198].constant = "ERR_OPENCL_NOT_SUPPORTED";
   //---
   errors[199].code = 5101;
   errors[199].description = "Errore interno durante l'esecuzione di OpenCL";
   errors[199].constant = "ERR_OPENCL_INTERNAL";
   //---
   errors[200].code = 5102;
   errors[200].description = "Handle OpenCL non valido";
   errors[200].constant = "ERR_OPENCL_INVALID_HANDLE";
   //---
   errors[201].code = 5103;
   errors[201].description = "Errore nella creazione del contesto OpenCL";
   errors[201].constant = "ERR_OPENCL_CONTEXT_CREATE";
   //---
   errors[202].code = 5104;
   errors[202].description = "Impossibile creare una coda di esecuzione OpenCL";
   errors[202].constant = "ERR_OPENCL_QUEUE_CREATE";
   //---
   errors[203].code = 5105;
   errors[203].description = "Errore durante la compilazione di un programma OpenCL";
   errors[203].constant = "ERR_OPENCL_PROGRAM_CREATE";
   //---
   errors[204].code = 5106;
   errors[204].description = "Nome kernel troppo lungo (kernel OpenCL)";
   errors[204].constant = "ERR_OPENCL_TOO_LONG_KERNEL_NAME";
   //---
   errors[205].code = 5107;
   errors[205].description = "Errore nella creazione di un kernel OpenCL";
   errors[205].constant = "ERR_OPENCL_KERNEL_CREATE";
   //---
   errors[206].code = 5108;
   errors[206].description = "Errore durante la configurazione dei parametri per il kernel OpenCL";
   errors[206].constant = "ERR_OPENCL_SET_KERNEL_PARAMETER";
   //---
   errors[207].code = 5109;
   errors[207].description = "Errore durante l'esecuzione del programma OpenCL";
   errors[207].constant = "ERR_OPENCL_EXECUTE";
   //---
   errors[209].code = 5110;
   errors[209].description = "Dimensione buffer OpenCL non valida";
   errors[209].constant = "ERR_OPENCL_WRONG_BUFFER_SIZE";
   //---
   errors[210].code = 5111;
   errors[210].description = "Offset buffer OpenCL non valido";
   errors[210].constant = "ERR_OPENCL_WRONG_BUFFER_OFFSET";
   //---
   errors[211].code = 5112;
   errors[211].description = "Impossibile creare un buffer OpenCL";
   errors[211].constant = "ERR_OPENCL_BUFFER_CREATE";
   //---
   errors[212].code = 5113;
   errors[212].description = "Numero massimo di oggetti OpenCL superato";
   errors[212].constant = "ERR_OPENCL_TOO_MANY_OBJECTS";
   //---
   errors[213].code = 5114;
   errors[213].description = "Errore nella selezione del dispositivo OpenCL";
   errors[213].constant = "ERR_OPENCL_SELECTDEVICE";
   //+------------------------------------------------------------------+
   //| Working with databases                                           |
   //+------------------------------------------------------------------+
   errors[214].code = 5120;
   errors[214].description = "Errore interno nel database";
   errors[214].constant = "ERR_DATABASE_INTERNAL";
   //---
   errors[215].code = 5121;
   errors[215].description = "Identificativo database non valido";
   errors[215].constant = "ERR_DATABASE_INVALID_HANDLE";
   //---
   errors[216].code = 5122;
   errors[216].description = "Numero massimo di oggetti database superato";
   errors[216].constant = "ERR_DATABASE_TOO_MANY_OBJECTS";
   //---
   errors[217].code = 5123;
   errors[217].description = "Errore di connessione al database";
   errors[217].constant = "ERR_DATABASE_CONNECT";
   //---
   errors[218].code = 5124;
   errors[218].description = "Errore nell'esecuzione della query";
   errors[218].constant = "ERR_DATABASE_EXECUTE";
   //---
   errors[219].code = 5125;
   errors[219].description = "Errore nella creazione della query";
   errors[219].constant = "ERR_DATABASE_PREPARE";
   //---
   errors[220].code = 5126;
   errors[220].description = "Nessun altro dato da leggere";
   errors[220].constant = "ERR_DATABASE_NO_MORE_DATA";
   //---
   errors[221].code = 5127;
   errors[221].description = "Errore nel passaggio al record successivo della query";
   errors[221].constant = "ERR_DATABASE_STEP";
   //---
   errors[222].code = 5128;
   errors[222].description = "I dati per la lettura dei risultati della query non sono ancora pronti";
   errors[222].constant = "ERR_DATABASE_NOT_READY";
   //---
   errors[223].code = 5129;
   errors[223].description = "Errore nella sostituzione automatica dei parametri nella query SQL";
   errors[223].constant = "ERR_DATABASE_BIND_PARAMETERS";
   //+------------------------------------------------------------------+
   //| Operations with WebRequest                                       |
   //+------------------------------------------------------------------+
   errors[224].code = 5200;
   errors[224].description = "URL non valido";
   errors[224].constant = "ERR_WEBREQUEST_INVALID_ADDRESS";
   //---
   errors[225].code = 5201;
   errors[225].description = "Connessione all'URL specificato fallita";
   errors[225].constant = "ERR_WEBREQUEST_CONNECT_FAILED";
   //---
   errors[226].code = 5202;
   errors[226].description = "Timeout scaduto";
   errors[226].constant = "ERR_WEBREQUEST_TIMEOUT";
   //---
   errors[227].code = 5203;
   errors[227].description = "Richiesta HTTP fallita";
   errors[227].constant = "ERR_WEBREQUEST_REQUEST_FAILED";
   //+------------------------------------------------------------------+
   //| Operations with network (sockets)                                |
   //+------------------------------------------------------------------+
   errors[228].code = 5270;
   errors[228].description = "Per la funzione è stato passato un identificativo socket non valido";
   errors[228].constant = "ERR_NETSOCKET_INVALIDHANDLE";
   //---
   errors[229].code = 5271;
   errors[229].description = "Troppi socket aperti (massimo 128)";
   errors[229].constant = "ERR_NETSOCKET_TOO_MANY_OPENED";
   //---
   errors[230].code = 5272;
   errors[230].description = "Errore nella connessione all'host remoto";
   errors[230].constant = "ERR_NETSOCKET_CANNOT_CONNECT";
   //---
   errors[231].code = 5273;
   errors[231].description = "Errore nell'invio/ricezione dati dal socket";
   errors[231].constant = "ERR_NETSOCKET_IO_ERROR";
   //---
   errors[232].code = 5274;
   errors[232].description = "Errore nell'instaurare una connessione sicura (TLS Handshake)";
   errors[232].constant = "ERR_NETSOCKET_HANDSHAKE_FAILED";
   //---
   errors[233].code = 5275;
   errors[233].description = "Nessun dato sul certificato che protegge la connessione";
   errors[233].constant = "ERR_NETSOCKET_NO_CERTIFICATE";
   //+------------------------------------------------------------------+
   //| Custom Symbols                                                   |
   //+------------------------------------------------------------------+
   errors[234].code = 5300;
   errors[234].description = "Deve essere specificato il simbolo personalizzato";
   errors[234].constant = "ERR_NOT_CUSTOM_SYMBOL";
   //---
   errors[235].code = 5301;
   errors[235].description = "Nome simbolo personalizzato errato. Nel nome del simbolo è possibile utilizzare solo caratteri latini senza punteggiatura, spazi e caratteri speciali (sono consentiti '.','_','&' e '#'). Si sconsiglia l'uso dei caratteri <, >, :, ', /, |, ?, *.";
   errors[235].constant = "ERR_CUSTOM_SYMBOL_WRONG_NAME";
   //---
   errors[236].code = 5302;
   errors[236].description = "Nome troppo lungo per il simbolo personalizzato. Il nome non può superare i 32 caratteri considerando lo 0 finale";
   errors[236].constant = "ERR_CUSTOM_SYMBOL_NAME_LONG";
   //---
   errors[237].code = 5303;
   errors[237].description = "Percorso troppo lungo per il simbolo personalizzato. Il percorso non deve superare i 128 caratteri, considerando 'Custom\\', il nome del simbolo, i separatori di gruppo e lo 0 finale";
   errors[237].constant = "ERR_CUSTOM_SYMBOL_PATH_LONG";
   //---
   errors[238].code = 5304;
   errors[238].description = "Esiste già un simbolo personalizzato con questo nome";
   errors[238].constant = "ERR_CUSTOM_SYMBOL_EXIST";
   //---
   errors[239].code = 5305;
   errors[239].description = "Errore nella creazione, eliminazione o modifica del simbolo personalizzato";
   errors[239].constant = "ERR_CUSTOM_SYMBOL_ERROR";
   //---
   errors[240].code = 5306;
   errors[240].description = "Tentativo di eliminare un simbolo personalizzato selezionato nella Market Watch";
   errors[240].constant = "ERR_CUSTOM_SYMBOL_SELECTED";
   //---
   errors[241].code = 5307;
   errors[241].description = "Proprietà del simbolo personalizzato errata";
   errors[241].constant = "ERR_CUSTOM_SYMBOL_PROPERTY_WRONG";
   //---
   errors[242].code = 5308;
   errors[242].description = "Parametro errato nell'impostazione della proprietà del simbolo personalizzato";
   errors[242].constant = "ERR_CUSTOM_SYMBOL_PARAMETER_ERROR";
   //---
   errors[243].code = 5309;
   errors[243].description = "Parametro stringa troppo lungo nell'impostazione della proprietà del simbolo personalizzato";
   errors[243].constant = "ERR_CUSTOM_SYMBOL_PARAMETER_LONG";
   //---
   errors[244].code = 5310;
   errors[244].description = "Array di tick non ordinato per tempo";
   errors[244].constant = "ERR_CUSTOM_TICKS_WRONG_ORDER";
   //+------------------------------------------------------------------+
   //| Economic Calendar                                                |
   //+------------------------------------------------------------------+
   errors[245].code = 5400;
   errors[245].description = "Dimensione dell'array insufficiente per ottenere le descrizioni di tutti i valori";
   errors[245].constant = "ERR_CALENDAR_MORE_DATA";
   //---
   errors[246].code = 5401;
   errors[246].description = "Timeout della richiesta superato";
   errors[246].constant = "ERR_CALENDAR_TIMEOUT";
   //---
   errors[247].code = 5402;
   errors[247].description = "Paese non trovato";
   errors[247].constant = "ERR_CALENDAR_NO_DATA";
   //+------------------------------------------------------------------+
   //| Working with databases                                           |
   //+------------------------------------------------------------------+
   errors[248].code = 5601;
   errors[248].description = "Errore generico";
   errors[248].constant = "ERR_DATABASE_ERROR";
   //---
   errors[249].code = 5602;
   errors[249].description = "Errore logico interno di SQLite";
   errors[249].constant = "ERR_DATABASE_INTERNAL";
   //---
   errors[250].code = 5603;
   errors[250].description = "Accesso negato";
   errors[250].constant = "ERR_DATABASE_PERM";
   //---
   errors[251].code = 5604;
   errors[251].description = "Routine di callback richiesta annullamento";
   errors[251].constant = "ERR_DATABASE_ABORT";
   //---
   errors[252].code = 5605;
   errors[252].description = "File di database bloccato";
   errors[252].constant = "ERR_DATABASE_BUSY";
   //---
   errors[253].code = 5606;
   errors[253].description = "Tabella di database bloccata";
   errors[253].constant = "ERR_DATABASE_LOCKED";
   //---
   errors[254].code = 5607;
   errors[254].description = "Memoria insufficiente per completare l'operazione";
   errors[254].constant = "ERR_DATABASE_NOMEM";
   //---
   errors[255].code = 5608;
   errors[255].description = "Tentativo di scrivere su un database in sola lettura";
   errors[255].constant = "ERR_DATABASE_READONLY";
   //---
   errors[256].code = 5609;
   errors[256].description = "Operazione terminata da sqlite3_interrupt()";
   errors[256].constant = "ERR_DATABASE_INTERRUPT";
   //---
   errors[257].code = 5610;
   errors[257].description = "Errore di I/O su disco";
   errors[257].constant = "ERR_DATABASE_IOERR";
   //---
   errors[258].code = 5611;
   errors[258].description = "Immagine del disco del database corrotta";
   errors[258].constant = "ERR_DATABASE_CORRUPT";
   //---
   errors[259].code = 5612;
   errors[259].description = "Codice operazione sconosciuto in sqlite3_file_control()";
   errors[259].constant = "ERR_DATABASE_NOTFOUND";
   //---
   errors[260].code = 5613;
   errors[260].description = "Inserimento fallito perché il database è pieno";
   errors[260].constant = "ERR_DATABASE_FULL";
   //---
   errors[261].code = 5614;
   errors[261].description = "Impossibile aprire il file di database";
   errors[261].constant = "ERR_DATABASE_CANTOPEN";
   //---
   errors[262].code = 5615;
   errors[262].description = "Errore di protocollo di blocco del database";
   errors[262].constant = "ERR_DATABASE_PROTOCOL";
   //---
   errors[263].code = 5616;
   errors[263].description = "Solo per uso interno";
   errors[263].constant = "ERR_DATABASE_EMPTY";
   //---
   errors[264].code = 5617;
   errors[264].description = "Schema del database modificato";
   errors[264].constant = "ERR_DATABASE_SCHEMA";
   //---
   errors[265].code = 5618;
   errors[265].description = "Stringa o BLOB supera il limite di dimensione";
   errors[265].constant = "ERR_DATABASE_TOOBIG";
   //---
   errors[266].code = 5619;
   errors[266].description = "Annullamento a causa di violazione di vincolo";
   errors[266].constant = "ERR_DATABASE_CONSTRAINT";
   //---
   errors[267].code = 5620;
   errors[267].description = "Incompatibilità di tipo di dati";
   errors[267].constant = "ERR_DATABASE_MISMATCH";
   //---
   errors[268].code = 5621;
   errors[268].description = "Libreria utilizzata in modo errato";
   errors[268].constant = "ERR_DATABASE_MISUSE";
   //---
   errors[269].code = 5622;
   errors[269].description = "Utilizza risorse del SO non supportate sull'host";
   errors[269].constant = "ERR_DATABASE_NOLFS";
   //---
   errors[270].code = 5623;
   errors[270].description = "Autorizzazione negata";
   errors[270].constant = "ERR_DATABASE_AUTH";
   //---
   errors[271].code = 5624;
   errors[271].description = "Non utilizzato";
   errors[271].constant = "ERR_DATABASE_FORMAT";
   //---
   errors[272].code = 5625;
   errors[272].description = "Errore di parametro di binding, indice errato";
   errors[272].constant = "ERR_DATABASE_RANGE";
   //---
   errors[273].code = 5626;
   errors[273].description = "File aperto che non è un file di database";
   errors[273].constant = "ERR_DATABASE_NOTADB";
  }
//+------------------------------------------------------------------+

