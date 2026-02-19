@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'PO Item Price Change - Projection'
@Metadata.allowExtensions: true
define root view entity ZC_POItemPriceDemo
  provider contract transactional_query
  as projection on ZR_POItemPriceDemo
{
  key PurchaseOrder,
  key PurchaseOrderItem,

      /* PO Header (읽기 전용 / 필터) */
      PurchaseOrderType,
      CompanyCode,
      PurchasingOrganization,
      PurchasingGroup,
      Supplier,
      CreationDate,

      /* PO Item (읽기 전용) */
      PurchaseOrderItemText,
      Material,
      Plant,
      OrderQuantity,
      PurchaseOrderQuantityUnit,

      /* 편집 대상 */
      // @Semantics.amount.currencyCode: 'DocumentCurrency'
      NetPriceAmount,
      DocumentCurrency,

      AccountAssignmentCategory,

      /* Association */
      _PurchaseOrder
}
