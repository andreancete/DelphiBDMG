object FormPrincipal: TFormPrincipal
  Left = 0
  Top = 0
  ActiveControl = lvTarefas
  Caption = 'BDMG - Gerenciador de Tarefas'
  ClientHeight = 640
  ClientWidth = 1000
  Color = 16381425
  Constraints.MinHeight = 560
  Constraints.MinWidth = 900
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  TextHeight = 15
  object pnlCabecalho: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 64
    Align = alTop
    BevelOuter = bvNone
    Color = 3877150
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      1000
      64)
    object lblTitulo: TLabel
      Left = 24
      Top = 10
      Width = 227
      Height = 25
      Caption = 'Gerenciador de Tarefas'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSubtitulo: TLabel
      Left = 24
      Top = 38
      Width = 279
      Height = 15
      Caption = 'Cliente VCL do servi'#231'o REST de tarefas (Horse + SQL Server)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14079702
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblStatusApi: TLabel
      Left = 680
      Top = 24
      Width = 150
      Height = 15
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      AutoSize = False
      Caption = #9679' Verificando servi'#231'o...'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14079702
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object btnAtualizar: TButton
      Left = 848
      Top = 16
      Width = 128
      Height = 32
      Anchors = [akTop, akRight]
      Caption = 'Atualizar (F5)'
      TabOrder = 0
      OnClick = btnAtualizarClick
    end
  end
  object pnlIndicadores: TPanel
    Left = 0
    Top = 64
    Width = 1000
    Height = 112
    Align = alTop
    BevelOuter = bvNone
    ParentBackground = False
    ParentColor = True
    TabOrder = 1
    object pnlCardTotal: TPanel
      Left = 24
      Top = 16
      Width = 300
      Height = 84
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      object lblCardTotalTitulo: TLabel
        Left = 16
        Top = 10
        Width = 99
        Height = 15
        Caption = 'TOTAL DE TAREFAS'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 9139300
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblTotalValor: TLabel
        Left = 16
        Top = 30
        Width = 14
        Height = 37
        Caption = '-'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3877150
        Font.Height = -27
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
    end
    object pnlCardMedia: TPanel
      Left = 340
      Top = 16
      Width = 300
      Height = 84
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      object lblCardMediaTitulo: TLabel
        Left = 16
        Top = 10
        Width = 213
        Height = 15
        Caption = 'M'#201'DIA DE PRIORIDADE DAS PENDENTES'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 9139300
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblMediaValor: TLabel
        Left = 16
        Top = 30
        Width = 14
        Height = 37
        Caption = '-'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 489433
        Font.Height = -27
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblMediaLegenda: TLabel
        Left = 110
        Top = 46
        Width = 175
        Height = 15
        Caption = 'escala: 1 Baixa ... 4 Urgente'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 9139300
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlCardConcluidas: TPanel
      Left = 656
      Top = 16
      Width = 300
      Height = 84
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 2
      object lblCardConcluidasTitulo: TLabel
        Left = 16
        Top = 10
        Width = 211
        Height = 15
        Caption = 'CONCLU'#205'DAS NOS '#218'LTIMOS 7 DIAS'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 9139300
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblConcluidasValor: TLabel
        Left = 16
        Top = 30
        Width = 14
        Height = 37
        Caption = '-'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4891414
        Font.Height = -27
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblConcluidasLegenda: TLabel
        Left = 110
        Top = 46
        Width = 140
        Height = 15
        Caption = 'pela data de conclus'#227'o'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 9139300
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
  end
  object pnlGrade: TPanel
    AlignWithMargins = True
    Left = 24
    Top = 179
    Width = 952
    Height = 373
    Margins.Left = 24
    Margins.Right = 24
    Margins.Bottom = 8
    Align = alClient
    BevelOuter = bvNone
    Color = 14800331
    Padding.Left = 1
    Padding.Top = 1
    Padding.Right = 1
    Padding.Bottom = 1
    ParentBackground = False
    TabOrder = 2
    object pnlFiltros: TPanel
      Left = 1
      Top = 1
      Width = 950
      Height = 60
      Align = alTop
      BevelOuter = bvNone
      Color = 16579320
      ParentBackground = False
      TabOrder = 0
      DesignSize = (
        950
        60)
      object lblFiltroBusca: TLabel
        Left = 12
        Top = 8
        Width = 49
        Height = 15
        Caption = 'Pesquisar'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 9139300
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblFiltroStatus: TLabel
        Left = 536
        Top = 8
        Width = 32
        Height = 15
        Caption = 'Status'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 9139300
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblFiltroPrioridade: TLabel
        Left = 354
        Top = 8
        Width = 54
        Height = 15
        Caption = 'Prioridade'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 9139300
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblContador: TLabel
        Left = 718
        Top = 30
        Width = 220
        Height = 15
        Alignment = taRightJustify
        Anchors = [akTop, akRight]
        AutoSize = False
        Caption = '0 tarefa(s) encontrada(s)'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 9139300
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object edtBusca: TEdit
        Left = 12
        Top = 26
        Width = 330
        Height = 23
        TabOrder = 0
        TextHint = 'T'#237'tulo ou descri'#231#227'o...'
        OnChange = edtBuscaChange
      end
      object cmbFiltroStatus: TComboBox
        Left = 536
        Top = 26
        Width = 170
        Height = 23
        Style = csDropDownList
        TabOrder = 2
        OnChange = cmbFiltroChange
      end
      object cmbFiltroPrioridade: TComboBox
        Left = 354
        Top = 26
        Width = 170
        Height = 23
        Style = csDropDownList
        TabOrder = 1
        OnChange = cmbFiltroChange
      end
    end
    object pnlSeparadorFiltros: TPanel
      Left = 1
      Top = 61
      Width = 950
      Height = 1
      Align = alTop
      BevelOuter = bvNone
      Color = 15788258
      ParentBackground = False
      TabOrder = 1
    end
    object lvTarefas: TListView
      Left = 1
      Top = 62
      Width = 950
      Height = 265
      Align = alClient
      BorderStyle = bsNone
      Columns = <
        item
          Caption = 'ID'
          Width = 60
        end
        item
          Caption = 'T'#237'tulo'
          Width = 380
        end
        item
          Caption = 'Prioridade'
          Width = 90
        end
        item
          Caption = 'Criada em'
          Width = 130
        end
        item
          Caption = 'Status'
          Width = 120
        end
        item
          Caption = 'Conclu'#237'da em'
          Width = 130
        end>
      HideSelection = False
      ReadOnly = True
      RowSelect = True
      PopupMenu = pmTarefas
      TabOrder = 2
      ViewStyle = vsReport
      OnKeyDown = lvTarefasKeyDown
      OnSelectItem = lvTarefasSelectItem
    end
    object pnlSeparadorPaginacao: TPanel
      Left = 1
      Top = 327
      Width = 950
      Height = 1
      Align = alBottom
      BevelOuter = bvNone
      Color = 15788258
      ParentBackground = False
      TabOrder = 3
    end
    object pnlPaginacao: TPanel
      Left = 1
      Top = 328
      Width = 950
      Height = 44
      Align = alBottom
      BevelOuter = bvNone
      Color = 16579320
      ParentBackground = False
      TabOrder = 4
      DesignSize = (
        950
        44)
      object lblPaginacao: TLabel
        Left = 124
        Top = 15
        Width = 260
        Height = 15
        Alignment = taCenter
        AutoSize = False
        Caption = 'P'#225'gina 1 de 1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3877150
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblItensPorPagina: TLabel
        Left = 752
        Top = 15
        Width = 98
        Height = 15
        Anchors = [akTop, akRight]
        Caption = 'Itens por p'#225'gina:'
      end
      object btnPaginaAnterior: TButton
        Left = 12
        Top = 8
        Width = 100
        Height = 28
        Caption = #171' Anterior'
        TabOrder = 0
      end
      object btnPaginaProxima: TButton
        Left = 396
        Top = 8
        Width = 100
        Height = 28
        Caption = 'Pr'#243'xima '#187
        TabOrder = 1
      end
      object cmbTamanhoPagina: TComboBox
        Left = 858
        Top = 11
        Width = 80
        Height = 23
        Style = csDropDownList
        Anchors = [akTop, akRight]
        TabOrder = 2
      end
    end
  end
  object pnlAcoes: TPanel
    Left = 0
    Top = 560
    Width = 1000
    Height = 57
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    ParentColor = True
    TabOrder = 3
    DesignSize = (
      1000
      57)
    object lblNovoStatus: TLabel
      Left = 180
      Top = 20
      Width = 63
      Height = 15
      Caption = 'Novo status:'
    end
    object btnNova: TButton
      Left = 24
      Top = 12
      Width = 140
      Height = 34
      Caption = '+ Nova tarefa'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      OnClick = btnNovaClick
    end
    object cmbNovoStatus: TComboBox
      Left = 252
      Top = 17
      Width = 160
      Height = 23
      Style = csDropDownList
      TabOrder = 1
    end
    object btnAlterarStatus: TButton
      Left = 420
      Top = 12
      Width = 130
      Height = 34
      Caption = 'Alterar status'
      TabOrder = 2
      OnClick = btnAlterarStatusClick
    end
    object btnRemover: TButton
      Left = 836
      Top = 12
      Width = 140
      Height = 34
      Anchors = [akTop, akRight]
      Caption = 'Remover tarefa'
      TabOrder = 3
      OnClick = btnRemoverClick
    end
  end
  object sbStatus: TStatusBar
    Left = 0
    Top = 617
    Width = 1000
    Height = 23
    Panels = <
      item
        Text = 'Pronto.'
        Width = 600
      end
      item
        Text = 'Clique direito na lista para mais a'#231#245'es | Del remove'
        Width = 400
      end>
  end
  object pmTarefas: TPopupMenu
    OnPopup = pmTarefasPopup
    Left = 512
    Top = 360
    object miMarcarPendente: TMenuItem
      Caption = 'Marcar como Pendente'
      OnClick = miMarcarStatusClick
    end
    object miMarcarEmAndamento: TMenuItem
      Caption = 'Marcar como Em andamento'
      OnClick = miMarcarStatusClick
    end
    object miMarcarConcluida: TMenuItem
      Caption = 'Marcar como Conclu'#237'da'
      OnClick = miMarcarStatusClick
    end
    object miMarcarCancelada: TMenuItem
      Caption = 'Marcar como Cancelada'
      OnClick = miMarcarStatusClick
    end
    object miSeparador: TMenuItem
      Caption = '-'
    end
    object miRemover: TMenuItem
      Caption = 'Remover tarefa'
      OnClick = miRemoverClick
    end
  end
  object tmrBusca: TTimer
    Enabled = False
    Interval = 400
    OnTimer = tmrBuscaTimer
    Left = 600
    Top = 360
  end
end
