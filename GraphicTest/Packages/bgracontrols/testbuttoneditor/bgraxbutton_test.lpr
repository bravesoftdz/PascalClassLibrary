program bgraxbutton_test;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX} {$IFDEF UseCThreads}
  cthreads, {$ENDIF} {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  umain { you can add units after this };

{$R *.res}

begin
  Application.Title := 'Button Editor 1.1 by Lainz';
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TfrmButtonEditor, frmButtonEditor);
  Application.Run;
end.

