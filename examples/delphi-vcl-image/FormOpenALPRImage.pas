unit FormOpenALPRImage;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  System.UITypes, System.IOUtils, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.Samples.Spin,
  Vcl.Imaging.pngimage, Vcl.Imaging.jpeg, Vcl.Imaging.GIFImg,
  openalpr;

type
  TOpenALPRImageForm = class(TForm)
    panResult: TPanel;
    panImage: TPanel;
    memResults: TMemo;
    btnOpenFile: TButton;
    Splitter1: TSplitter;
    labResults: TLabel;
    OpenDialogImage: TOpenDialog;
    StatusBar: TStatusBar;
    panTop: TPanel;
    btnLoadMask: TButton;
    rgMode: TRadioGroup;
    pbMask: TPaintBox;
    imgOutput: TImage;
    btnSetMask: TButton;
    btnDetectPlates: TButton;
    pbROI: TPaintBox;
    edROIX: TSpinEdit;
    edROIH: TSpinEdit;
    edROIW: TSpinEdit;
    edROIY: TSpinEdit;
    labROIX: TLabel;
    labROIY: TLabel;
    labROIW: TLabel;
    labROIH: TLabel;
    gbROI: TGroupBox;
    btnClearROI: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnOpenFileClick(Sender: TObject);
    procedure btnLoadMaskClick(Sender: TObject);
    procedure rgModeClick(Sender: TObject);
    procedure pbMaskMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbMaskMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbMaskMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure pbMaskPaint(Sender: TObject);
    procedure btnDetectPlatesClick(Sender: TObject);
    procedure btnSetMaskClick(Sender: TObject);
    procedure pbROIMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbROIMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure pbROIMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbROIPaint(Sender: TObject);
    procedure btnClearROIClick(Sender: TObject);
  private
    { Private declarations }
    FOpenAlpr: TOpenALPR;
    FDrawingMask: Boolean;
    FSelectingROI: Boolean;
    FSelectionROI: TRect;
    FDrawingMaskMode: Boolean;
    FMaskBitmap: TBitmap;
    FInputImage: TBitmap;
    procedure DrawMaskBrush(X, Y: Integer; AColor: TColor; ASize: Integer);
    function LoadImageAsBitmap(AFileName: String): TBitmap;
    procedure ShowOpenALPRResults(AResult: TOpenALPRResult);
  public
    { Public declarations }
  end;

var
  OpenALPRImageForm: TOpenALPRImageForm;

implementation

{$R *.dfm}

procedure TOpenALPRImageForm.FormCreate(Sender: TObject);
begin
  FDrawingMask := False;
  FSelectingROI := False;
  Self.DoubleBuffered := True;

  FOpenAlpr := TOpenALPR.Create;
  FOpenAlpr.Initialize('eu', 'openalpr.conf', 'runtime_data');
  if not FOpenAlpr.IsLoaded then
    MessageDlg('Error loading OpenALPR', mtError, [mbOk], 0)
  else
    memResults.Lines.Add('OpenALPR loaded successfully');

  FMaskBitmap := TBitmap.Create;
  FMaskBitmap.PixelFormat := pf8bit;
  FMaskBitmap.Width := MAX_DETECTION_INPUT_WIDTH;
  FMaskBitmap.Height := MAX_DETECTION_INPUT_HEIGHT;
  FMaskBitmap.Canvas.Brush.Color := clBlack;
  FMaskBitmap.Canvas.FillRect(FMaskBitmap.Canvas.ClipRect);
  FInputImage := TBitmap.Create;
end;

procedure TOpenALPRImageForm.FormDestroy(Sender: TObject);
begin
  FOpenAlpr.Free;
  FMaskBitmap.Free;
  FInputImage.Free;
end;

procedure TOpenALPRImageForm.btnClearROIClick(Sender: TObject);
begin
  edROIX.Value := 0;
  edROIY.Value := 0;
  edROIW.Value := 0;
  edROIH.Value := 0;
  FSelectionROI.Width := 0;
  FSelectionROI.Height := 0;
  pbROI.Invalidate;
end;

procedure TOpenALPRImageForm.btnDetectPlatesClick(Sender: TObject);
var
  roi: TAlprCRegionOfInterest;
