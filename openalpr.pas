unit openalpr;

{ The MIT License (MIT) 
 
 TOpenALPR 
 Copyright (c) 2017 Damian Woroch, http://r1me.pl 
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions: 
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software. 
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE. }

interface
uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.Generics.Collections,
  Vcl.Graphics;

type
  TAlpr = Pointer;

type
  TAlprCRegionOfInterest = packed record
    x: Integer;
    y: Integer;
    width: Integer;
    height: Integer;
    constructor CreateROI(Ax, Ay, Awidth, Aheight: Integer);
  end;
  PAlprCRegionOfInterest = ^TAlprCRegionOfInterest;

const
  libopenalpr = 'openalpr.dll';

type
  Tfnopenalpr_init = function(const country: PUTF8Char; const configFile: PUTF8Char; const runtimeDir: PUTF8Char): TAlpr; cdecl;
  Tfnopenalpr_is_loaded = function(instance: TAlpr): Boolean; cdecl;
  Tfnopenalpr_set_country = procedure(instance: TAlpr; const country: PUTF8Char); cdecl;
  Tfnopenalpr_set_prewarp = procedure(instance: TAlpr; const prewarp_config: PUTF8Char); cdecl;
  Tfnopenalpr_set_mask = procedure(instance: TAlpr; pixelData: Pointer; bytesPerPixel, imgWidth, imgHeight: Integer); cdecl;
  Tfnopenalpr_set_detect_region = procedure(instance: TAlpr; detectRegion: Boolean); cdecl;
  Tfnopenalpr_set_topn = procedure(instance: TAlpr; topN: Integer); cdecl;
  Tfnopenalpr_set_default_region = procedure(instance: TAlpr; const region: PUTF8Char); cdecl;
  Tfnopenalpr_recognize_rawimage = function(instance: TAlpr; pixelData: Pointer; bytesPerPixel, imgWidth, imgHeight: Integer; roi: TAlprCRegionOfInterest): PUTF8Char; cdecl;
  Tfnopenalpr_recognize_encodedimage = function(instance: TAlpr; bytes: Pointer; len: Int64; roi: TAlprCRegionOfInterest): PUTF8Char; cdecl;
  Tfnopenalpr_free_response_string = procedure(response: PUTF8Char); cdecl;
  Tfnopenalpr_cleanup = procedure(instance: TAlpr); cdecl;

type
  TPlateCoordinates = array[0..3] of TPoint;

type
  TOpenALPRPlateCandidate = class(TObject)
  private
    FPlate: String;
    FConfidence: Single;
    FMatchesTemplate: Boolean;
  public
    property Plate: String read FPlate;
    property Confidence: Single read FConfidence;
    property MatchesTemplate: Boolean read FMatchesTemplate;
    constructor Create(APlate: String; AConfidence: Single; AMatchesTemplate: Boolean);
  end;
  TOpenALPRPlateCandidates = TObjectList<TOpenALPRPlateCandidate>;

type
  TOpenALPRPlate = class(TObject)
  private
    FCandidates: TOpenALPRPlateCandidates;
  public
    Plate: String;
    Confidence: Single;
    MatchesTemplate: Boolean;
    PlateIndex: Integer;
    Region: String;
    RegionConfidence: Single;
    ProcessingTimeMs: Single;
    Coordinates: TPlateCoordinates;
    property Candidates: TOpenALPRPlateCandidates read FCandidates;
    procedure AddCandidate(APlate: String; AConfidence: Single; AMatchesTemplate: Boolean);
    constructor Create;
    destructor Destroy; override;
  end;
  TOpenALPRPlates = TObjectList<TOpenALPRPlate>;

type
  TOpenALPRResult = class(TObject)
  private
    FProcessingTimeMs: Single;
    FPlates: TOpenALPRPlates;
  public
    property ProcessingTimeMs: Single read FProcessingTimeMs;
    property Plates: TOpenALPRPlates read FPlates write FPlates;
    procedure ParseJSON(AJSON: String);
    constructor Create;
    destructor Destroy; override;
  end;

