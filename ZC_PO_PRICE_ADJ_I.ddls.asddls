@AbapCatalog.sqlViewName: 'ZICPOPRICEADJ'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO Price Adjustment - Interface View'
define view entity ZC_PO_PRICE_ADJ_I
  as select from I_PurchaseOrderItem as POItem
  association to I_PurchaseOrder     as _POHeader on _POHeader.PurchaseOrder = POItem.PurchaseOrder
{
      @UI.facet: [
        { id: 'idPOPriceAdj', purpose: #STANDARD, type: #COLLECTION, label: 'PO Price Adjustment', position: 10 },
        { id: 'idGeneral', parentId: 'idPOPriceAdj', purpose: #STANDARD, type: #FORM_ELEMENTS, label: 'General Information', position: 10 },
        { id: 'idPricing', parentId: 'idPOPriceAdj', purpose: #STANDARD, type: #FORM_ELEMENTS, label: 'Pricing Details', position: 20 }
      ]

      @UI.lineItem: [{ position: 10, label: 'PO Number', importance: #HIGH }]
      @UI.identification: [{ position: 10, label: 'PO Number', type: #FOR_INTENT_BASED_NAVIGATION, semanticObject: 'PurchaseOrder', semanticObjectAction: 'display' }]
      @UI.selectionField: [{ position: 10 }]
  key PurchaseOrder,

      @UI.lineItem: [{ position: 20, label: 'PO Item', importance: #HIGH }]
      @UI.identification: [{ position: 20, label: 'PO Item' }]
      @UI.selectionField: [{ position: 20 }]
  key PurchaseOrderItem,

      @UI.lineItem: [{ position: 30, label: 'Material' }]
      @UI.identification: [{ position: 30, label: 'Material' }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Material', element: 'Material' } }]
      POItem.Material,

      @UI.lineItem: [{ position: 40, label: 'Net Price Amount', criticality: 'NetPriceAmountCriticality' }]
      @UI.identification: [{ position: 40, label: 'Net Price Amount' }]
      POItem.NetPriceAmount,

      @UI.hidden: true
      POItem.NetPriceAmount_2,

      @Semantics.currencyCode: true
      POItem.PurchaseOrderItemCurrency,

      @UI.hidden: true
      POItem.NetPriceQuantity,

      @UI.hidden: true
      POItem.NetPriceQuantityUnit,

      @UI.lineItem: [{ position: 50, label: 'PO Creation Date' }]
      @UI.identification: [{ position: 50, label: 'PO Creation Date' }]
      @UI.selectionField: [{ position: 30 }]
      _POHeader.CreationDate as PurchaseOrderCreationDate,

      @UI.lineItem: [{ position: 60, label: 'Supplier' }]
      @UI.identification: [{ position: 60, label: 'Supplier', type: #FOR_INTENT_BASED_NAVIGATION, semanticObject: 'Supplier', semanticObjectAction: 'display' }]
      @UI.selectionField: [{ position: 40 }]
      _POHeader.Supplier,

      @UI.lineItem: [{ position: 70, label: 'Purchasing Organization' }]
      @UI.identification: [{ position: 70, label: 'Purchasing Organization' }]
      @UI.selectionField: [{ position: 50 }]
      _POHeader.PurchasingOrganization,

      @UI.lineItem: [{ position: 80, label: 'Purchasing Group' }]
      @UI.identification: [{ position: 80, label: 'Purchasing Group' }]
      @UI.selectionField: [{ position: 60 }]
      _POHeader.PurchasingGroup,

      @UI.lineItem: [{ position: 90, label: 'Document Type' }]
      @UI.identification: [{ position: 90, label: 'Document Type' }]
      @UI.selectionField: [{ position: 70 }]
      _POHeader.PurchaseOrderType,

      @UI.lineItem: [{ position: 100, label: 'Delivery Date' }]
      @UI.identification: [{ position: 100, label: 'Delivery Date' }]
      @UI.selectionField: [{ position: 80 }]
      POItem.ScheduleLineDeliveryDate,

      @UI.hidden: true
      cast( '' as abap.char(1) ) as AdjustmentStatus,

      @UI.hidden: true
      cast( '' as abap.string ) as AdjustmentMessage,

      @UI.hidden: true
      cast( 0 as abap.dec(15,2) ) as NewNetPriceAmount,

      @UI.hidden: true
      cast( 0 as abap.dec(15,2) ) as AdjustmentPercentage,

      @UI.hidden: true
      cast( '' as abap.char(1) ) as IsTestRun,

      @UI.hidden: true
      cast( '' as abap.char(1) ) as IsSelected,

      @UI.hidden: true
      cast( 0 as abap.dec(1,0) ) as NetPriceAmountCriticality,

      _POHeader
}
