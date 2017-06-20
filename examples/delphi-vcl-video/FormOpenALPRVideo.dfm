object OpenALPRVideoForm: TOpenALPRVideoForm
  Left = 0
  Top = 0
  Caption = 'TOpenALPR - Video'
  ClientHeight = 339
  ClientWidth = 643
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 360
    Top = 0
    Height = 320
    Align = alRight
    ExplicitLeft = 352
    ExplicitTop = 152
    ExplicitHeight = 100
  end
  object panResult: TPanel
    Left = 363
    Top = 0
    Width = 280
    Height = 320
    Align = alRight
    TabOrder = 0
    DesignSize = (
      280
      320)
    object labResults: TLabel
      Left = 8
      Top = 8
      Width = 39
      Height = 13
      Caption = 'Results:'
    end
    object memResults: TMemo
      Left = 8
      Top = 27
      Width = 262
      Height = 285
      Anchors = [akLeft, akTop, akRight, akBottom]
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object panImage: TPanel
    Left = 0
    Top = 0
    Width = 360
    Height = 320
    Align = alClient
    ParentBackground = False
    TabOrder = 1
    object PaintBox: TPaintBox
      Left = 1
      Top = 1
      Width = 358
      Height = 318
      Align = alClient
      ExplicitLeft = 104
      ExplicitTop = 96
      ExplicitWidth = 105
      ExplicitHeight = 105
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 320
    Width = 643
    Height = 19
    Panels = <>
    SimplePanel = True
  end
end