begin
  if FInputImage.Width = 0 then Exit;

  rgMode.ItemIndex := 0;
  if (edROIX.Value <> 0) or
     (edROIY.Value <> 0) or
     (edROIW.Value <> 0) or
     (edROIH.Value <> 0) then
  begin
    roi := TAlprCRegionOfInterest.CreateROI(edROIX.Value, edROIY.Value, edROIW.Value, edROIH.Value);
    ShowOpenALPRResults(FOpenAlpr.RecognizeBitmap(FInputImage, @roi));
  end else
    ShowOpenALPRResults(FOpenAlpr.RecognizeBitmap(FInputImage));
end;

procedure TOpenALPRImageForm.btnLoadMaskClick(Sender: TObject);
var
  bmpMask: TBitmap;
begin
  if OpenDialogImage.Execute then
  begin
    bmpMask := LoadImageAsBitmap(OpenDialogImage.FileName);
    try
      FMaskBitmap.Assign(bmpMask);
      pbMask.Invalidate;
    finally
      bmpMask.Free;
    end;
  end;

  rgMode.ItemIndex := 1;
  btnSetMask.Enabled := False;
  FOpenAlpr.SetMask(FMaskBitmap);
end;

procedure TOpenALPRImageForm.btnOpenFileClick(Sender: TObject);
begin
  if OpenDialogImage.Execute then
  begin
    StatusBar.SimpleText := OpenDialogImage.FileName;
    if Assigned(FInputImage) then
      FInputImage.Free;
    FInputImage := LoadImageAsBitmap(OpenDialogImage.FileName);
    imgOutput.Picture.Assign(FInputImage);
    memResults.Clear;
    rgMode.ItemIndex := 0;
  end;
end;

procedure TOpenALPRImageForm.btnSetMaskClick(Sender: TObject);
begin
  btnSetMask.Enabled := False;
  FOpenAlpr.SetMask(FMaskBitmap);
end;

function TOpenALPRImageForm.LoadImageAsBitmap(AFileName: String): TBitmap;
var
  img: TPicture;
begin
  Result := TBitmap.Create;

  img := TPicture.Create;
  try
    img.LoadFromFile(AFileName);
    Result.Assign(img.Graphic);
  finally
    img.Free;
  end;
end;

procedure TOpenALPRImageForm.ShowOpenALPRResults(AResult: TOpenALPRResult);
var
  plate: TOpenALPRPlate;
  plateCandidate: TOpenALPRPlateCandidate;
  fs: TFormatSettings;
  i: Integer;
begin
  fs.DecimalSeparator := '.';

  memResults.Lines.BeginUpdate;
  try
    memResults.Clear;

    imgOutput.Picture.Assign(FInputImage);

    imgOutput.Canvas.Brush.Style := bsClear;
    imgOutput.Canvas.Pen.Color := clYellow;
    imgOutput.Canvas.Pen.Width := 4;
    imgOutput.Canvas.Pen.Style := psSolid;
    imgOutput.Canvas.Font.Size := 16;
    imgOutput.Canvas.Font.Color := clYellow;

    memResults.Lines.Add(Format('Processing time: %1.2f ms', [AResult.ProcessingTimeMs], fs));

    for plate in AResult.Plates do
    begin
      memResults.Lines.Add(Format('Plate: %s - Confidence: %1.2f %%', [plate.Plate, plate.Confidence], fs));
      for plateCandidate in plate.Candidates do
        memResults.Lines.Add(Format('   Candidate: %s (%1.2f %%)', [plateCandidate.Plate, plateCandidate.Confidence], fs));

      imgOutput.Canvas.TextOut(plate.Coordinates[0].X, plate.Coordinates[0].Y-35, plate.Plate);
      for i := Low(plate.Coordinates) to High(plate.Coordinates) do
      begin
        if (i = 0) then
          imgOutput.Canvas.MoveTo(plate.Coordinates[0].X, plate.Coordinates[0].Y)
        else
        begin
          imgOutput.Canvas.LineTo(plate.Coordinates[i].X, plate.Coordinates[i].Y);
          if (i = High(plate.Coordinates)) then
            imgOutput.Canvas.LineTo(plate.Coordinates[0].X, plate.Coordinates[0].Y);
        end;
      end;
    end;
  finally
    memResults.Lines.EndUpdate;
    AResult.Free;
  end;
end;

