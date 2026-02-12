@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'PO Item - Price Edit (Projection)'
@Metadata.allowExtensions: true
define view entity ZC_PO_ITEM_PRICE_EDIT
  as projection on ZI_PO_ITEM_PRICE_EDIT
{
  key PurchaseOrder,
  key PurchaseOrderItem,
      Material,
      PurchaseOrderItemText,
      Plant,
      StorageLocation,
      OrderQuantity,
      PurchaseOrderQuantityUnit,
      NetPriceAmount,
      NetPriceQuantity,
      OrderPriceUnit,
      DocumentCurrency,
      _Header : redirected to parent ZC_PO_PRICE_EDIT
}