type
  TOpenALPR = class(TObject)
  protected
    FOpenALPRInstance: TAlpr;
    FLibOpenALPR: THandle;
    FDetectionMask: TMemoryStream;
    function InitOpenAlprLib: Boolean;
    procedure FreeOpenAlprLib;
  private
    openalpr_init: Tfnopenalpr_init;
    openalpr_is_loaded: Tfnopenalpr_is_loaded;
    openalpr_set_country: Tfnopenalpr_set_country;
    openalpr_set_prewarp: Tfnopenalpr_set_prewarp;
    openalpr_set_mask: Tfnopenalpr_set_mask;
    openalpr_set_detect_region: Tfnopenalpr_set_detect_region;
    openalpr_set_topn: Tfnopenalpr_set_topn;
    openalpr_set_default_region: Tfnopenalpr_set_default_region;
    openalpr_recognize_rawimage: Tfnopenalpr_recognize_rawimage;
    openalpr_recognize_encodedimage: Tfnopenalpr_recognize_encodedimage;
    openalpr_free_response_string: Tfnopenalpr_free_response_string;
    openalpr_cleanup: Tfnopenalpr_cleanup;
    function JSONBufferToString(pJSON: PUTF8Char): String;
    function BitmapToMemoryBuffer(const ABitmap: Vcl.Graphics.TBitmap; out ABytesPerPixel: Integer): TMemoryStream;
    function PROIToROI(AROI: PAlprCRegionOfInterest; AX, AY, AWidth, AHeight: Integer): TAlprCRegionOfInterest;
  public
    // Initializes OpenALPR library
    function Initialize(ACountry, AConfigFile, ARuntimeDir: String): Boolean;
    // Is OpenALPR loaded successfully ?
    function IsLoaded: Boolean;
    // The top number of possible plates to return (with confidences)
    procedure SetTopN(ATopN: Integer);
    // Experimental, tries to detect plate region
    procedure SetDetectRegion(ADetectRegion: Boolean);
    // A region for pattern matching. This improves accuracy by
    // comparing the plate text with the regional pattern
    procedure SetDefaultRegion(ADefaultRegion: String);
    // Prewarp angle setting, use openalpr-utils-calibrate tool to create one
    procedure SetPrewarp(APrewarp: String);
    // Allows to change country, once initialized
    procedure SetCountry(ACountry: String);
    // Update the detection mask without reloading the library
    procedure SetMask(const AFileName: String); overload;
    procedure SetMask(const ABitmap: Vcl.Graphics.TBitmap); overload;
    // Recognizes plates from a file. Formats supported by OpenALPR
    function RecognizeFile(AFileName: String; AROI: PAlprCRegionOfInterest = nil): TOpenALPRResult;
    // Recognizes plates from a bitmap
    function RecognizeBitmap(const ABitmap: Vcl.Graphics.TBitmap; AROI: PAlprCRegionOfInterest = nil): TOpenALPRResult;
    // Recognizes plates from a image buffer, useful for video streams as input
    function RecognizeBuffer(const ABuffer: Pointer; AImageWidth, AImageHeight: Integer; ABytesPerPixel: Integer = 3; AROI: PAlprCRegionOfInterest = nil): TOpenALPRResult;

    constructor Create;
    destructor Destroy; override;
  end;

var
  MAX_DETECTION_INPUT_WIDTH: Integer = 1280;
  MAX_DETECTION_INPUT_HEIGHT: Integer = 720;

{.$DEFINE FirstDetectionDelayFix}

implementation
uses
  System.JSON;

{ TAlprCRegionOfInterest }

constructor TAlprCRegionOfInterest.CreateROI(Ax, Ay, Awidth, Aheight: Integer);
begin
  x := Ax;
  y := Ay;
  width := Awidth;
  height := Aheight;
end;

{ TOpenALPR }

constructor TOpenALPR.Create;
begin
  FOpenALPRInstance := nil;
  FLibOpenALPR := 0;
  FDetectionMask := TMemoryStream.Create;
end;

destructor TOpenALPR.Destroy;
begin
  if Assigned(FOpenALPRInstance) then
    openalpr_cleanup(FOpenALPRInstance);
  FreeOpenAlprLib;
  FDetectionMask.Free;
  inherited Destroy;
end;