procedure TOpenALPRImageForm.DrawMaskBrush(X, Y: Integer; AColor: TColor; ASize: Integer);
begin
  FMaskBitmap.Canvas.Pen.Color := AColor;
  FMaskBitmap.Canvas.Pen.Style := psSolid;
  FMaskBitmap.Canvas.Pen.Width := ASize;
  FMaskBitmap.Canvas.Ellipse(X, Y, X+ASize, Y+ASize);
end;

procedure TOpenALPRImageForm.pbMaskMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) or (Button = mbRight) then
  begin
    FDrawingMask := True;
    FDrawingMaskMode := (Button = mbLeft);
    if FDrawingMaskMode then
      DrawMaskBrush(X, Y, clWhite, 15)
    else
      DrawMaskBrush(X, Y, clBlack, 15);
    pbMask.Invalidate;
  end;

  if (Button = mbMiddle) then
  begin
    FDrawingMaskMode := not FDrawingMaskMode;
    if FDrawingMaskMode then
      FMaskBitmap.Canvas.Brush.Color := clWhite
    else
      FMaskBitmap.Canvas.Brush.Color := clBlack;
    FMaskBitmap.Canvas.Brush.Style := bsSolid;
    FMaskBitmap.Canvas.FillRect(FMaskBitmap.Canvas.ClipRect);
  end;
end;

procedure TOpenALPRImageForm.pbMaskMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  if FDrawingMask then
  begin
    if FDrawingMaskMode then
      DrawMaskBrush(X, Y, clWhite, 15)
    else
      DrawMaskBrush(X, Y, clBlack, 15);
    pbMask.Invalidate;
  end;
end;

procedure TOpenALPRImageForm.pbMaskMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FDrawingMask := False;
  pbMask.Invalidate;
end;

procedure TOpenALPRImageForm.pbMaskPaint(Sender: TObject);
begin
  pbMask.Canvas.Draw(0, 0, FMaskBitmap);
end;

procedure TOpenALPRImageForm.pbROIMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FSelectionROI.Left := X;
  FSelectionROI.Top := Y;
  FSelectingROI := True;
end;

procedure TOpenALPRImageForm.pbROIMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if FSelectingROI then
  begin
    FSelectionROI.Right := X;
    FSelectionROI.Bottom := Y;
    pbROI.Invalidate;
  end;
end;

procedure TOpenALPRImageForm.pbROIMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FSelectingROI := False;
  FSelectionROI.Right := X;
  FSelectionROI.Bottom := Y;
  pbROI.Invalidate;

  FSelectionROI.NormalizeRect;

  edROIX.Value := FSelectionROI.Left;
  edROIY.Value := FSelectionROI.Top;
  edROIW.Value := FSelectionROI.Width;
  edROIH.Value := FSelectionROI.Height;
end;

procedure TOpenALPRImageForm.pbROIPaint(Sender: TObject);
begin
  pbROI.Canvas.Draw(0, 0, FInputImage);
  pbROI.Canvas.Brush.Style := bsClear;
  pbROI.Canvas.Pen.Style := psSolid;
  pbROI.Canvas.Pen.Color := clRed;
  pbROI.Canvas.Rectangle(FSelectionROI);
end;

procedure TOpenALPRImageForm.rgModeClick(Sender: TObject);
begin
  case rgMode.ItemIndex of
    0:
      begin
        pbMask.Visible := False;
        pbROI.Visible := False;
        imgOutput.Visible := True;
        btnSetMask.Enabled := False;
        gbROI.Visible := False;
      end;
    1:
      begin
        if (imgOutput.Picture.Bitmap.Width <> 0) and
          (imgOutput.Picture.Bitmap.Height <> 0) then
        begin
          FMaskBitmap.Width := imgOutput.Picture.Bitmap.Width;
          FMaskBitmap.Height := imgOutput.Picture.Bitmap.Height;
        end;
        pbROI.Visible := False;
        pbMask.Visible := True;
        imgOutput.Visible := False;
        btnSetMask.Enabled := True;
        gbROI.Visible := False;
      end;
    2:
      begin
        pbMask.Visible := False;
        pbROI.Visible := True;
        imgOutput.Visible := False;
        btnSetMask.Enabled := False;
        gbROI.Visible := True;
      end;
  end;
end;

end.
