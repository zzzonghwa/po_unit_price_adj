@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'PO Item Price Change - BO Root'
define root view entity ZR_POItemPriceDemo
  as select from I_PurchaseOrderItemAPI01 as _Item
  association [1] to I_PurchaseOrderAPI01 as _PurchaseOrder on _PurchaseOrder.PurchaseOrder = _Item.PurchaseOrder
{
  key _Item.PurchaseOrder,
  key _Item.PurchaseOrderItem as PurchaseOrderItem,

      /* PO Header 필드 (조회/필터 전용) */
      _PurchaseOrder.PurchaseOrderType,
      _PurchaseOrder.CompanyCode,
      _PurchaseOrder.PurchasingOrganization,
      _PurchaseOrder.PurchasingGroup,
      _PurchaseOrder.Supplier,
      _PurchaseOrder.CreationDate,

      /* PO Item 필드 */
      _Item.PurchaseOrderItemText,
      _Item.Material,
      _Item.Plant,
      _Item.OrderQuantity,
      _Item.PurchaseOrderQuantityUnit,

      /* 편집 대상 필드 */
      // @Semantics.amount.currencyCode: 'DocumentCurrency'
      _Item.NetPriceAmount    as NetPriceAmount,
      _Item.DocumentCurrency,

      _Item.AccountAssignmentCategory,

      /* ETag용 변경 타임스탬프 - Local Generated */
//      @Semantics.systemDateTime.localInstanceLastChangedAt: true
//      cast(
//        cast( _Item.PurchaseOrderItem as abap.dec(21,7) ) + _PurchaseOrder.LastChangeDateTime
//        as timestampl
//      )                       as LocalLastChangedAt,

      /* Association */
      _PurchaseOrder
}