function TOpenALPR.InitOpenAlprLib: Boolean;
begin
  Result := False;

  if (FLibOpenALPR = 0) then
  begin
    FLibOpenALPR := LoadLibrary(PChar(libopenalpr));
    if (FLibOpenALPR <> 0) then
    begin
      @openalpr_init := GetProcAddress(FLibOpenALPR, 'openalpr_init');
      @openalpr_is_loaded := GetProcAddress(FLibOpenALPR, 'openalpr_is_loaded');
      @openalpr_set_country := GetProcAddress(FLibOpenALPR, 'openalpr_set_country');
      @openalpr_set_prewarp := GetProcAddress(FLibOpenALPR, 'openalpr_set_prewarp');
      @openalpr_set_mask := GetProcAddress(FLibOpenALPR, 'openalpr_set_mask');
      @openalpr_set_detect_region := GetProcAddress(FLibOpenALPR, 'openalpr_set_detect_region');
      @openalpr_set_topn := GetProcAddress(FLibOpenALPR, 'openalpr_set_topn');
      @openalpr_set_default_region := GetProcAddress(FLibOpenALPR, 'openalpr_set_default_region');
      @openalpr_recognize_rawimage := GetProcAddress(FLibOpenALPR, 'openalpr_recognize_rawimage');
      @openalpr_recognize_encodedimage := GetProcAddress(FLibOpenALPR, 'openalpr_recognize_encodedimage');
      @openalpr_free_response_string := GetProcAddress(FLibOpenALPR, 'openalpr_free_response_string');
      @openalpr_cleanup := GetProcAddress(FLibOpenALPR, 'openalpr_cleanup');

      Result := Assigned(openalpr_init) and
                Assigned(openalpr_is_loaded) and
                Assigned(openalpr_set_country) and
                Assigned(openalpr_set_prewarp) and
                Assigned(openalpr_set_mask) and
                Assigned(openalpr_set_detect_region) and
                Assigned(openalpr_set_topn) and
                Assigned(openalpr_set_default_region) and
                Assigned(openalpr_recognize_rawimage) and
                Assigned(openalpr_recognize_encodedimage) and
                Assigned(openalpr_free_response_string) and
                Assigned(openalpr_cleanup);

      if not Result then
        FreeOpenAlprLib;
    end;
  end;
end;

procedure TOpenALPR.FreeOpenAlprLib;
begin
  if (FLibOpenALPR <> 0) then
  begin
    FreeLibrary(FLibOpenALPR);
    FLibOpenALPR := 0;
  end;
end;

function TOpenALPR.Initialize(ACountry, AConfigFile, ARuntimeDir: String): Boolean;
var
  configFile: TStringList;
  iw, ih: integer;
  {$IFDEF FirstDetectionDelayFix}
  roi: TAlprCRegionOfInterest;
  res: PUTF8Char;
  buff: Pointer;
  {$ENDIF}
begin
  Result := False;

  if not InitOpenAlprLib then
    raise Exception.Create('Unable to load ' + libopenalpr + ' library');
  if (FLibOpenALPR = 0) then Exit;
  if Assigned(FOpenALPRInstance) then
    raise Exception.Create('TOpenALPR is already initialized');
  FOpenALPRInstance := openalpr_init(PUTF8Char(UTF8Encode(ACountry)),
    PUTF8Char(UTF8Encode(AConfigFile)), PUTF8Char(UTF8Encode(ARuntimeDir)));
  if Assigned(FOpenALPRInstance) then
  begin
    configFile := TStringList.Create;
    try
      try
        configFile.LoadFromFile(AConfigFile);
        configFile.Sort;
        iw := -1;
        ih := -1;
        configFile.Find('max_detection_input_width =', iw);
        if (iw <> -1) then
          MAX_DETECTION_INPUT_WIDTH := StrToInt(Trim(configFile.ValueFromIndex[iw]));
        configFile.Find('max_detection_input_height =', ih);
        if (ih <> -1) then
          MAX_DETECTION_INPUT_HEIGHT := StrToInt(Trim(configFile.ValueFromIndex[ih]));
      except
      end;
    finally
      configFile.Free;
    end;

    {$IFDEF FirstDetectionDelayFix}
    roi.x := 0;
    roi.y := 0;
    roi.width := 100;
    roi.height := 100;
    GetMem(buff, 100 * 100 * 3);
    try
      res := openalpr_recognize_rawimage(FOpenALPRInstance, buff, 3, 100, 100, roi);
      openalpr_free_response_string(res);
    finally
      FreeMem(buff);
    end;
    {$ENDIF}

    Result := openalpr_is_loaded(FOpenALPRInstance);
  end;
