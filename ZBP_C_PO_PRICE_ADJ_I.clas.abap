CLASS zbp_c_po_price_adj_i DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF ZC_PO_PRICE_ADJ_I.
  PROTECTED SECTION.
    INTERFACES if_abap_behv_handler_provider.
ENDCLASS.

CLASS zbp_c_po_price_adj_i IMPLEMENTATION.
  METHOD if_abap_behv_handler_provider~get_handler.
    CASE is_for_entity-entity.
      WHEN 'ZC_PO_PRICE_ADJ_I'.
        rv_handler = NEW zcl_bp_po_price_adj_i( ).
      WHEN 'ZI_PO_PRICE_ADJ_PARAM'.
        rv_handler = NEW zcl_bp_po_price_adj_param( ).
    ENDCASE.
  ENDMETHOD.
ENDCLASS.

CLASS zcl_bp_po_price_adj_i DEFINITION PUBLIC FINAL FOR BEHAVIOR OF ZC_PO_PRICE_ADJ_I.
  PUBLIC SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR POPriceAdjustment RESULT failed_authorizations.

    METHODS adjustPrice FOR MODIFY
      IMPORTING keys REQUEST requested_parameters FOR adjustPrice.

    METHODS previewAdjustment FOR MODIFY
      IMPORTING keys REQUEST requested_parameters FOR previewAdjustment.

    METHODS get_features FOR FEATURES
      IMPORTING keys REQUEST requested_features FOR POPriceAdjustment RESULT result.

ENDCLASS.

