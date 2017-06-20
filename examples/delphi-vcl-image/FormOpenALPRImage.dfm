object OpenALPRImageForm: TOpenALPRImageForm
  Left = 0
  Top = 0
  Caption = 'TOpenALPR - Image'
  ClientHeight = 433
  ClientWidth = 892
  Color = clBtnFace
  Constraints.MinHeight = 460
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 647
    Top = 0
    Height = 414
    Align = alRight
    ExplicitLeft = 352
    ExplicitTop = 152
    ExplicitHeight = 100
  end
  object panResult: TPanel
    Left = 650
    Top = 0
    Width = 242
    Height = 414
    Align = alRight
    TabOrder = 0
    DesignSize = (
      242
      414)
    object labResults: TLabel
      Left = 8
      Top = 6
      Width = 39
      Height = 13
      Caption = 'Results:'
    end
    object memResults: TMemo
      Left = 8
      Top = 25
      Width = 224
      Height = 381
      Anchors = [akLeft, akTop, akRight, akBottom]
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object panImage: TPanel
    Left = 113
    Top = 0
    Width = 534
    Height = 414
    Align = alClient
    TabOrder = 1
    DesignSize = (
      534
      414)
    object pbMask: TPaintBox
      Left = 10
      Top = 6
      Width = 514
      Height = 402
      Cursor = crCross
      Anchors = [akLeft, akTop, akRight, akBottom]
      Visible = False
      OnMouseDown = pbMaskMouseDown
      OnMouseMove = pbMaskMouseMove
      OnMouseUp = pbMaskMouseUp
      OnPaint = pbMaskPaint
      ExplicitWidth = 469
      ExplicitHeight = 328
    end
    object imgOutput: TImage
      Left = 10
      Top = 6
      Width = 514
      Height = 402
      Anchors = [akLeft, akTop, akRight, akBottom]
      ExplicitWidth = 469
      ExplicitHeight = 303
    end
    object pbROI: TPaintBox
      Left = 10
      Top = 6
      Width = 514
      Height = 402
      Cursor = crCross
      Anchors = [akLeft, akTop, akRight, akBottom]
      Visible = False
      OnMouseDown = pbROIMouseDown
      OnMouseMove = pbROIMouseMove
      OnMouseUp = pbROIMouseUp
      OnPaint = pbROIPaint
      ExplicitWidth = 469
      ExplicitHeight = 328
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 414
    Width = 892
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object panTop: TPanel
    Left = 0
    Top = 0
    Width = 113
    Height = 414
    Align = alLeft
    TabOrder = 3
    object btnOpenFile: TButton
      Left = 10
      Top = 8
      Width = 92
      Height = 25
      Caption = 'Open image'
      TabOrder = 0
      OnClick = btnOpenFileClick
    end
    object btnLoadMask: TButton
      Left = 10
      Top = 81
      Width = 91
      Height = 25
      Caption = 'Load mask file'
      TabOrder = 1
      OnClick = btnLoadMaskClick
    end
    object rgMode: TRadioGroup
      Left = 10
      Top = 143
      Width = 91
      Height = 97
      Caption = 'Mode'
      ItemIndex = 0
      Items.Strings = (
        'View image'
        'Draw mask'
        'Select ROI')
      TabOrder = 2
      OnClick = rgModeClick
    end
    object btnSetMask: TButton
      Left = 10
      Top = 112
      Width = 91
      Height = 25
      Caption = 'Set mask'
      Enabled = False
      TabOrder = 3
      OnClick = btnSetMaskClick
    end
    object btnDetectPlates: TButton
      Left = 10
      Top = 39
      Width = 92
      Height = 25
      Caption = 'Detect plates'
      TabOrder = 4
      OnClick = btnDetectPlatesClick
    end
    object gbROI: TGroupBox
      Left = 10
      Top = 242
      Width = 91
      Height = 162
      TabOrder = 5
      Visible = False
      object labROIX: TLabel
        Left = 6
        Top = 15
        Width = 10
        Height = 13
        Caption = 'X:'
      end
      object labROIY: TLabel
        Left = 6
        Top = 44
        Width = 10
        Height = 13
        Caption = 'Y:'
      end
      object labROIW: TLabel
        Left = 6
        Top = 70
        Width = 14
        Height = 13
        Caption = 'W:'
      end
      object labROIH: TLabel
        Left = 6
        Top = 100
        Width = 11
        Height = 13
        Caption = 'H:'
      end
      object edROIX: TSpinEdit
        Left = 24
        Top = 12
        Width = 60
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 0
        Value = 0
      end
      object edROIH: TSpinEdit
        Left = 24
        Top = 95
        Width = 60
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 1
        Value = 0
      end
      object edROIW: TSpinEdit
        Left = 24
        Top = 67
        Width = 60
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 2
        Value = 0
      end
      object edROIY: TSpinEdit
        Left = 24
        Top = 40
        Width = 60
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 3
        Value = 0
      end
      object btnClearROI: TButton
        Left = 8
        Top = 126
        Width = 75
        Height = 25
        Caption = 'Clear'
        TabOrder = 4
        OnClick = btnClearROIClick
      end
    end
  end
  object OpenDialogImage: TOpenDialog
    Filter = 'Image files (jpg, bmp, png, gif)|*.jpg;*jpeg;*.bmp;*.png;*.gif'
    Left = 346
    Top = 152
  end
end
