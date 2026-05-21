#ifndef CXTERMINALSCANNER_MQH
#define CXTERMINALSCANNER_MQH

#include <Arrays\ArrayObj.mqh>
#include "..\..\Models\CXParam.mqh"

/**
 * @class CXTerminalScanner
 * @brief ?곕??먯쓽 臾쇰━???먯궛(?ъ???二쇰Ц) ?꾩닔 議곗궗 ?대떦
 */
class CXTerminalScanner {
public:
    CXTerminalScanner() {}
    ~CXTerminalScanner() {}

    /**
     * @brief ?꾩옱 ?곕??먯쓽 紐⑤뱺 愿???먯궛???ㅼ틪?섏뿬 由ъ뒪?몃줈 諛섑솚
     */
    int ScanAll(CArrayObj* list) {
        if(IS_INVALID(list)) return 0;
        int count = 0;

        //-- 1. ?쒖꽦 ?ъ????ㅼ틪
        for(int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            if(PositionSelectByTicket(ticket)) {
                string sid = PositionGetString(POSITION_COMMENT);
                if(sid != "") {
                    CXParam* p = new CXParam();
                    p.SetString(sid);
                    p.SetLong((long)ticket);
                    p.SetInt(10); // Type: Position (Active)
                    list.Add(p);
                    count++;
                }
            }
        }

        //-- 2. ?湲?二쇰Ц ?ㅼ틪
        for(int i = OrdersTotal() - 1; i >= 0; i--) {
            ulong ticket = OrderGetTicket(i);
            if(OrderSelect(ticket)) {
                string sid = OrderGetString(ORDER_COMMENT);
                if(sid != "") {
                    CXParam* p = new CXParam();
                    p.SetString(sid);
                    p.SetLong((long)ticket);
                    p.SetInt(1); // Type: Pending Order
                    list.Add(p);
                    count++;
                }
            }
        }

        return count;
    }
};

#endif


