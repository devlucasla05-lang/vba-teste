Attribute VB_Name = "jpa"

Option Explicit

Public Function demojpa() As Variant
    Dim products As New Bridge_Entity
    
    With products
        .Name tableName:="books"
        .Field columnName:="id", columnType:=DT_LONG, isId:=True, generateType:=UUID
        .Field columnName:="cpf", columnType:=DT_STRING, length:=255, nullable:=True
        .Field columnName:="data", columnType:=DT_DATE, nullable:=False
    End With

    Debug.Print products.ToString
End Function
