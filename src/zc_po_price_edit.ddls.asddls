@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'PO Header - Price Edit (Projection)'
@Metadata.allowExtensions: true
define root view entity ZC_PO_PRICE_EDIT
  provider contract transactional_query
  as projection on ZI_PO_PRICE_EDIT
{
  key PurchaseOrder,
      PurchaseOrderType,
      CompanyCode,
      PurchasingOrganization,
      PurchasingGroup,
      Supplier,
      DocumentCurrency,
      PurchaseOrderDate,
      CreatedByUser,
      CreationDate,
      LastChangeDateTime,
      _Item : redirected to composition child ZC_PO_ITEM_PRICE_EDIT
}