CLASS zcl_bp_po_price_adj_i IMPLEMENTATION.

  METHOD get_instance_authorizations.
    " Implement authorization checks here if needed.
    " For simplicity, we'll allow all for now.
  ENDMETHOD.

  METHOD get_features.
    DATA: ls_key LIKE LINE OF keys,
          ls_result LIKE LINE OF result.

    LOOP AT keys INTO ls_key.
      ls_result = VALUE #( %tky = ls_key-%tky ).
      " Enable adjustPrice and previewAdjustment actions only for selected items
      SELECT SINGLE IsSelected FROM ZC_PO_PRICE_ADJ_I INTO @DATA(lv_is_selected) WHERE PurchaseOrder = @ls_key-PurchaseOrder AND PurchaseOrderItem = @ls_key-PurchaseOrderItem.
      IF sy-subrc = 0 AND lv_is_selected = 'X'.
        ls_result-%action-adjustPrice = if_abap_behv=>enabled;
        ls_result-%action-previewAdjustment = if_abap_behv=>enabled;
      ELSE.
        ls_result-%action-adjustPrice = if_abap_behv=>disabled;
        ls_result-%action-previewAdjustment = if_abap_behv=>disabled;
      ENDIF.
      APPEND ls_result TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD adjustPrice.
    DATA: lt_po_update TYPE TABLE FOR UPDATE I_PurchaseOrderTP\PurchaseOrderItem,
          ls_po_update LIKE LINE OF lt_po_update,
          lt_failed_po TYPE TABLE FOR FAILED I_PurchaseOrderTP\PurchaseOrderItem,
          lt_reported_po TYPE TABLE FOR REPORTED I_PurchaseOrderTP\PurchaseOrderItem,
          lv_percentage TYPE abap_decp_2_2,
          lv_is_test_run TYPE abap_boolean.

    DATA(lo_po_processor) = cl_po_processing_api=>get_instance( ).

    LOOP AT keys INTO DATA(ls_key).
      READ ENTITIES OF ZC_PO_PRICE_ADJ_I IN LOCAL MODE
        ENTITY POPriceAdjustment
          BY_KEY
            FIELDS ( PurchaseOrder PurchaseOrderItem NetPriceAmount PurchaseOrderItemCurrency NetPriceQuantity NetPriceQuantityUnit IsTestRun AdjustmentPercentage )
            WITH VALUE #( ( %tky = ls_key-%tky ) )
        RESULT DATA(lt_read_result).

      DATA(ls_read_result) = lt_read_result[ 1 ].

      lv_percentage = requested_parameters[ 1 ]-AdjustPrice-AdjustmentPercentage.
      lv_is_test_run = requested_parameters[ 1 ]-AdjustPrice-IsTestRun.

      IF ls_read_result-IsSelected <> 'X'.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-poPriceAdjustment.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message( id = 'ZCM_PO_PRICE_ADJ'
                                            number = '001'
                                            v1 = ls_key-PurchaseOrder
                                            v2 = ls_key-PurchaseOrderItem
                                            severity = if_abap_behv_message=>severity-error ) ) TO reported-poPriceAdjustment.
        CONTINUE.
      ENDIF.

      DATA(lv_old_net_price) = ls_read_result-NetPriceAmount.
      DATA(lv_new_net_price) = lv_old_net_price * ( 1 + lv_percentage / 100 ).

      " Rounding based on currency decimals, for simplicity using generic rounding here.
      lv_new_net_price = round( val = lv_new_net_price dec = 2 ). " Assuming 2 decimal places for currency

      IF lv_is_test_run = abap_true.
        " In test run, just update the transient fields for preview
        MODIFY ENTITIES OF ZC_PO_PRICE_ADJ_I IN LOCAL MODE
          ENTITY POPriceAdjustment
            UPDATE FIELDS ( NewNetPriceAmount AdjustmentPercentage AdjustmentStatus AdjustmentMessage NetPriceAmountCriticality )
            WITH VALUE #( ( %tky = ls_key-%tky
                            NewNetPriceAmount = lv_new_net_price
                            AdjustmentPercentage = lv_percentage
                            AdjustmentStatus = 'P' " Previewed
                            AdjustmentMessage = 'Preview: Price will change to ' && lv_new_net_price && ' ' && ls_read_result-PurchaseOrderItemCurrency
                            NetPriceAmountCriticality = 2 ) ). " Yellow for preview
      ELSE.
        " Prepare for actual PO update via API
        ls_po_update-PurchaseOrder = ls_key-PurchaseOrder.
        ls_po_update-PurchaseOrderItem = ls_key-PurchaseOrderItem.
        ls_po_update-PurchaseOrderItemNetPrice = lv_new_net_price.
        ls_po_update-PurchaseOrderItemNetPriceQuantity = ls_read_result-NetPriceQuantity.
        ls_po_update-PurchaseOrderItemNetPriceQuantityUnit = ls_read_result-NetPriceQuantityUnit.
        ls_po_update-PurchaseOrderItemCurrency = ls_read_result-PurchaseOrderItemCurrency.
        APPEND ls_po_update TO lt_po_update.

        " Update transient fields for reporting after actual update
        MODIFY ENTITIES OF ZC_PO_PRICE_ADJ_I IN LOCAL MODE
          ENTITY POPriceAdjustment
            UPDATE FIELDS ( NewNetPriceAmount AdjustmentPercentage AdjustmentStatus NetPriceAmountCriticality )
            WITH VALUE #( ( %tky = ls_key-%tky
                            NewNetPriceAmount = lv_new_net_price
                            AdjustmentPercentage = lv_percentage
                            AdjustmentStatus = 'S' " Success
                            NetPriceAmountCriticality = 3 ) ). " Green for success
      ENDIF.
    ENDLOOP.

    IF NOT lt_po_update IS INITIAL.
      " Call the Purchase Order API to update the items
      lo_po_processor->update_item(
        EXPORTING
          it_item_update = lt_po_update
        IMPORTING
          et_failed_item = lt_failed_po
          et_reported_item = lt_reported_po
      ).

      " Handle API results
      LOOP AT lt_failed_po INTO DATA(ls_failed_po).
        APPEND VALUE #( %tky = VALUE #( PurchaseOrder = ls_failed_po-PurchaseOrder PurchaseOrderItem = ls_failed_po-PurchaseOrderItem ) ) TO failed-poPriceAdjustment.
        APPEND VALUE #( %tky = VALUE #( PurchaseOrder = ls_failed_po-PurchaseOrder PurchaseOrderItem = ls_failed_po-PurchaseOrderItem )
                        %msg = new_message( id = 'ZCM_PO_PRICE_ADJ'
                                            number = '002'
                                            v1 = ls_failed_po-PurchaseOrder
                                            v2 = ls_failed_po-PurchaseOrderItem
                                            severity = if_abap_behv_message=>severity-error ) ) TO reported-poPriceAdjustment.
        " Update transient fields for error status
        MODIFY ENTITIES OF ZC_PO_PRICE_ADJ_I IN LOCAL MODE
          ENTITY POPriceAdjustment
            UPDATE FIELDS ( AdjustmentStatus AdjustmentMessage NetPriceAmountCriticality )
            WITH VALUE #( ( %tky = VALUE #( PurchaseOrder = ls_failed_po-PurchaseOrder PurchaseOrderItem = ls_failed_po-PurchaseOrderItem )
                            AdjustmentStatus = 'E'
                            AdjustmentMessage = 'Error updating PO: ' && ls_failed_po-MessageText
                            NetPriceAmountCriticality = 1 ) ). " Red for error
      ENDLOOP.

      IF NOT lt_failed_po IS INITIAL.
        ROLLBACK ENTITIES.
      ELSE.
        COMMIT ENTITIES.
      ENDIF.

      LOOP AT lt_reported_po INTO DATA(ls_reported_po).
        APPEND VALUE #( %tky = VALUE #( PurchaseOrder = ls_reported_po-PurchaseOrder PurchaseOrderItem = ls_reported_po-PurchaseOrderItem )
                        %msg = new_message( id = 'ZCM_PO_PRICE_ADJ'
                                            number = '003'
                                            v1 = ls_reported_po-PurchaseOrder
                                            v2 = ls_reported_po-PurchaseOrderItem
                                            severity = if_abap_behv_message=>severity-information ) ) TO reported-poPriceAdjustment.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD previewAdjustment.
    DATA: lv_percentage TYPE abap_decp_2_2,
          lv_is_test_run TYPE abap_boolean.

    LOOP AT keys INTO DATA(ls_key).
      READ ENTITIES OF ZC_PO_PRICE_ADJ_I IN LOCAL MODE
        ENTITY POPriceAdjustment
          BY_KEY
            FIELDS ( PurchaseOrder PurchaseOrderItem NetPriceAmount PurchaseOrderItemCurrency IsSelected )
            WITH VALUE #( ( %tky = ls_key-%tky ) )
        RESULT DATA(lt_read_result).

      DATA(ls_read_result) = lt_read_result[ 1 ].

      lv_percentage = requested_parameters[ 1 ]-PreviewAdjustment-AdjustmentPercentage.
      lv_is_test_run = requested_parameters[ 1 ]-PreviewAdjustment-IsTestRun.

      IF ls_read_result-IsSelected <> 'X'.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-poPriceAdjustment.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message( id = 'ZCM_PO_PRICE_ADJ'
                                            number = '001'
                                            v1 = ls_key-PurchaseOrder
                                            v2 = ls_key-PurchaseOrderItem
                                            severity = if_abap_behv_message=>severity-error ) ) TO reported-poPriceAdjustment.
        CONTINUE.
      ENDIF.

      DATA(lv_old_net_price) = ls_read_result-NetPriceAmount.
      DATA(lv_new_net_price) = lv_old_net_price * ( 1 + lv_percentage / 100 ).

      lv_new_net_price = round( val = lv_new_net_price dec = 2 ). " Assuming 2 decimal places for currency

      MODIFY ENTITIES OF ZC_PO_PRICE_ADJ_I IN LOCAL MODE
        ENTITY POPriceAdjustment
          UPDATE FIELDS ( NewNetPriceAmount AdjustmentPercentage AdjustmentStatus AdjustmentMessage NetPriceAmountCriticality )
          WITH VALUE #( ( %tky = ls_key-%tky
                          NewNetPriceAmount = lv_new_net_price
                          AdjustmentPercentage = lv_percentage
                          AdjustmentStatus = 'P' " Previewed
                          AdjustmentMessage = 'Preview: Price will change to ' && lv_new_net_price && ' ' && ls_read_result-PurchaseOrderItemCurrency
                          NetPriceAmountCriticality = 2 ) ). " Yellow for preview
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS zcl_bp_po_price_adj_param DEFINITION PUBLIC FINAL FOR BEHAVIOR OF ZI_PO_PRICE_ADJ_PARAM.
  PUBLIC SECTION.
ENDCLASS.

CLASS zcl_bp_po_price_adj_param IMPLEMENTATION.
ENDCLASS.
