VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "BridgeObjectManager"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Const BOM_FILENAME As String = "bom.json"
Private rootPath As String
Private bomFilePath As String

Private Sub Class_Initialize()
    On Error GoTo catch
    
    rootPath = getRootPath()
    bomFilePath = rootPath & Application.PathSeparator & BOM_FILENAME
    
    Exit Sub
catch:
    Dim ex As New Exception
        ex.init Err.Description, Err.source, Err.Number
    ExceptionHandler ex
End Sub

Public Sub init()
    On Error GoTo catch
    
    If bomFileExists() Then
        throw New BomAlreadyExistsException
    End If
    
    setupProject
    Exit Sub
catch:
    Dim ex As New Exception
        ex.init Err.Description, Err.source, Err.Number
    ExceptionHandler ex
End Sub

Public Function content() As String
    If Not bomFileExists() Then
        throw New ProjectNotInitializedException
    End If
    
    content = readFileContent(filePath:=bomFilePath)
End Function

Public Sub recreate(Optional ByVal jsonContent As Object)
    On Error GoTo catch

    If bomFileExists() Then
        setupProject jsonContent:=jsonContent
        Exit Sub
    End If
    
    throw New ProjectNotInitializedException
catch:
    Dim ex As New Exception
        ex.init Err.Description, Err.source, Err.Number
    ExceptionHandler ex
End Sub

Private Sub setupProject(Optional ByVal jsonContent As Object)
    If jsonContent Is Nothing Then
        Call generateFile(bomFilePath, buildContent())
    Else
        Call generateFile(bomFilePath, JsonConverter.ConvertToJson(jsonContent))
    End If
    
    Call animLogo
    
    Dim props As New BridgeProperties
    props.init
End Sub

Private Function getRootPath() As String
    Dim fso As Object: Set fso = CreateObject("Scripting.FileSystemObject")
    Dim currentPath As String
    Dim folder As Object
    
    currentPath = IIf(ThisWorkbook.path = "", CurDir$, ThisWorkbook.path)
    
    Do
        If fso.FolderExists(currentPath & Application.PathSeparator & "src") Then
            getRootPath = currentPath
            Exit Function
        End If
        
        Set folder = fso.GetFolder(currentPath)
        
        If folder.ParentFolder Is Nothing Then
            throw New InvalidRootFolderException
        End If
        
        currentPath = folder.ParentFolder.path
    Loop
End Function

Private Sub generateFile(ByVal filePath As String, ByVal content As String)
    Dim fileNum As Integer
    
    On Error GoTo catch
    
    fileNum = FreeFile
    
    Open filePath For Output As #fileNum
        Print #fileNum, content
    Close #fileNum
    Exit Sub
catch:
    throw New FailedToGenerateBomException
End Sub

Public Function buildContent() As String
    Dim body As New ResponseBody
    Dim projectBody As New ResponseBody
    Dim bridgeBody As New ResponseBody
    Dim dependenciesBody As New ResponseBody
    Dim structureBody As New ResponseBody
 
    With projectBody
        .addValue key:="uuid", value:=generateUUID()
        .addValue key:="name", value:="my-example-project"
        .addValue key:="version", value:="1.0.0"
        .addValue key:="description", value:="A VBA application using the Bridge Framework."
        .addValue key:="author", value:=""
        .addValue key:="createAt", value:=Format(Now(), "yyyy-mm-dd")
        .addValue key:="license", value:=""
    End With
    
    With structureBody
        .addValue key:="workbookPath", value:="src/workbook/" & ThisWorkbook.name
        .addValue key:="resourcesPath", value:="src/resources"
        .addValue "libsPath", "src/resources/lib"
    End With
    
    With bridgeBody
        .addValue key:="version", value:=APP_VERSION
        .addValue key:="runtime", value:="VBA"
        .addValue key:="structure", value:=structureBody.getBody
    End With
        
    With body
        .addValue "project", projectBody.getBody
        .addValue "bridge", bridgeBody.getBody
        .addValue "dependencies", dependenciesBody.getBody
    End With
        
    buildContent = JsonConverter.ConvertToJson(body.getBody, Whitespace:=2)
End Function

Private Function readFileContent(ByVal filePath As String) As String
    Dim fileNum As Integer
    Dim content As String
    
    On Error GoTo catch
    
    fileNum = FreeFile
    Open filePath For Input As #fileNum
        content = Input$(LOF(fileNum), #fileNum)
    Close #fileNum
    
    readFileContent = content
    Exit Function
catch:
    throw New FailedToReadBomException
End Function

Public Function bomFileExists() As Boolean
    bomFileExists = CreateObject("Scripting.FileSystemObject").FileExists(bomFilePath)
End Function

Public Function parseBomContent(ByVal fileContent As String) As Object
    On Error GoTo catch
    Set parseBomContent = JsonConverter.ParseJson(fileContent)
    Exit Function
catch:
    throw New InvalidJsonManifestException
End Function
