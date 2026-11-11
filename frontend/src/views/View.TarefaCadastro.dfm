object FormTarefaCadastro: TFormTarefaCadastro
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Nova tarefa'
  ClientHeight = 380
  ClientWidth = 480
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlConteudo: TPanel
    Left = 0
    Top = 0
    Width = 480
    Height = 324
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 24
      Top = 20
      Width = 36
      Height = 15
      Caption = 'T'#237'tulo *'
      FocusControl = edtTitulo
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblDescricao: TLabel
      Left = 24
      Top = 80
      Width = 54
      Height = 15
      Caption = 'Descri'#231#227'o'
      FocusControl = memDescricao
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblContadorDescricao: TLabel
      Left = 356
      Top = 230
      Width = 100
      Height = 15
      Alignment = taRightJustify
      AutoSize = False
      Caption = '0 / 1000'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 9139300
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblPrioridade: TLabel
      Left = 24
      Top = 256
      Width = 58
      Height = 15
      Caption = 'Prioridade'
      FocusControl = cmbPrioridade
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object edtTitulo: TEdit
      Left = 24
      Top = 40
      Width = 432
      Height = 23
      TabOrder = 0
      TextHint = 'Ex.: Revisar contrato do fornecedor'
    end
    object memDescricao: TMemo
      Left = 24
      Top = 100
      Width = 432
      Height = 126
      ScrollBars = ssVertical
      TabOrder = 1
      OnChange = memDescricaoChange
    end
    object cmbPrioridade: TComboBox
      Left = 24
      Top = 276
      Width = 200
      Height = 23
      Style = csDropDownList
      TabOrder = 2
    end
  end
  object pnlBotoes: TPanel
    Left = 0
    Top = 324
    Width = 480
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    Color = 16381425
    ParentBackground = False
    TabOrder = 1
    object btnSalvar: TButton
      Left = 236
      Top = 12
      Width = 108
      Height = 32
      Caption = 'Salvar'
      Default = True
      TabOrder = 0
      OnClick = btnSalvarClick
    end
    object btnCancelar: TButton
      Left = 348
      Top = 12
      Width = 108
      Height = 32
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 1
    end
  end
end
