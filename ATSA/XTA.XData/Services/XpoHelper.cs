using DevExpress.Data.Filtering;
using DevExpress.Xpo;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace XTA.XData.Services;

/// <summary>
/// XPO IDataLayer를 위한 제네릭 CRUD 확장 메서드 및 헬퍼
/// </summary>
public static class XpoHelper
{
    /// <summary>
    /// 단일 객체 조회 (비동기)
    /// </summary>
    public static async Task<T?> FindObjectAsync<T>(this IDataLayer layer, CriteriaOperator criteria) where T : class
    {
        using var uow = new UnitOfWork(layer);
        return await uow.FindObjectAsync<T>(criteria) as T;
    }

    /// <summary>
    /// 리스트 조회 (비동기)
    /// </summary>
    public static async Task<List<T>> FindListAsync<T>(this IDataLayer layer, CriteriaOperator criteria, params SortProperty[] sorts) where T : class
    {
        using var uow = new UnitOfWork(layer);
        var collection = new XPCollection<T>(uow, criteria, sorts);
        return collection.Cast<T>().ToList();
    }

    /// <summary>
    /// 객체 저장 또는 업데이트 (비동기)
    /// </summary>
    public static async Task SaveObjectAsync<T>(this IDataLayer layer, Action<T, UnitOfWork> updateAction, CriteriaOperator? findCriteria = null) where T : class, IXPObject
    {
        using var uow = new UnitOfWork(layer);
        T? xpo = !ReferenceEquals(findCriteria, null) ? await uow.FindObjectAsync<T>(findCriteria) as T : null;
        if (xpo == null) xpo = (T)Activator.CreateInstance(typeof(T), uow)!;
        
        updateAction(xpo, uow);
        await uow.CommitChangesAsync();
    }
}