end;

function TOpenALPR.IsLoaded: Boolean;
begin
  Result := False;
  if Assigned(FOpenALPRInstance) then
    Result := openalpr_is_loaded(FOpenALPRInstance);
end;

procedure TOpenALPR.SetTopN(ATopN: Integer);
begin
  if Assigned(FOpenALPRInstance) then
    openalpr_set_topn(FOpenALPRInstance, ATopN);
end;

procedure TOpenALPR.SetDetectRegion(ADetectRegion: Boolean);
begin
  if Assigned(FOpenALPRInstance) then
    openalpr_set_detect_region(FOpenALPRInstance, ADetectRegion);
end;

procedure TOpenALPR.SetDefaultRegion(ADefaultRegion: String);
begin
  if Assigned(FOpenALPRInstance) then
    openalpr_set_default_region(FOpenALPRInstance, PUTF8Char(UTF8Encode(ADefaultRegion)));
end;

procedure TOpenALPR.SetPrewarp(APrewarp: String);
begin
  if Assigned(FOpenALPRInstance) then
    openalpr_set_prewarp(FOpenALPRInstance, PUTF8Char(UTF8Encode(APrewarp)));
end;

procedure TOpenALPR.SetCountry(ACountry: String);
begin
  if Assigned(FOpenALPRInstance) then
    openalpr_set_country(FOpenALPRInstance, PUTF8Char(UTF8Encode(ACountry)));
end;

procedure TOpenALPR.SetMask(const ABitmap: Vcl.Graphics.TBitmap);
var
  msBitmap: TMemoryStream;
  bytesPerPixel: Integer;
begin
  if Assigned(FOpenALPRInstance) then
  begin
    msBitmap := BitmapToMemoryBuffer(ABitmap, bytesPerPixel);
    try
      if (msBitmap.Size = 0) then Exit;
      msBitmap.Position := 0;
      FDetectionMask.Clear;
      FDetectionMask.CopyFrom(msBitmap, msBitmap.Size);
      openalpr_set_mask(FOpenALPRInstance, FDetectionMask.Memory,
        bytesPerPixel, ABitmap.width, ABitmap.height);
    finally
      msBitmap.Free;
    end;
  end;
end;

procedure TOpenALPR.SetMask(const AFileName: String);
var
  bmpMask: TBitmap;
  picMask: TPicture;
  msBitmap: TMemoryStream;
  bytesPerPixel: Integer;
begin
  if Assigned(FOpenALPRInstance) then
  begin
    picMask := TPicture.Create;
    try
      picMask.LoadFromFile(AFileName);
      bmpMask := TBitmap.Create;
      try
        bmpMask.Assign(picMask.Graphic);
        msBitmap := BitmapToMemoryBuffer(bmpMask, bytesPerPixel);
        try
          if (msBitmap.Size = 0) then Exit;
          msBitmap.Position := 0;
          FDetectionMask.Clear;
          FDetectionMask.CopyFrom(msBitmap, msBitmap.Size);
          openalpr_set_mask(FOpenALPRInstance, FDetectionMask.Memory, bytesPerPixel,
            bmpMask.width, bmpMask.height);
        finally
          msBitmap.Free;
        end;
      finally
        bmpMask.Free;
      end;
    finally
      picMask.Free;
    end;
  end;
end;

function TOpenALPR.RecognizeFile(AFileName: String; AROI: PAlprCRegionOfInterest = nil): TOpenALPRResult;
var
  pJson: PUTF8Char;
  msEncodedImage: TMemoryStream;
  fsImageFile: TFileStream;
  roi: TAlprCRegionOfInterest;
