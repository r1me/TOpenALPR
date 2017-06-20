unit FormOpenALPRVideo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls,
  ocv.core.types_c,
  ocv.core_c,
  ocv.highgui_c,
  ocv.utils,
  openalpr;

type
  TOpenALPRVideoForm = class(TForm)
    Splitter1: TSplitter;
    panResult: TPanel;
    labResults: TLabel;
    memResults: TMemo;
    panImage: TPanel;
    StatusBar1: TStatusBar;
    PaintBox: TPaintBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    FVideoSource: pCvCapture;
    FBitmapFrame: TBitmap;
    FOpenAlpr: TOpenALPR;
    procedure OnIdle(Sender: TObject; var Done: Boolean);
  public
    { Public declarations }
    procedure DetectPlates(AImage: pIplImage);
  end;

var
  OpenALPRVideoForm: TOpenALPRVideoForm;

implementation

{$R *.dfm}

procedure TOpenALPRVideoForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Application.OnIdle := nil;
end;

procedure TOpenALPRVideoForm.FormCreate(Sender: TObject);
begin
  FOpenAlpr := TOpenALPR.Create;
  FOpenAlpr.Initialize('eu', 'openalpr.conf', 'runtime_data');
  if not FOpenAlpr.IsLoaded then
    MessageDlg('Error loading OpenALPR', mtError, [mbOk], 0);
  FBitmapFrame := TBitmap.Create;
  FBitmapFrame.PixelFormat := pf24bit;
  FVideoSource := cvCreateFileCapture('samples\eu-clip.mp4');
  Application.OnIdle := OnIdle;
end;

procedure TOpenALPRVideoForm.FormDestroy(Sender: TObject);
begin
  if Assigned(FVideoSource) then
    cvReleaseCapture(FVideoSource);
  FBitmapFrame.Free;
  FOpenAlpr.Free;
end;

procedure TOpenALPRVideoForm.OnIdle(Sender: TObject; var Done: Boolean);
var
  videoFrame: pIplImage;
begin
  videoFrame := cvQueryFrame(FVideoSource);
  if Assigned(videoFrame) then
  begin
    DetectPlates(videoFrame);
    IplImage2Bitmap(videoFrame, FBitmapFrame);
    PaintBox.Canvas.StretchDraw(PaintBox.ClientRect, FBitmapFrame);
    Done := False;
  end else
    Application.OnIdle := nil;
end;

procedure TOpenALPRVideoForm.DetectPlates(AImage: pIplImage);
var
  AResult: TOpenALPRResult;
  plate: TOpenALPRPlate;
  fs: TFormatSettings;
  i: Integer;
  font: TCvFont;
begin
  AResult := FOpenAlpr.RecognizeBuffer(AImage.imageData,
    AImage.width, AImage.height, AImage.nChannels);

  if Assigned(AResult) then
  begin
    fs.DecimalSeparator := '.';
    cvInitFont(@font, CV_FONT_HERSHEY_SIMPLEX, 1.1, 1.1, 0, 2, CV_AA);
    try
      StatusBar1.SimpleText := Format('Processing time: %1.2f ms', [AResult.ProcessingTimeMs], fs);
      for plate in AResult.Plates do
      begin
        if (plate.Confidence > 90.0) and (memResults.Lines.IndexOf(plate.Plate) = -1) then
          memResults.Lines.Add(plate.Plate);
        cvPutText(AImage, PAnsiChar(AnsiString(plate.Plate)),
          cvPoint(plate.Coordinates[0].X, plate.Coordinates[0].Y-35), @font, CV_RGB(255, 255, 0));
        for i := Low(plate.Coordinates) to High(plate.Coordinates) do
        begin
          if (i > 0) then
          begin
            cvLine(AImage,
              CvPoint(plate.Coordinates[i-1].X, plate.Coordinates[i-1].Y),
              CvPoint(plate.Coordinates[i].X, plate.Coordinates[i].Y), CV_RGB(255, 255, 0), 3);
            if (i = High(plate.Coordinates)) then
              cvLine(AImage,
                CvPoint(plate.Coordinates[i].X, plate.Coordinates[i].Y),
                CvPoint(plate.Coordinates[0].X, plate.Coordinates[0].Y), CV_RGB(255, 255, 0), 3);
          end;
        end;
      end;
    finally
      AResult.Free;
    end;
  end;
end;

end.
