@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'PO Item - Price Edit (Interface)'
define view entity ZI_PO_ITEM_PRICE_EDIT
  as select from I_PurchaseOrderItemAPI01 as Item
  association to parent ZI_PO_PRICE_EDIT as _Header on $projection.PurchaseOrder = _Header.PurchaseOrder
{
  key Item.PurchaseOrder,
  key Item.PurchaseOrderItem,
      Item.Material,
      Item.PurchaseOrderItemText,
      Item.Plant,
      Item.StorageLocation,
      Item.OrderQuantity,
      Item.PurchaseOrderQuantityUnit,
      Item.NetPriceAmount,
      Item.NetPriceQuantity,
      Item.OrderPriceUnit,
      Item.DocumentCurrency,
      _Header
}
