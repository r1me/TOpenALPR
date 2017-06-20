program delphi_console;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.Diagnostics,
  System.SysUtils,
  openalpr in '..\..\openalpr.pas';

var
  vOpenAlpr: TOpenALPR;
  alprResult: TOpenALPRResult;
  i, k: Integer;
  sw: TStopWatch;
begin
  vOpenAlpr := TOpenALPR.Create;
  try
    if vOpenAlpr.Initialize('eu', 'openalpr.conf', 'runtime_data') then
    begin
      vOpenAlpr.SetTopN(10);
      sw := TStopwatch.StartNew;
      alprResult := vOpenAlpr.RecognizeFile('samples\eu-3.jpg');
      WriteLn(Format('Total time to process image: %1.3fms.', [sw.Elapsed.TotalMilliseconds]));
      if (alprResult.Plates.Count > 0) then
      begin
        for i := 0 to alprResult.Plates.Count-1 do
        begin
          WriteLn(Format('plate%d: %d results -- Processing Time = %1.3fms.',
            [i, alprResult.Plates[i].Candidates.Count, alprResult.Plates[i].ProcessingTimeMs]));
          for k := 0 to alprResult.Plates[i].Candidates.Count-1 do
          begin
            WriteLn(Format('    - %s' + #9 + ' confidence: %1.3f',
              [alprResult.Plates[i].Candidates[k].Plate, alprResult.Plates[i].Candidates[k].Confidence]));
          end;
        end;
      end else
        WriteLn('No license plates found.');
    end;
  finally
    vOpenAlpr.Free;
  end;
end.
