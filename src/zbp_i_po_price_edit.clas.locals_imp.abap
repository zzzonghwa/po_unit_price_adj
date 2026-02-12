CLASS lhc_poheader DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR POHeader RESULT result.

ENDCLASS.

CLASS lhc_poheader IMPLEMENTATION.

  METHOD get_global_authorizations.
ENDMETHOD.

  ENDCLASS.

CLASS lhc_poitem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validatePrice FOR VALIDATE ON SAVE
      IMPORTING keys FOR POItem~validatePrice.
ENDCLASS.

CLASS lhc_poitem IMPLEMENTATION.
  METHOD validatePrice.
    READ ENTITIES OF zi_po_price_edit IN LOCAL MODE
      ENTITY POItem
        FIELDS ( PurchaseOrder PurchaseOrderItem NetPriceAmount )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    LOOP AT lt_items INTO DATA(ls_item).
      IF ls_item-NetPriceAmount <= 0.
        APPEND VALUE #(
          %tky = ls_item-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = '가격은 0보다 커야 합니다.' )
          %element-NetPriceAmount = if_abap_behv=>mk-on
        ) TO reported-poitem.
        APPEND VALUE #( %tky = ls_item-%tky ) TO failed-poitem.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zi_po_price_edit DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.

CLASS lsc_zi_po_price_edit IMPLEMENTATION.
  METHOD save_modified.
    IF update-poitem IS NOT INITIAL.
      DATA: lt_poitem  TYPE TABLE OF bapimepoitem,
            lt_poitemx TYPE TABLE OF bapimepoitemx,
            lt_return  TYPE TABLE OF bapiret2.

      LOOP AT update-poitem INTO DATA(ls_item).
        CLEAR: lt_poitem, lt_poitemx, lt_return.

        APPEND VALUE #(
          po_item   = ls_item-PurchaseOrderItem
          net_price = ls_item-NetPriceAmount
        ) TO lt_poitem.

        APPEND VALUE #(
          po_item   = ls_item-PurchaseOrderItem
          po_itemx  = abap_true
          net_price = abap_true
        ) TO lt_poitemx.

        CALL FUNCTION 'BAPI_PO_CHANGE'
          EXPORTING
            purchaseorder = CONV ebeln( ls_item-PurchaseOrder )
          TABLES
            poitem        = lt_poitem
            poitemx       = lt_poitemx
            return        = lt_return.

        READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        ELSE.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