begin
  Result := TOpenALPRResult.Create;
  if Assigned(FOpenALPRInstance) then
  begin
    msEncodedImage := TMemoryStream.Create;
    fsImageFile := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      msEncodedImage.CopyFrom(fsImageFile, fsImageFile.Size);
      roi := PROIToROI(AROI, 0, 0, MAX_DETECTION_INPUT_WIDTH, MAX_DETECTION_INPUT_HEIGHT);
      pJSON := openalpr_recognize_encodedimage(FOpenALPRInstance, msEncodedImage.Memory, msEncodedImage.Size, roi);
      Result.ParseJSON(JSONBufferToString(pJSON));
    finally
      fsImageFile.Free;
      msEncodedImage.Free;
    end;
  end;
end;

function TOpenALPR.RecognizeBitmap(const ABitmap: Vcl.Graphics.TBitmap; AROI: PAlprCRegionOfInterest = nil): TOpenALPRResult;
var
  pJSON: PUTF8Char;
  msBitmap: TMemoryStream;
  bytesPerPixel: Integer;
  roi: TAlprCRegionOfInterest;
begin
  Result := TOpenALPRResult.Create;

  if Assigned(FOpenALPRInstance) then
  begin
    msBitmap := BitmapToMemoryBuffer(ABitmap, bytesPerPixel);
    try
      if (msBitmap.Size = 0) then Exit;
      roi := PROIToROI(AROI, 0, 0, ABitmap.width, ABitmap.height);
      pJSON := openalpr_recognize_rawimage(FOpenALPRInstance, msBitmap.Memory,
        bytesPerPixel, ABitmap.width, ABitmap.height, roi);
      Result.ParseJSON(JSONBufferToString(pJSON));
    finally
      msBitmap.Free;
    end;
  end;
end;

function TOpenALPR.RecognizeBuffer(const ABuffer: Pointer; AImageWidth, AImageHeight: Integer;
  ABytesPerPixel: Integer = 3; AROI: PAlprCRegionOfInterest = nil): TOpenALPRResult;
var
  pJSON: PUTF8Char;
  roi: TAlprCRegionOfInterest;
begin
  Result := TOpenALPRResult.Create;
  if Assigned(FOpenALPRInstance) and Assigned(ABuffer) then
  begin
    roi := PROIToROI(AROI, 0, 0, AImageWidth, AImageHeight);
    pJSON := openalpr_recognize_rawimage(FOpenALPRInstance, ABuffer, ABytesPerPixel, AImageWidth, AImageHeight, roi);
    Result.ParseJSON(JSONBufferToString(pJSON));
  end;
end;

function TOpenALPR.PROIToROI(AROI: PAlprCRegionOfInterest; AX, AY, AWidth, AHeight: Integer): TAlprCRegionOfInterest;
begin
  if Assigned(AROI) then
  begin
    Result := AROI^;
  end else
  begin
    Result.x := AX;
    Result.y := AY;
    Result.width := AWidth;
    Result.height := AHeight;
  end;
end;

function TOpenALPR.BitmapToMemoryBuffer(const ABitmap: Vcl.Graphics.TBitmap;
  out ABytesPerPixel: Integer): TMemoryStream;
var
  msBitmap: TMemoryStream;
  pixels: PByteArray;
  y: Integer;
  bytesPerPixel: Integer;
begin
  msBitmap := TMemoryStream.Create;
  bytesPerPixel := 0;

  if Assigned(ABitmap) then
  begin
    case ABitmap.PixelFormat of
      pf8bit: bytesPerPixel := 1;
      pf16bit: bytesPerPixel := 2;
      pf24bit: bytesPerPixel := 3;
      pf32bit: bytesPerPixel := 4;
      else
        raise Exception.Create('Unsupported bitmap format');
    end;

    for y := 0 to ABitmap.Height-1 do
    begin
      pixels := ABitmap.ScanLine[y];
      msBitmap.Write(pixels^, ABitmap.Width * bytesPerPixel);
    end;
  end;

  ABytesPerPixel := bytesPerPixel;
  Result := msBitmap;
end;

function TOpenALPR.JSONBufferToString(pJSON: PUTF8Char): String;
var
  utfJSON: UTF8String;
begin
  Result := '';
  if Assigned(pJSON) then
  begin
    SetString(utfJSON, pJSON, Length(pJSON));
    openalpr_free_response_string(pJSON);
    Result := String(utfJSON);
  end;
