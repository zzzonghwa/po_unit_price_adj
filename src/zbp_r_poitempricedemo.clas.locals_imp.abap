"! 버퍼 클래스: update -> save 간 데이터 전달용
CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_update_data,
             purchaseorder     TYPE ebeln,
             purchaseorderitem TYPE ebelp,
             netpriceamount    TYPE bapicurext,
             documentcurrency  TYPE waers,
           END OF ty_update_data.
    CLASS-DATA mt_update TYPE TABLE OF ty_update_data.
ENDCLASS.

CLASS lhc_poitemprice DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR POItemPrice RESULT result.

    METHODS changeprice FOR MODIFY
      IMPORTING keys FOR ACTION poitemprice~changeprice RESULT results.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR poitemprice RESULT result.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE poitemprice.

    METHODS read FOR READ
      IMPORTING keys FOR READ poitemprice RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK poitemprice.

ENDCLASS.

CLASS lhc_poitemprice IMPLEMENTATION.

  METHOD changePrice.

    MODIFY ENTITIES OF zr_poitempricedemo IN LOCAL MODE
    ENTITY POItemPrice
    UPDATE FIELDS ( NetPriceAmount )
    WITH VALUE #( FOR key IN keys (
      %tky = key-%tky
    ) ).

  ENDMETHOD.

  METHOD get_instance_features.

    result = VALUE #( FOR ls_data IN keys
      ( %tky = ls_data-%tky
        %features-%update = if_abap_behv=>fc-o-enabled
      ) ).

  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD update.

    " 변경된 엔티티를 버퍼에 저장 (save 단계에서 BAPI 호출에 사용)
    LOOP AT entities INTO DATA(ls_entity).
      APPEND VALUE lcl_buffer=>ty_update_data(
        purchaseorder     = ls_entity-purchaseorder
        purchaseorderitem = ls_entity-purchaseorderitem
        netpriceamount    = ls_entity-netpriceamount
        documentcurrency  = ls_entity-documentcurrency
      ) TO lcl_buffer=>mt_update.
    ENDLOOP.

  ENDMETHOD.

  METHOD read.

    SELECT * FROM zr_poitempricedemo
      FOR ALL ENTRIES IN @keys
      WHERE purchaseorder     = @keys-purchaseorder
        AND purchaseorderitem = @keys-purchaseorderitem
      INTO CORRESPONDING FIELDS OF TABLE @result.

  ENDMETHOD.

  METHOD lock.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_zr_poitempricedemo DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zr_poitempricedemo IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD cleanup.
    " 트랜잭션 종료 시 버퍼 초기화
    CLEAR lcl_buffer=>mt_update.

  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

  METHOD save.

    " 변경 데이터 없으면 종료
    IF lcl_buffer=>mt_update IS INITIAL.
      RETURN.
    ENDIF.

    TYPES: BEGIN OF ty_po_group,
             purchaseorder TYPE ebeln,
           END OF ty_po_group.

    DATA lt_po_list TYPE SORTED TABLE OF ty_po_group
                    WITH UNIQUE KEY purchaseorder.

    " PO 목록 수집
    LOOP AT lcl_buffer=>mt_update INTO DATA(ls_buffer).
      INSERT VALUE #( purchaseorder = ls_buffer-purchaseorder )
        INTO TABLE lt_po_list.
    ENDLOOP.

    " PO별 처리
    LOOP AT lt_po_list INTO DATA(ls_po).

      DATA: ls_poheader  TYPE bapimepoheader,
            ls_poheaderx TYPE bapimepoheaderx,
            lt_poitem    TYPE TABLE OF bapimepoitem,
            lt_poitemx   TYPE TABLE OF bapimepoitemx,
            lt_return    TYPE TABLE OF bapiret2.

      LOOP AT lcl_buffer=>mt_update INTO DATA(ls_item)
           WHERE purchaseorder = ls_po-purchaseorder.

        " 통화 세팅
        IF ls_poheader-currency IS INITIAL
        AND ls_item-documentcurrency IS NOT INITIAL.

          ls_poheader-currency  = ls_item-documentcurrency.
          ls_poheaderx-currency = abap_true.
        ENDIF.

        " Item 값
        APPEND VALUE bapimepoitem(
          po_item   = ls_item-purchaseorderitem
          net_price = ls_item-netpriceamount
        ) TO lt_poitem.

        APPEND VALUE bapimepoitemx(
          po_item   = ls_item-purchaseorderitem
          po_itemx  = abap_true
          net_price = abap_true
        ) TO lt_poitemx.

      ENDLOOP.

      " BAPI 호출
      CALL FUNCTION 'BAPI_PO_CHANGE'
        EXPORTING
          purchaseorder    = ls_po-purchaseorder
          poheader         = ls_poheader
          poheaderx        = ls_poheaderx
          no_price_from_po = abap_true
        TABLES
          poitem           = lt_poitem
          poitemx          = lt_poitemx
          return           = lt_return.

      " 에러 처리 → RAP rollback 유도
      LOOP AT lt_return INTO DATA(ls_return) WHERE type CA 'AEX'.

        APPEND VALUE #(
          %msg = new_message(
            id       = ls_return-id
            number   = ls_return-number
            severity = if_abap_behv_message=>severity-error
            v1 = ls_return-message
           ) )
          TO reported-poitemprice.

        APPEND VALUE #(
          purchaseorder     = ls_po-purchaseorder )
          TO reported-poitemprice.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
