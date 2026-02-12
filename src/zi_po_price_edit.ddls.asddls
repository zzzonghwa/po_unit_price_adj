@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'PO Header - Price Edit (Interface)'
define root view entity ZI_PO_PRICE_EDIT
  as select from I_PurchaseOrderAPI01 as PO
  composition [0..*] of ZI_PO_ITEM_PRICE_EDIT as _Item
{
  key PO.PurchaseOrder,
      PO.PurchaseOrderType,
      PO.CompanyCode,
      PO.PurchasingOrganization,
      PO.PurchasingGroup,
      PO.Supplier,
      PO.DocumentCurrency,
      PO.PurchaseOrderDate,
      PO.CreatedByUser,
      PO.CreationDate,
      PO.LastChangeDateTime,
      _Item
}
