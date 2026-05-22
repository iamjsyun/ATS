#ifndef CXIDMANAGER_MQH
#define CXIDMANAGER_MQH

#include "..\Interfaces\CXDefine.mqh"

/**
 * @class CXIdManager
 * @brief SID/GID 규격 검증 및 데이터 추출 전문 매니저 (v8.2 Standard)
 * @details SID Format: CNO(4)-YYMMDDHH(8)-SNO(2)-GNO(2)-DIR(1)-TYPE(1) (Total 23 chars)
 */
class CXIdManager {
public:
    /**
     * @brief SID 구조 및 길이 검증
     */
    static bool ValidateSID(string sid) {
        if(StringLen(sid) != 23) return false;
        
        // 하이픈 위치 검증 (4, 13, 16, 19, 21)
        if(StringGetCharacter(sid, 4) != '-' ||
           StringGetCharacter(sid, 13) != '-' ||
           StringGetCharacter(sid, 16) != '-' ||
           StringGetCharacter(sid, 19) != '-' ||
           StringGetCharacter(sid, 21) != '-') return false;
           
        return true;
    }

    /**
     * @brief SID에서 방향(Direction) 추출 (index 20)
     */
    static int ExtractDir(string sid) {
        if(!ValidateSID(sid)) return 0;
        string dirStr = StringSubstr(sid, 20, 1);
        return (int)StringToInteger(dirStr);
    }

    /**
     * @brief SID에서 주문 타입(Type) 추출 (index 22)
     */
    static int ExtractType(string sid) {
        if(!ValidateSID(sid)) return 0;
        string typeStr = StringSubstr(sid, 22, 1);
        return (int)StringToInteger(typeStr);
    }
};

#endif