end;

{ TOpenALPRPlateCandidate }

constructor TOpenALPRPlateCandidate.Create(APlate: String; AConfidence: Single;
  AMatchesTemplate: Boolean);
begin
  FPlate := APlate;
  FConfidence := AConfidence;
  FMatchesTemplate := AMatchesTemplate;
end;

{ TOpenALPRPlate }

constructor TOpenALPRPlate.Create;
begin
  FCandidates := TOpenALPRPlateCandidates.Create;
end;

destructor TOpenALPRPlate.Destroy;
begin
  FCandidates.Free;
  inherited Destroy;
end;

procedure TOpenALPRPlate.AddCandidate(APlate: String; AConfidence: Single; AMatchesTemplate: Boolean);
begin
  FCandidates.Add(TOpenALPRPlateCandidate.Create(APlate, AConfidence, AMatchesTemplate));
end;

{ TOpenALPRResult }

constructor TOpenALPRResult.Create;
begin
  FPlates := TOpenALPRPlates.Create;
  FProcessingTimeMs := 0;
end;

destructor TOpenALPRResult.Destroy;
begin
  FPlates.Free;
  inherited Destroy;
end;

procedure TOpenALPRResult.ParseJSON(AJSON: String);
var
  jsonObj: TJSONObject;
  plates: TJSONArray;
  candidates, coordinates: TJSONArray;
  candidate: TJsonValue;
  jsonPlate: TJSONObject;
  vPlate, coordinate: TJsonValue;
  dataType: TJsonValue;
  plate: TOpenALPRPlate;
  FS: TFormatSettings;
  i: Integer;
begin
  FS.DecimalSeparator := '.';

  if Length(AJSON) > 0 then
  begin
    jsonObj := TJSONObject.ParseJSONValue(AJSON) as TJSONObject;
    try
      dataType := jsonObj.GetValue('data_type');
      if not Assigned(dataType) then Exit;
      if (dataType as TJSONString).Value = 'alpr_results' then
      begin
        FProcessingTimeMs := StrToFloat((jsonObj.Values['processing_time_ms'] as TJSONString).Value);

        plates := jsonObj.Values['results'] as TJSONArray;
        for vPlate in plates do
        begin
          jsonPlate := TJsonObject(vPlate);

          plate := TOpenALPRPlate.Create;
          plate.Plate := (jsonPlate.Values['plate'] as TJSONString).Value;
          plate.Confidence := StrToFloat((jsonPlate.Values['confidence'] as TJSONString).Value);
          plate.MatchesTemplate := Boolean(StrToInt((jsonPlate.Values['matches_template'] as TJSONNumber).Value));
          plate.PlateIndex := StrToInt((jsonPlate.Values['plate_index'] as TJSONNumber).Value);
          plate.Region := (jsonPlate.Values['region'] as TJSONString).Value;
          plate.RegionConfidence := StrToFloat((jsonPlate.Values['region_confidence'] as TJSONString).Value);
          plate.ProcessingTimeMs := StrToFloat((jsonPlate.Values['processing_time_ms'] as TJSONString).Value);

          i := 0;
          coordinates := jsonPlate.Values['coordinates'] as TJSONArray;
          for coordinate in coordinates do
          begin
            plate.Coordinates[i].X := StrToInt((TJsonObject(coordinate).Values['x'] as TJSONNumber).Value);
            plate.Coordinates[i].Y := StrToInt((TJsonObject(coordinate).Values['y'] as TJSONNumber).Value);
            Inc(i);
          end;

          candidates := jsonPlate.Values['candidates'] as TJSONArray;
          for candidate in candidates do
          begin
            plate.AddCandidate(
              (TJsonObject(candidate).Values['plate'] as TJSONString).Value,
              StrToFloat((TJsonObject(candidate).Values['confidence'] as TJSONString).Value),
              Boolean(StrToInt((TJsonObject(candidate).Values['matches_template'] as TJSONNumber).Value)));
          end;
          FPlates.Add(plate);
        end;
      end;
    finally
      jsonObj.Free;
    end;
  end;
end;

end.
